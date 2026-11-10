const logger = require('../config/logger');

class ClipboardService {
  constructor() {
    this.io = null;
  }

  setSocketIo(io) {
    this.io = io;
  }

  syncClipboard(senderDeviceId, targetDeviceId, text, mimeType = 'text/plain') {
    if (!this.io) {
      logger.warn('SocketIO not bound to ClipboardService');
      return false;
    }

    logger.debug(`Clipboard sync from [${senderDeviceId}] to [${targetDeviceId}], length: ${text ? text.length : 0}`);

    this.io.to(`device:${targetDeviceId}`).emit('clipboard:sync', {
      senderDeviceId,
      text,
      mimeType,
      timestamp: Date.now()
    });

    return true;
  }
}

module.exports = new ClipboardService();
