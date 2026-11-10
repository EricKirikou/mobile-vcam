const express = require('express');
const router = express.Router();
const pairingController = require('../controllers/pairingController');
const { authenticate } = require('../middleware/auth');
const { validateRequestBody } = require('../middleware/validator');

router.post('/',
  authenticate,
  validateRequestBody(['desktopDeviceId']),
  pairingController.createPairing.bind(pairingController)
);

router.post('/complete',
  authenticate,
  validateRequestBody(['mobileDeviceId']),
  pairingController.completePairing.bind(pairingController)
);

router.get('/',
  authenticate,
  pairingController.getPairings.bind(pairingController)
);

router.patch('/:id',
  authenticate,
  pairingController.updatePairing.bind(pairingController)
);

module.exports = router;
