const Device = require('../models/Device');
const logger = require('../config/logger');

class NotificationService {
  constructor() {
    this.io = null;
  }

  setSocketIo(io) {
    this.io = io;
  }

  /**
   * Broadcasts real-time notification to a specific device via WebSockets / push
   */
  async notifyDevice(deviceId, notification) {
    const { type, title, body, data, severity } = notification;

    logger.info(`Sending notification to device ${deviceId}: [${type}] ${title}`);

    if (this.io) {
      // Find room or socket associated with deviceId
      this.io.to(`device:${deviceId}`).emit('notification', {
        type,
        title,
        body,
        data: data || {},
        severity: severity || 'info',
        timestamp: new Date().toISOString()
      });
    }

    // If device has a pushToken registered, in production dispatch to FCM / APNS
    const device = await Device.findOne({ deviceId });
    if (device && device.pushToken) {
      // FCM dispatch placeholder
      logger.debug(`FCM Push dispatched to token: ${device.pushToken.substring(0, 10)}...`);
    }

    return true;
  }

  async sendBatteryLowAlert(mobileDeviceId, desktopDeviceId, batteryLevel) {
    return this.notifyDevice(desktopDeviceId, {
      type: 'BATTERY_LOW',
      title: 'Mobile Battery Low',
      body: `Phone battery is at ${batteryLevel}%. Please connect to a charger to prevent stream disruption.`,
      severity: 'warning',
      data: { batteryLevel, mobileDeviceId }
    });
  }

  async sendWeakNetworkAlert(deviceId, packetLoss, latency) {
    return this.notifyDevice(deviceId, {
      type: 'WEAK_NETWORK',
      title: 'Network Quality Degraded',
      body: `High latency (${latency}ms) or packet loss (${packetLoss}%). Switching to adaptive bitrate.`,
      severity: 'warning',
      data: { packetLoss, latency }
    });
  }
}

module.exports = new NotificationService();
