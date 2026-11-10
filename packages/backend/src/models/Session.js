const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  desktopDeviceId: {
    type: String,
    required: true
  },
  mobileDeviceId: {
    type: String,
    required: true
  },
  sessionId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  status: {
    type: String,
    enum: ['initiating', 'connected', 'fallback_ws', 'disconnected', 'failed'],
    default: 'initiating'
  },
  connectionType: {
    type: String,
    enum: ['p2p_direct', 'turn_relay', 'websocket_fallback'],
    default: 'p2p_direct'
  },
  videoProfile: {
    resolution: { type: String, default: '4K' },
    fps: { type: Number, default: 60 },
    codec: { type: String, default: 'H264' },
    bitrateKbps: { type: Number, default: 25000 }
  },
  audioProfile: {
    enabled: { type: Boolean, default: true },
    noiseSuppression: { type: Boolean, default: true },
    echoCancellation: { type: Boolean, default: true }
  },
  metrics: {
    avgLatencyMs: { type: Number, default: 0 },
    currentFps: { type: Number, default: 0 },
    currentBitrateKbps: { type: Number, default: 0 },
    packetLossPct: { type: Number, default: 0 },
    framesDropped: { type: Number, default: 0 }
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  endedAt: {
    type: Date
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Session', sessionSchema);
