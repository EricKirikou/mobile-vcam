const express = require('express');
const router = express.Router();
const cameraRpcController = require('../controllers/cameraRpcController');
const { authenticate } = require('../middleware/auth');

/**
 * Remote Camera Control REST API
 * All routes require authentication via JWT Bearer token.
 * RPC commands are relayed to the mobile device in real-time via Socket.IO.
 */

// Camera lifecycle
router.post('/devices/:deviceId/camera/start',   authenticate, cameraRpcController.startCamera.bind(cameraRpcController));
router.post('/devices/:deviceId/camera/stop',    authenticate, cameraRpcController.stopCamera.bind(cameraRpcController));
router.post('/devices/:deviceId/camera/photo',   authenticate, cameraRpcController.takePhoto.bind(cameraRpcController));
router.post('/devices/:deviceId/camera/switch',  authenticate, cameraRpcController.switchCamera.bind(cameraRpcController));

// Camera settings
router.post('/devices/:deviceId/camera/resolution', authenticate, cameraRpcController.changeResolution.bind(cameraRpcController));
router.post('/devices/:deviceId/camera/controls',   authenticate, cameraRpcController.setCameraControls.bind(cameraRpcController));

// Status queries
router.get('/devices/:deviceId/battery',  authenticate, cameraRpcController.getBattery.bind(cameraRpcController));
router.get('/devices/:deviceId/metrics',  authenticate, cameraRpcController.getFps.bind(cameraRpcController));

module.exports = router;
