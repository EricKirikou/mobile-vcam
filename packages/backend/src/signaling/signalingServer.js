/**
 * Socket.IO WebRTC Signaling Server
 *
 * Responsible for:
 * - WebRTC Offer/Answer/ICE candidate relay between mobile and desktop
 * - Device presence management (online/offline status)
 * - Real-time camera control command relay (RPC over Socket.IO)
 * - Clipboard sync relay
 * - Heartbeat/keep-alive tracking
 * - File transfer signaling
 * - Session lifecycle management
 */

const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const env = require('../config/env');
const logger = require('../config/logger');
const Device = require('../models/Device');
const Session = require('../models/Session');
const AuditLog = require('../models/AuditLog');
const notificationService = require('../services/notificationService');

// Map: deviceId → socketId
const deviceSocketMap = new Map();
// Map: socketId → deviceId
const socketDeviceMap = new Map();
// Map: sessionId → { desktopSocketId, mobileSocketId }
const activeSessions = new Map();

/**
 * Authenticate the socket connection via JWT in handshake auth.
 */
function authenticateSocket(socket, next) {
  try {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
    if (!token) return next(new Error('AUTH_REQUIRED: No token provided'));

    const decoded = jwt.verify(token, env.JWT_SECRET);
    socket.userId = decoded.userId;
    socket.deviceId = socket.handshake.auth?.deviceId || decoded.deviceId;
    next();
  } catch (err) {
    next(new Error(`AUTH_INVALID: ${err.message}`));
  }
}

