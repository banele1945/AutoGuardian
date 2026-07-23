const express = require('express');
const router = express.Router();
const db = require('../models');
const Alert = db.Alert;
const Device = db.Device;

// 🚨 POST: Submit a new alert
router.post('/', async (req, res) => {
  const { device_uid, type, message } = req.body;

  if (!device_uid || !type) {
    return res.status(400).json({ error: 'device_uid and type are required' });
  }

  try {
    const device = await Device.findOne({ where: { device_uid } });
    if (!device) return res.status(404).json({ error: 'Device not found' });

    const alert = await Alert.create({
      device_id: device.id,
      type,
      message
    });

    res.status(201).json({ message: 'Alert logged', alert });
  } catch (err) {
    console.error('Alert logging failed:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// 📥 GET: Fetch recent alerts
// Usage: /api/alert?device_uid=ABC123&limit=5
router.get('/', async (req, res) => {
  const { device_uid, limit = 10 } = req.query;

  try {
    let where = {};

    if (device_uid) {
      const device = await Device.findOne({ where: { device_uid } });
      if (!device) return res.status(404).json({ error: 'Device not found' });

      where.device_id = device.id;
    }

    const alerts = await Alert.findAll({
      where,
      order: [['timestamp', 'DESC']],
      limit: parseInt(limit)
    });

    res.status(200).json({ alerts });
  } catch (err) {
    console.error('Error fetching alerts:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;