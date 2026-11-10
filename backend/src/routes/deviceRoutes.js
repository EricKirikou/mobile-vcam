const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');
const { authenticate } = require('../middleware/auth');

router.get('/',
  authenticate,
  deviceController.listDevices.bind(deviceController)
);

router.get('/:deviceId',
  authenticate,
  deviceController.getDevice.bind(deviceController)
);

router.patch('/:deviceId',
  authenticate,
  deviceController.updateDevice.bind(deviceController)
);

router.delete('/:deviceId',
  authenticate,
  deviceController.deleteDevice.bind(deviceController)
);

module.exports = router;
