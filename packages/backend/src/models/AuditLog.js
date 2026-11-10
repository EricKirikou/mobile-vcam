const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    index: true
  },
  deviceId: {
    type: String,
    index: true
  },
  action: {
    type: String,
    required: true,
    index: true
  }, // 'AUTH_LOGIN', 'DEVICE_PAIRED', 'STREAM_START', 'STREAM_STOP', 'SECURITY_ALERT', 'ERROR'
  level: {
    type: String,
    enum: ['info', 'warning', 'error', 'security'],
    default: 'info'
  },
  ipAddress: {
    type: String,
    default: ''
  },
  userAgent: {
    type: String,
    default: ''
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  }
}, {
  timestamps: { createdAt: true, updatedAt: false }
});

module.exports = mongoose.model('AuditLog', auditLogSchema);
