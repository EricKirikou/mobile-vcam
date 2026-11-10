const Device = require('../models/Device');

class DeviceController {
  async listDevices(req, res, next) {
    try {
      const devices = await Device.find({ userId: req.user._id }).sort({ lastSeenAt: -1 });
      res.status(200).json({
        success: true,
        data: devices
      });
    } catch (err) {
      next(err);
    }
  }

  async getDevice(req, res, next) {
    try {
      const device = await Device.findOne({ deviceId: req.params.deviceId, userId: req.user._id });
      if (!device) {
        return res.status(404).json({ success: false, error: 'Device not found' });
      }
      res.status(200).json({ success: true, data: device });
    } catch (err) {
      next(err);
    }
  }

  async updateDevice(req, res, next) {
    try {
      const { name, cameraCapabilities, telemetry, pushToken, status } = req.body;
      const updates = { lastSeenAt: new Date() };

      if (name) updates.name = name;
      if (cameraCapabilities) updates.cameraCapabilities = cameraCapabilities;
      if (telemetry) updates.telemetry = telemetry;
      if (pushToken) updates.pushToken = pushToken;
      if (status) updates.status = status;

      const device = await Device.findOneAndUpdate(
        { deviceId: req.params.deviceId, userId: req.user._id },
        updates,
        { new: true }
      );

      if (!device) {
        return res.status(404).json({ success: false, error: 'Device not found' });
      }

      res.status(200).json({ success: true, data: device });
    } catch (err) {
      next(err);
    }
  }

  async deleteDevice(req, res, next) {
    try {
      const device = await Device.findOneAndDelete({ deviceId: req.params.deviceId, userId: req.user._id });
      if (!device) {
        return res.status(404).json({ success: false, error: 'Device not found' });
      }
      res.status(200).json({ success: true, message: 'Device removed successfully' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DeviceController();
