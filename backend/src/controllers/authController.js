const authService = require('../services/authService');
const Settings = require('../models/Settings');

class AuthController {
  async register(req, res, next) {
    try {
      const { email, password, name, deviceId, deviceName, platform, deviceType } = req.body;
      const result = await authService.register({
        email,
        password,
        name,
        deviceId,
        deviceName,
        platform,
        deviceType
      });

      // Initialize default user settings
      await Settings.create({ userId: result.user._id });

      res.status(201).json({
        success: true,
        message: 'Account registered successfully',
        data: {
          user: {
            id: result.user._id,
            email: result.user.email,
            name: result.user.name,
            role: result.user.role
          },
          device: result.device,
          tokens: result.tokens
        }
      });
    } catch (err) {
      next(err);
    }
  }

  async login(req, res, next) {
    try {
      const { email, password, deviceId, deviceName, platform, deviceType } = req.body;
      const result = await authService.login({
        email,
        password,
        deviceId,
        deviceName,
        platform,
        deviceType,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent']
      });

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: result.user._id,
            email: result.user.email,
            name: result.user.name,
            role: result.user.role
          },
          device: result.device,
          tokens: result.tokens
        }
      });
    } catch (err) {
      res.status(401).json({ success: false, error: err.message });
    }
  }

  async googleAuth(req, res, next) {
    try {
      const { token, googleId, email, name, avatarUrl, deviceId, platform, deviceType } = req.body;
      const result = await authService.googleAuth({
        token,
        googleId,
        email,
        name,
        avatarUrl,
        deviceId,
        platform,
        deviceType
      });

      res.status(200).json({
        success: true,
        data: {
          user: {
            id: result.user._id,
            email: result.user.email,
            name: result.user.name
          },
          tokens: result.tokens
        }
      });
    } catch (err) {
      next(err);
    }
  }

  async refreshToken(req, res, next) {
    try {
      const { refreshToken } = req.body;
      if (!refreshToken) {
        return res.status(400).json({ success: false, error: 'Refresh token is required' });
      }

      const tokens = await authService.refreshToken(refreshToken);
      res.status(200).json({
        success: true,
        data: tokens
      });
    } catch (err) {
      res.status(401).json({ success: false, error: err.message });
    }
  }

  async logout(req, res, next) {
    try {
      await authService.logout(req.token, req.user._id, req.deviceId);
      res.status(200).json({ success: true, message: 'Logged out successfully' });
    } catch (err) {
      next(err);
    }
  }

  async getProfile(req, res, next) {
    try {
      const settings = await Settings.findOne({ userId: req.user._id });
      res.status(200).json({
        success: true,
        data: {
          user: req.user,
          settings: settings || {}
        }
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