function setupSignalingServer(io) {
  notificationService.setSocketIo(io);

  io.use(authenticateSocket);

  io.on('connection', async (socket) => {
    const { userId, deviceId } = socket;
    logger.info(`Socket connected: device=[${deviceId}] user=[${userId}] socket=[${socket.id}]`);

    // ─── Join device-specific room ─────────────────────────────────────────────
    if (deviceId) {
      socket.join(`device:${deviceId}`);
      socket.join(`user:${userId}`);
      deviceSocketMap.set(deviceId, socket.id);
      socketDeviceMap.set(socket.id, deviceId);

      // Update DB device status to online
      await Device.findOneAndUpdate({ deviceId }, { status: 'online', socketId: socket.id, lastSeenAt: new Date() });

      // Notify other paired devices of this user that this device came online
      socket.to(`user:${userId}`).emit('device:online', { deviceId, timestamp: Date.now() });
    }

    // ─── WebRTC Signaling: Session Initiation ─────────────────────────────────
    socket.on('signaling:request_session', async (data, ack) => {
      try {
        const { targetDeviceId, videoProfile, audioProfile } = data;
        logger.info(`Session requested: from=[${deviceId}] to=[${targetDeviceId}]`);

        const sessionId = uuidv4();
        const session = await Session.create({
          userId,
          desktopDeviceId: deviceId,
          mobileDeviceId: targetDeviceId,
          sessionId,
          status: 'initiating',
          videoProfile: videoProfile || {},
          audioProfile: audioProfile || {}
        });

        activeSessions.set(sessionId, { desktopSocketId: socket.id, mobileSocketId: null, sessionId });

        // Notify the target mobile device to prepare
        const targetSocketId = deviceSocketMap.get(targetDeviceId);
        if (!targetSocketId) {
          await session.updateOne({ status: 'failed' });
          return ack?.({ error: `Target device [${targetDeviceId}] is offline` });
        }

        io.to(targetSocketId).emit('signaling:incoming_session', {
          sessionId,
          fromDeviceId: deviceId,
          userId,
          videoProfile,
          audioProfile,
          timestamp: Date.now()
        });

        await AuditLog.create({ userId, deviceId, action: 'STREAM_SESSION_INITIATED', details: { sessionId, targetDeviceId } });

        ack?.({ sessionId });
      } catch (err) {
        logger.error(`signaling:request_session error: ${err.message}`);
        ack?.({ error: err.message });
      }
    });

    // ─── WebRTC SDP Offer (from Desktop → Mobile) ─────────────────────────────
    socket.on('signaling:offer', async (data) => {
      const { sessionId, sdp } = data;
      logger.debug(`SDP Offer relayed: session=[${sessionId}]`);

      const session = activeSessions.get(sessionId);
      if (session?.mobileSocketId) {
        io.to(session.mobileSocketId).emit('signaling:offer', { sessionId, sdp, fromDeviceId: deviceId });
      }
    });

    // ─── WebRTC SDP Answer (from Mobile → Desktop) ────────────────────────────
    socket.on('signaling:answer', async (data) => {
      const { sessionId, sdp } = data;
      logger.debug(`SDP Answer relayed: session=[${sessionId}]`);

      const session = activeSessions.get(sessionId);
      if (session?.desktopSocketId) {
        io.to(session.desktopSocketId).emit('signaling:answer', { sessionId, sdp, fromDeviceId: deviceId });
      }
    });

    // ─── ICE Candidate Exchange ────────────────────────────────────────────────
    socket.on('signaling:ice_candidate', (data) => {
      const { sessionId, candidate, sdpMid, sdpMLineIndex } = data;

      const session = activeSessions.get(sessionId);
      if (!session) return;

      // Relay ICE candidate to the peer
      const targetSocketId = socket.id === session.desktopSocketId
        ? session.mobileSocketId
        : session.desktopSocketId;

      if (targetSocketId) {
        io.to(targetSocketId).emit('signaling:ice_candidate', {
          sessionId,
          candidate,
          sdpMid,
          sdpMLineIndex,
          fromDeviceId: deviceId
        });
      }
    });

    // ─── Session Connected Confirmation ────────────────────────────────────────
    socket.on('signaling:session_ready', async (data) => {
      const { sessionId, connectionType } = data;
      logger.info(`Session CONNECTED: session=[${sessionId}] type=[${connectionType}]`);

      const session = activeSessions.get(sessionId);
      if (session) {
        session.mobileSocketId = socket.id;
        activeSessions.set(sessionId, session);
      }

      await Session.findOneAndUpdate({ sessionId }, {
        status: 'connected',
        connectionType: connectionType || 'p2p_direct'
      });

      // Notify desktop that stream is live
      if (session?.desktopSocketId) {
        io.to(session.desktopSocketId).emit('signaling:stream_live', { sessionId, fromDeviceId: deviceId });
      }
    });

    // ─── Session Disconnection ────────────────────────────────────────────────
    socket.on('signaling:end_session', async (data) => {
      const { sessionId } = data;
      logger.info(`Session ended by [${deviceId}]: session=[${sessionId}]`);

      await _endSession(io, sessionId, deviceId);
    });

    // ─── Live Metrics Update (Mobile → Server → Desktop) ─────────────────────
    socket.on('metrics:update', async (data) => {
      const { sessionId, latencyMs, fps, bitrateKbps, packetLossPct, batteryLevel } = data;

      await Session.findOneAndUpdate({ sessionId }, {
        'metrics.avgLatencyMs': latencyMs,
        'metrics.currentFps': fps,
        'metrics.currentBitrateKbps': bitrateKbps,
        'metrics.packetLossPct': packetLossPct
      });

      if (deviceId) {
        await Device.findOneAndUpdate({ deviceId }, {
          'telemetry.batteryLevel': batteryLevel,
          lastSeenAt: new Date()
        });
      }

      // Forward metrics to desktop
      const session = activeSessions.get(sessionId);
      if (session?.desktopSocketId) {
        io.to(session.desktopSocketId).emit('metrics:live', {
          sessionId,
          latencyMs,
          fps,
          bitrateKbps,
          packetLossPct,
          batteryLevel,
          fromDeviceId: deviceId,
          timestamp: Date.now()
        });
      }

      // Battery alert
      if (batteryLevel !== undefined && batteryLevel <= 15) {
        const session = activeSessions.get(sessionId);
        if (session) {
          const desktopDeviceId = socketDeviceMap.get(session.desktopSocketId);
          if (desktopDeviceId) {
            await notificationService.sendBatteryLowAlert(deviceId, desktopDeviceId, batteryLevel);
          }
        }
      }
    });

    // ─── Device Telemetry (Mobile pushes battery, temperature, etc.) ──────────
    socket.on('device:telemetry', async (data) => {
      if (!deviceId) return;
      await Device.findOneAndUpdate({ deviceId }, {
        telemetry: data,
        lastSeenAt: new Date()
      });
      socket.to(`user:${userId}`).emit('device:telemetry', { deviceId, ...data, timestamp: Date.now() });
    });

    // ─── Camera RPC Response (Mobile → Server → REST caller) ─────────────────
    socket.on('camera:rpc_response', (data) => {
      // This event is emitted by mobile to respond to desktop RPC calls.
      // The acknowledgment callback in cameraRpcController.sendRpcToDevice handles this.
      logger.debug(`RPC response from [${deviceId}]: cmd=[${data.commandId}]`);
    });

    // ─── Clipboard Sync ───────────────────────────────────────────────────────
    socket.on('clipboard:push', (data) => {
      const { targetDeviceId, text, mimeType } = data;
      logger.debug(`Clipboard sync from [${deviceId}] -> [${targetDeviceId}]`);
      io.to(`device:${targetDeviceId}`).emit('clipboard:sync', {
        senderDeviceId: deviceId,
        text,
        mimeType: mimeType || 'text/plain',
        timestamp: Date.now()
      });
    });

    // ─── Screen Share Signaling ───────────────────────────────────────────────
    socket.on('screenshare:request', (data) => {
      const { targetDeviceId, direction } = data; // direction: 'phone_to_desktop' | 'desktop_to_phone'
      io.to(`device:${targetDeviceId}`).emit('screenshare:request', {
        fromDeviceId: deviceId,
        direction,
        timestamp: Date.now()
      });
    });

    // ─── Heartbeat / Keep-alive ───────────────────────────────────────────────
    socket.on('heartbeat', async () => {
      if (deviceId) {
        await Device.findOneAndUpdate({ deviceId }, { lastSeenAt: new Date() });
      }
      socket.emit('heartbeat_ack', { timestamp: Date.now() });
    });

    // ─── Disconnect Cleanup ───────────────────────────────────────────────────
    socket.on('disconnect', async (reason) => {
      logger.info(`Socket disconnected: device=[${deviceId}] reason=[${reason}]`);

      if (deviceId) {
        deviceSocketMap.delete(deviceId);
        socketDeviceMap.delete(socket.id);

        await Device.findOneAndUpdate({ deviceId }, {
          status: 'offline',
          socketId: null,
          lastSeenAt: new Date()
        });

        // Notify all user devices that this device went offline
        socket.to(`user:${userId}`).emit('device:offline', { deviceId, reason, timestamp: Date.now() });

        // End any active streaming sessions for this device
        for (const [sessionId, session] of activeSessions.entries()) {
          if (session.desktopSocketId === socket.id || session.mobileSocketId === socket.id) {
            await _endSession(io, sessionId, deviceId);
          }
        }
      }
    });
  });

  logger.info('WebRTC Signaling Server initialized and ready');
  return io;
}

async function _endSession(io, sessionId, initiatorDeviceId) {
  const session = activeSessions.get(sessionId);
  if (!session) return;

  activeSessions.delete(sessionId);

  await Session.findOneAndUpdate({ sessionId }, {
    status: 'disconnected',
    endedAt: new Date()
  });

  // Notify both endpoints about session end
  if (session.desktopSocketId) {
    io.to(session.desktopSocketId).emit('signaling:session_ended', { sessionId, initiatorDeviceId, timestamp: Date.now() });
  }
  if (session.mobileSocketId) {
    io.to(session.mobileSocketId).emit('signaling:session_ended', { sessionId, initiatorDeviceId, timestamp: Date.now() });
  }

  logger.info(`Session cleaned up: session=[${sessionId}] initiator=[${initiatorDeviceId}]`);
}

module.exports = setupSignalingServer;
