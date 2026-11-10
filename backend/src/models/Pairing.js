const mongoose = require('mongoose');

const pairingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  desktopDeviceId: {
    type: String,
    required: true,
    index: true
  },
  mobileDeviceId: {
    type: String,
    sparse: true,
    index: true
  },
  pairCode: {
    type: String,
    required: true,
    index: true
  },
  qrToken: {
    type: String,
    required: true,
    unique: true
  },
  status: {
    type: String,
    enum: ['pending', 'paired', 'revoked', 'expired'],
    default: 'pending'
  },
  sharedSecret: {
    type: String,
    required: true
  },
  alias: {
    type: String,
    default: 'My Mobile Camera'
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expires: '30d' } // Pair requests expire, but once paired can stay permanently
  },
  pairedAt: {
    type: Date
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Pairing', pairingSchema);
