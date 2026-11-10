const express = require('express');
const router = express.Router();
const Session = require('../models/Session');
const AuditLog = require('../models/AuditLog');
const Device = require('../models/Device');
const { authenticate } = require('../middleware/auth');

/**
 * GET /api/analytics/sessions
 * Returns streaming session history with performance metrics.
 */
router.get('/sessions', authenticate, async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, deviceId } = req.query;
    const filter = { userId: req.user._id };
    if (deviceId) filter.$or = [{ desktopDeviceId: deviceId }, { mobileDeviceId: deviceId }];

    const sessions = await Session.find(filter)
      .sort({ startedAt: -1 })
      .skip(parseInt(offset))
      .limit(Math.min(parseInt(limit), 200))
      .lean();

    const total = await Session.countDocuments(filter);

    res.status(200).json({ success: true, data: { sessions, total, offset, limit } });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/analytics/logs
 * Returns audit logs for the authenticated user (security activity).
 */
router.get('/logs', authenticate, async (req, res, next) => {
  try {
    const { limit = 100, offset = 0 } = req.query;
    const logs = await AuditLog.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .skip(parseInt(offset))
      .limit(Math.min(parseInt(limit), 500))
      .lean();

    res.status(200).json({ success: true, data: logs });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/analytics/summary
 * Dashboard summary stats for the connected desktop UI.
 */
router.get('/summary', authenticate, async (req, res, next) => {
  try {
    const userId = req.user._id;

    const [deviceCount, sessionCount, lastSession] = await Promise.all([
      Device.countDocuments({ userId }),
      Session.countDocuments({ userId }),
      Session.findOne({ userId }).sort({ startedAt: -1 }).lean()
    ]);

    const totalStreamedMs = await Session.aggregate([
      { $match: { userId, status: 'disconnected' } },
      { $project: { duration: { $subtract: ['$endedAt', '$startedAt'] } } },
      { $group: { _id: null, total: { $sum: '$duration' } } }
    ]);

    res.status(200).json({
      success: true,
      data: {
        deviceCount,
        sessionCount,
        totalStreamedMs: totalStreamedMs[0]?.total || 0,
        lastSession
      }
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
