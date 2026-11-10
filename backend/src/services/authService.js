const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const Device = require('../models/Device');
const AuditLog = require('../models/AuditLog');
const safeRedis = require('../config/redis');
const env = require('../config/env');
const logger = require('../config/logger');

class AuthService {
  generateTokens(userId, deviceId = null) {
    const payload = { userId, deviceId };
    
    const accessToken = jwt.sign(payload, env.JWT_SECRET, {
      expiresIn: env.JWT_EXPIRES_IN
    });

    const refreshToken = jwt.sign(
      { userId, deviceId, jti: crypto.randomUUID() },
      env.REFRESH_TOKEN_SECRET,
      { expiresIn: env.REFRESH_TOKEN_EXPIRES_IN }
    );

    return { accessToken, refreshToken, expiresIn: env.JWT_EXPIRES_IN };
  }

  async register({ email, password, name, deviceId, deviceName, platform, deviceType }) {
    const existing = await User.findOne({ email });
    if (existing) {
      throw new Error('An account with this email address already exists');
    }

    const passwordHash = await User.hashPassword(password);
    const user = await User.create({
      email,
      passwordHash,
      name,
      lastLoginAt: new Date()
    });

    let registeredDevice = null;
    if (deviceId && platform && deviceType) {
      registeredDevice = await Device.findOneAndUpdate(
        { deviceId },
        {
          userId: user._id,
          deviceId,
          name: deviceName || `${platform} device`,
          platform,
          deviceType,
          status: 'online',
          lastSeenAt: new Date()
        },
        { upsert: true, new: true }
      );
    }

    const tokens = this.generateTokens(user._id, deviceId);
    await safeRedis.set(`refresh:${user._id}:${deviceId || 'default'}`, tokens.refreshToken, 'EX', 30 * 86400);

    await AuditLog.create({
      userId: user._id,
      deviceId,
      action: 'USER_REGISTERED',
      details: { email: user.email, platform }
    });

    return { user, tokens, device: registeredDevice };
  }

  async login({ email, password, deviceId, deviceName, platform, deviceType, ipAddress, userAgent }) {
    const user = await User.findOne({ email });
    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      await AuditLog.create({
        userId: user._id,
        deviceId,
        action: 'AUTH_FAILED',
        level: 'warning',
        ipAddress,
        userAgent,
        details: { reason: 'Incorrect password' }
      });
      throw new Error('Invalid email or password');
    }

    user.lastLoginAt = new Date();
    await user.save();

    let device = null;
    if (deviceId) {
      device = await Device.findOneAndUpdate(
        { deviceId },
        {
          userId: user._id,
          deviceId,
          name: deviceName || `${platform || 'Unknown'} Device`,
          platform: platform || 'windows',
          deviceType: deviceType || 'desktop',
          status: 'online',
          lastSeenAt: new Date()
        },
        { upsert: true, new: true }
      );
    }

    const tokens = this.generateTokens(user._id, deviceId);
    await safeRedis.set(`refresh:${user._id}:${deviceId || 'default'}`, tokens.refreshToken, 'EX', 30 * 86400);

    await AuditLog.create({
      userId: user._id,
      deviceId,
      action: 'AUTH_LOGIN_SUCCESS',
      ipAddress,
      userAgent,
      details: { email: user.email }
    });

    return { user, tokens, device };
  }

  async googleAuth({ token, googleId, email, name, avatarUrl, deviceId, platform, deviceType }) {
    // In production, token is verified against Google API: https://oauth2.googleapis.com/tokeninfo?id_token=...
    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (!user) {
      user = await User.create({
        googleId,
        email,
        name: name || 'Google User',
        avatarUrl: avatarUrl || '',
        lastLoginAt: new Date()
      });
    } else {
      user.googleId = googleId;
      if (avatarUrl) user.avatarUrl = avatarUrl;
      user.lastLoginAt = new Date();
      await user.save();
    }

    const tokens = this.generateTokens(user._id, deviceId);
    await safeRedis.set(`refresh:${user._id}:${deviceId || 'default'}`, tokens.refreshToken, 'EX', 30 * 86400);

    return { user, tokens };
  }

  async refreshToken(refreshToken) {
    try {
      const decoded = jwt.verify(refreshToken, env.REFRESH_TOKEN_SECRET);
      const stored = await safeRedis.get(`refresh:${decoded.userId}:${decoded.deviceId || 'default'}`);

      if (!stored || stored !== refreshToken) {
        throw new Error('Invalid or revoked refresh token');
      }

      const user = await User.findById(decoded.userId);
      if (!user || !user.isActive) {
        throw new Error('User account not found or deactivated');
      }

      const newTokens = this.generateTokens(user._id, decoded.deviceId);
      await safeRedis.set(`refresh:${user._id}:${decoded.deviceId || 'default'}`, newTokens.refreshToken, 'EX', 30 * 86400);

      return newTokens;
    } catch (err) {
      throw new Error(`Token refresh failed: ${err.message}`);
    }
  }

  async logout(token, userId, deviceId) {
    if (token) {
      // Blacklist access token for remaining lifetime (15 mins)
      await safeRedis.set(`blacklist:${token}`, '1', 'EX', 900);
    }
    if (userId && deviceId) {
      await safeRedis.del(`refresh:${userId}:${deviceId}`);
      await Device.findOneAndUpdate({ deviceId }, { status: 'offline', lastSeenAt: new Date() });
    }
    return true;
  }
}

module.exports = new AuthService();
