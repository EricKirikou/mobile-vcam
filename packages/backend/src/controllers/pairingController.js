const pairingService = require('../services/pairingService');

class PairingController {
  async createPairing(req, res, next) {
    try {
      const desktopDeviceId = req.body.desktopDeviceId || req.deviceId;
      if (!desktopDeviceId) {
        return res.status(400).json({ success: false, error: 'desktopDeviceId is required' });
      }

      const result = await pairingService.createPairingRequest(req.user._id, desktopDeviceId);
      res.status(201).json({
        success: true,
        data: result
      });
    } catch (err) {
      next(err);
    }
  }

  async completePairing(req, res, next) {
    try {
      const { mobileDeviceId, mobileDeviceName, qrToken, pairCode, platform, model } = req.body;
      const result = await pairingService.completePairing({
        userId: req.user._id,
        mobileDeviceId: mobileDeviceId || req.deviceId,
        mobileDeviceName,
        qrToken,
        pairCode,
        platform,
        model
      });

      res.status(200).json({
        success: true,
        message: 'Pairing completed successfully',
        data: result
      });
    } catch (err) {
      res.status(400).json({ success: false, error: err.message });
    }
  }

  async getPairings(req, res, next) {
    try {
      const pairings = await pairingService.getUserPairings(req.user._id);
      res.status(200).json({
        success: true,
        data: pairings
      });
    } catch (err) {
      next(err);
    }
  }

  async updatePairing(req, res, next) {
    try {
      const { id } = req.params;
      const { alias, revoke } = req.body;
      const result = await pairingService.updatePairing(id, req.user._id, { alias, revoke });
      res.status(200).json({
        success: true,
        data: result
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new PairingController();
