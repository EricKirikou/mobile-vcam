const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  deviceId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  deviceType: {
    type: String,
    enum: ['mobile', 'desktop'],
    required: true
  },
  platform: {
    type: String,
    enum: ['android', 'ios', 'windows', 'macos', 'linux'],
    required: true
  },
  model: {
    type: String,
    default: 'Unknown Model'
  },
  osVersion: {
    type: String,
    default: ''
  },
  appVersion: {
    type: String,
    default: '1.0.0'
  },
  pushToken: {
    type: String,
    default: null
  },
  status: {
    type: String,
    enum: ['online', 'offline', 'streaming', 'busy'],
    default: 'offline',
    index: true
  },
  socketId: {
    type: String,
    default: null
  },
  cameraCapabilities: {
    hasFront: { type: Boolean, default: true },
    hasBack: { type: Boolean, default: true },
    maxResolution: { type: String, default: '4K' }, // 720p, 1080p, 1440p, 4K
    supportedFps: { type: [Number], default: [24, 30, 60] },
    hasTorch: { type: Boolean, default: true },
    hasZoom: { type: Boolean, default: true },
    hasAutoFocus: { type: Boolean, default: true }
  },
  telemetry: {
    batteryLevel: { type: Number, default: 100 },
    isCharging: { type: Boolean, default: false },
    batteryTemperatureC: { type: Number, default: 30.0 },
    networkType: { type: String, default: 'wifi' }, // wifi, 4g, 5g, ethernet
    signalStrengthDbm: { type: Number, default: -60 }
  },
  lastSeenAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Device', deviceSchema);
