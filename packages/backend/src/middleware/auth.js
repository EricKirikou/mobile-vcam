const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/User');
const safeRedis = require('../config/redis');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: Missing or invalid authorization token'
      });
    }

    const token = authHeader.split(' ')[1];

    // Check if token has been revoked in Redis blacklist
    const isRevoked = await safeRedis.get(`blacklist:${token}`);
    if (isRevoked) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: Token has been revoked'
      });
    }

    const decoded = jwt.verify(token, env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-passwordHash');

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: Account not found or deactivated'
      });
    }

    req.user = user;
    req.token = token;
    req.deviceId = req.headers['x-device-id'] || decoded.deviceId;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        code: 'TOKEN_EXPIRED',
        error: 'Authorization token has expired'
      });
    }
    return res.status(401).json({
      success: false,
      error: 'Invalid authorization token'
    });
  }
};

module.exports = { authenticate };
