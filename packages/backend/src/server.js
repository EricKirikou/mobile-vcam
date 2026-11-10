/**
 * Mobile Virtual Camera - Main Application Entry Point
 *
 * Architecture:
 *   Express HTTP Server  → REST API (Auth, Devices, Pairing, Camera RPC, Files, Settings, Analytics)
 *   Socket.IO Server     → WebRTC Signaling, Real-time events, Presence management
 *   MongoDB              → Persistent data (Users, Devices, Sessions, Pairings, Settings)
 *   Redis                → JWT token management, session caching
 */

'use strict';

const http = require('http');
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Server: SocketIOServer } = require('socket.io');

const env = require('./config/env');
const logger = require('./config/logger');
const connectDB = require('./config/db');
const { apiLimiter } = require('./middleware/rateLimiter');
const { notFoundHandler, globalErrorHandler } = require('./middleware/errorHandler');

// ─── Route Imports ────────────────────────────────────────────────────────────
const authRoutes       = require('./routes/authRoutes');
const pairingRoutes    = require('./routes/pairingRoutes');
const deviceRoutes     = require('./routes/deviceRoutes');
const turnRoutes       = require('./routes/turnRoutes');
const cameraRoutes     = require('./routes/cameraRoutes');
const fileRoutes       = require('./routes/fileRoutes');
const settingsRoutes   = require('./routes/settingsRoutes');
const analyticsRoutes  = require('./routes/analyticsRoutes');

// ─── Service / Controller Imports ─────────────────────────────────────────────
const setupSignalingServer  = require('./signaling/signalingServer');
const cameraRpcController   = require('./controllers/cameraRpcController');
const clipboardService      = require('./services/clipboardService');
const fileUploadDir         = env.FILE_UPLOAD_PATH;

// ─── App Setup ─────────────────────────────────────────────────────────────────
const app    = express();
const server = http.createServer(app);

// ─── CORS Configuration ───────────────────────────────────────────────────────
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || env.CORS_ORIGIN.includes(origin) || env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      callback(new Error(`CORS rejected: ${origin}`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-ID']
}));

// ─── Security Headers ─────────────────────────────────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));

// ─── Logging & Body Parsing ───────────────────────────────────────────────────
app.use(morgan('combined', { stream: { write: msg => logger.info(msg.trim()) } }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Static File Uploads ──────────────────────────────────────────────────────
const fs = require('fs');
if (!fs.existsSync(fileUploadDir)) fs.mkdirSync(fileUploadDir, { recursive: true });
app.use('/uploads', express.static(path.resolve(fileUploadDir)));

// ─── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'mobile-virtual-camera-backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// ─── API Rate Limiting ────────────────────────────────────────────────────────
app.use('/api/', apiLimiter);

// ─── API Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth',        authRoutes);
app.use('/api/pairings',    pairingRoutes);
app.use('/api/devices',     deviceRoutes);
app.use('/api/ice-servers', turnRoutes);
app.use('/api',             cameraRoutes);
app.use('/api/files',       fileRoutes);
app.use('/api/settings',    settingsRoutes);
app.use('/api/analytics',   analyticsRoutes);

// ─── 404 and Error Handlers ────────────────────────────────────────────────────
app.use(notFoundHandler);
app.use(globalErrorHandler);

// ─── Socket.IO Setup ──────────────────────────────────────────────────────────
const io = new SocketIOServer(server, {
  cors: {
    origin: env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  },
  transports: ['websocket', 'polling'],
  pingTimeout: 20000,
  pingInterval: 10000,
  upgradeTimeout: 10000,
  allowEIO3: true  // Allow older Engine.IO clients
});

// Inject io into controllers and services that need real-time messaging
setupSignalingServer(io);
cameraRpcController.setSocketIo(io);
clipboardService.setSocketIo(io);
fileRoutes._setIo(io);

// ─── Boot Sequence ────────────────────────────────────────────────────────────
async function bootstrap() {
  try {
    await connectDB();

    server.listen(env.PORT, env.HOST, () => {
      logger.info(`══════════════════════════════════════════════════════`);
      logger.info(`  Mobile Virtual Camera Backend v1.0.0`);
      logger.info(`  🚀 Server listening on http://${env.HOST}:${env.PORT}`);
      logger.info(`  🌐 Environment: ${env.NODE_ENV}`);
      logger.info(`  📡 Socket.IO: Signaling server active`);
      logger.info(`  🔐 TURN domain: ${env.TURN_DOMAIN}`);
      logger.info(`══════════════════════════════════════════════════════`);
    });
  } catch (err) {
    logger.error(`Bootstrap failed: ${err.message}`, { stack: err.stack });
    process.exit(1);
  }
}

// ─── Graceful Shutdown ─────────────────────────────────────────────────────────
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, initiating graceful shutdown...');
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });
});

process.on('unhandledRejection', (err) => {
  logger.error(`Unhandled Promise Rejection: ${err.message}`, { stack: err.stack });
});

process.on('uncaughtException', (err) => {
  logger.error(`Uncaught Exception: ${err.message}`, { stack: err.stack });
  process.exit(1);
});

bootstrap();

module.exports = { app, server, io };
