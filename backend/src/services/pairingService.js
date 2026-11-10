const crypto = require('crypto');
const QRCode = require('qrcode');
const Pairing = require('../models/Pairing');
const Device = require('../models/Device');
const AuditLog = require('../models/AuditLog');
const logger = require('../config/logger');

class PairingService {
  /**
   * Generates a 6-digit readable pair code (e.g. 849-204)
   */
  generatePairCode() {
    const rawNumber = Math.floor(100000 + Math.random() * 900000).toString();
    return `${rawNumber.substring(0, 3)}-${rawNumber.substring(3, 6)}`;
  }

  /**
   * Initiates a pairing request from Desktop PC
   * Returns QR Code Data URI and 6-digit pair code
   */
  async createPairingRequest(userId, desktopDeviceId) {
    // Generate unique pairing secret and token
    const pairCode = this.generatePairCode();
    const qrToken = crypto.randomBytes(24).toString('hex');
    const sharedSecret = crypto.randomBytes(32).toString('hex');

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes validity for initial scan

    const pairing = await Pairing.create({
      userId,
      desktopDeviceId,
      pairCode,
      qrToken,
      sharedSecret,
      status: 'pending',
      expiresAt
    });

    const qrPayload = JSON.stringify({
      version: '1.0',
      action: 'pair',
      qrToken,
      pairCode,
      desktopDeviceId,
      userId: userId.toString(),
      exp: expiresAt.getTime()
    });

    // Render QR Code as PNG Data URL for display in Windows WPF desktop UI
    const qrCodeDataUrl = await QRCode.toDataURL(qrPayload, {
      errorCorrectionLevel: 'H',
      margin: 2,
      width: 320,
      color: {
        dark: '#1e293b',
        light: '#ffffff'
      }
    });

    return {
      pairingId: pairing._id,
      pairCode,
      qrToken,
      qrCodeDataUrl,
      expiresAt
    };
  }

  /**
   * Completes device pairing when Mobile scans QR or enters Pair Code
   */
  async completePairing({ userId, mobileDeviceId, mobileDeviceName, qrToken, pairCode, platform, model }) {
    let query = { userId, status: 'pending' };
    if (qrToken) {
      query.qrToken = qrToken;
    } else if (pairCode) {
      query.pairCode = pairCode;
    } else {
      throw new Error('Must provide either qrToken or pairCode to complete pairing');
    }

    const pairing = await Pairing.findOne(query);
    if (!pairing) {
      throw new Error('Invalid or expired pairing code/token');
    }

    if (new Date() > pairing.expiresAt) {
      pairing.status = 'expired';
      await pairing.save();
      throw new Error('Pairing session has expired. Please refresh QR code on Desktop.');
    }

    // Register or update mobile device record
    const mobileDevice = await Device.findOneAndUpdate(
      { deviceId: mobileDeviceId },
      {
        userId,
        deviceId: mobileDeviceId,
        name: mobileDeviceName || `${model || 'Android'} Phone`,
        deviceType: 'mobile',
        platform: platform || 'android',
        model: model || 'Smartphone',
        status: 'online',
        lastSeenAt: new Date()
      },
      { upsert: true, new: true }
    );

    pairing.mobileDeviceId = mobileDeviceId;
    pairing.status = 'paired';
    pairing.pairedAt = new Date();
    // Extend expiry to permanent (e.g. 10 years)
    pairing.expiresAt = new Date(Date.now() + 10 * 365 * 24 * 3600 * 1000);
    await pairing.save();

    await AuditLog.create({
      userId,
      deviceId: mobileDeviceId,
      action: 'DEVICE_PAIRED',
      details: {
        desktopDeviceId: pairing.desktopDeviceId,
        mobileDeviceId,
        pairCode: pairing.pairCode
      }
    });

    logger.info(`Device paired successfully: Mobile [${mobileDeviceId}] <--> Desktop [${pairing.desktopDeviceId}]`);

    return {
      pairing,
      mobileDevice,
      sharedSecret: pairing.sharedSecret
    };
  }

  /**
   * Retrieves all paired devices for a user
   */
  async getUserPairings(userId) {
    const pairings = await Pairing.find({ userId, status: 'paired' }).lean();
    const deviceIds = [
      ...pairings.map(p => p.desktopDeviceId),
      ...pairings.map(p => p.mobileDeviceId).filter(Boolean)
    ];

    const devices = await Device.find({ deviceId: { $in: deviceIds } }).lean();
    const deviceMap = new Map(devices.map(d => [d.deviceId, d]));

    return pairings.map(p => ({
      pairingId: p._id,
      alias: p.alias,
      status: p.status,
      pairedAt: p.pairedAt,
      desktopDevice: deviceMap.get(p.desktopDeviceId) || { deviceId: p.desktopDeviceId },
      mobileDevice: deviceMap.get(p.mobileDeviceId) || { deviceId: p.mobileDeviceId },
      sharedSecret: p.sharedSecret
    }));
  }

  /**
   * Revokes or renames a paired device
   */
  async updatePairing(pairingId, userId, { alias, revoke }) {
    const pairing = await Pairing.findOne({ _id: pairingId, userId });
    if (!pairing) throw new Error('Pairing not found');

    if (revoke) {
      pairing.status = 'revoked';
      await pairing.save();
      await AuditLog.create({
        userId,
        deviceId: pairing.mobileDeviceId,
        action: 'PAIRING_REVOKED',
        details: { pairingId }
      });
      return { success: true, message: 'Device unlinked successfully' };
    }

    if (alias) {
      pairing.alias = alias;
      await pairing.save();
    }

    return pairing;
  }
}

module.exports = new PairingService();
