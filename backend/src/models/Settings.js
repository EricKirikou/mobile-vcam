const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  theme: {
    type: String,
    enum: ['light', 'dark', 'system'],
    default: 'system'
  },
  language: {
    type: String,
    default: 'en-US'
  },
  video: {
    preferredResolution: { type: String, default: '1080p' }, // 720p, 1080p, 1440p, 4K
    preferredFps: { type: Number, default: 30 },
    preferredCodec: { type: String, default: 'H264' },
    targetBitrateKbps: { type: Number, default: 4500 },
    adaptiveBitrate: { type: Boolean, default: true },
    hardwareAcceleration: { type: Boolean, default: true }
  },
  audio: {
    enabled: { type: Boolean, default: true },
    noiseSuppression: { type: Boolean, default: true },
    echoCancellation: { type: Boolean, default: true },
    autoGainControl: { type: Boolean, default: true }
  },
  aiFeatures: {
    backgroundBlur: { type: Boolean, default: false },
    blurIntensity: { type: Number, default: 50 }, // 0 - 100
    virtualBackgroundUrl: { type: String, default: '' },
    faceTracking: { type: Boolean, default: false },
    autoFraming: { type: Boolean, default: false },
    portraitEnhance: { type: Boolean, default: false },
    lowLightEnhance: { type: Boolean, default: false },
    greenScreenColor: { type: String, default: '#00FF00' }
  },
  features: {
    clipboardSync: { type: Boolean, default: true },
    fileTransferEnabled: { type: Boolean, default: true },
    screenShareEnabled: { type: Boolean, default: true },
    autoConnectOnLaunch: { type: Boolean, default: true },
    startWithWindows: { type: Boolean, default: true },
    autoCheckUpdates: { type: Boolean, default: true }
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Settings', settingsSchema);
