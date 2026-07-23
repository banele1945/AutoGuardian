const express = require('express');
const router = express.Router();
const carStatusController = require('../controllers/carStatusController');
const authenticateToken = require('../middleware/auth');

router.post('/', authenticateToken, carStatusController.postCarStatus);
router.get('/:device_uid', authenticateToken, carStatusController.getCarStatus);

module.exports = router; 