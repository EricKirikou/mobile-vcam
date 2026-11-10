const Device = require('../models/Device');
const logger = require('../config/logger');

class CameraRpcController {
  constructor() {
    this.io = null;
  }

  setSocketIo(io) {
    this.io = io;
  }

  async sendRpcToDevice(targetDeviceId, action, payload = {}) {
    if (!this.io) {
      throw new Error('Realtime transport service not initialized');
    }

    const commandId = Math.random().toString(36).substring(2, 9);
    logger.info(`Dispatching RPC [${action}] to device [${targetDeviceId}] with id ${commandId}`);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`RPC timeout: Mobile device [${targetDeviceId}] did not respond within 5000ms`));
      }, 5000);

      // Emit through Socket.IO with acknowledgment callback
      this.io.to(`device:${targetDeviceId}`).timeout(5000).emit('camera:rpc', {
        commandId,
        action,
        payload,
        timestamp: Date.now()
      }, (err, response) => {
        clearTimeout(timeout);
        if (err) {
          return reject(new Error(`Failed to deliver RPC to device: ${err.message || 'Device offline'}`));
        }
        resolve(response);
      });
    });
  }

  async startCamera(req, res, next) {
    try {
      const { deviceId } = req.params;
      const { resolution, fps, facing } = req.body;
      const response = await this.sendRpcToDevice(deviceId, 'START_CAMERA', { resolution, fps, facing });
      res.status(200).json({ success: true, message: 'Camera started', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async stopCamera(req, res, next) {
    try {
      const { deviceId } = req.params;
      const response = await this.sendRpcToDevice(deviceId, 'STOP_CAMERA');
      res.status(200).json({ success: true, message: 'Camera stopped', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async takePhoto(req, res, next) {
    try {
      const { deviceId } = req.params;
      const { highRes, flash } = req.body;
      const response = await this.sendRpcToDevice(deviceId, 'TAKE_PHOTO', { highRes, flash });
      res.status(200).json({ success: true, message: 'Photo captured', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async changeResolution(req, res, next) {
    try {
      const { deviceId } = req.params;
      const { resolution, fps, bitrateKbps } = req.body;
      const response = await this.sendRpcToDevice(deviceId, 'CHANGE_RESOLUTION', { resolution, fps, bitrateKbps });
      res.status(200).json({ success: true, message: 'Resolution changed', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async switchCamera(req, res, next) {
    try {
      const { deviceId } = req.params;
      const { facing } = req.body; // 'front' | 'back' | 'toggle'
      const response = await this.sendRpcToDevice(deviceId, 'SWITCH_CAMERA', { facing });
      res.status(200).json({ success: true, message: 'Camera switched', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async setCameraControls(req, res, next) {
    try {
      const { deviceId } = req.params;
      const {
        zoom,
        flash,
        focusMode,
        focusDistance,
        exposureCompensation,
        whiteBalance,
        hdr,
        stabilization,
        orientation
      } = req.body;

      const response = await this.sendRpcToDevice(deviceId, 'UPDATE_CONTROLS', {
        zoom,
        flash,
        focusMode,
        focusDistance,
        exposureCompensation,
        whiteBalance,
        hdr,
        stabilization,
        orientation
      });

      res.status(200).json({ success: true, message: 'Camera controls updated', data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }

  async getBattery(req, res, next) {
    try {
      const { deviceId } = req.params;
      const device = await Device.findOne({ deviceId });
      if (!device) return res.status(404).json({ success: false, error: 'Device not found' });
      res.status(200).json({ success: true, data: device.telemetry });
    } catch (err) {
      next(err);
    }
  }

  async getFps(req, res, next) {
    try {
      const { deviceId } = req.params;
      const response = await this.sendRpcToDevice(deviceId, 'GET_METRICS');
      res.status(200).json({ success: true, data: response });
    } catch (err) {
      res.status(504).json({ success: false, error: err.message });
    }
  }
}

module.exports = new CameraRpcController();
