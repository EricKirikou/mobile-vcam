const express = require('express');
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const env = require('../config/env');
const logger = require('../config/logger');

let ioRef = null;
const setIo = (io) => { ioRef = io; };

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, env.FILE_UPLOAD_PATH),
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
    cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: env.MAX_FILE_SIZE_BYTES },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp|mp4|mov|avi|pdf|txt|doc|docx|zip/i;
    const ext = path.extname(file.originalname);
    if (allowed.test(ext)) {
      cb(null, true);
    } else {
      cb(new Error(`File type '${ext}' is not permitted for transfer`));
    }
  }
});

/**
 * POST /api/files/upload
 * Uploads a file and signals the target device to download it.
 */
router.post('/upload', authenticate, upload.single('file'), (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }

    const { targetDeviceId } = req.body;
    const fileInfo = {
      fileId: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimeType: req.file.mimetype,
      uploadedAt: new Date().toISOString(),
      downloadUrl: `/api/files/download/${req.file.filename}`
    };

    logger.info(`File uploaded by device [${req.deviceId}] -> target [${targetDeviceId}]: ${req.file.originalname}`);

    // Notify target device over Socket.IO
    if (ioRef && targetDeviceId) {
      ioRef.to(`device:${targetDeviceId}`).emit('file:incoming', {
        ...fileInfo,
        senderDeviceId: req.deviceId,
        senderId: req.user._id
      });
    }

    res.status(200).json({
      success: true,
      message: 'File uploaded successfully',
      data: fileInfo
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/files/download/:fileId
 * Streams the file back to the requesting client.
 */
router.get('/download/:fileId', authenticate, (req, res, next) => {
  try {
    const filePath = path.join(env.FILE_UPLOAD_PATH, path.basename(req.params.fileId));
    res.download(filePath, (err) => {
      if (err) {
        logger.error(`File download error for [${req.params.fileId}]: ${err.message}`);
        res.status(404).json({ success: false, error: 'File not found or expired' });
      }
    });
  } catch (err) {
    next(err);
  }
});

router._setIo = setIo;
module.exports = router;
