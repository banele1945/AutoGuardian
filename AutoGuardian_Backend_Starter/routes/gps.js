// routes/gps.js

const express = require('express');
const router = express.Router();
const { GPSLog, Device } = require('../models');

// ✅ POST: Add a GPS log
router.post('/', async (req, res) => {
  const { device_uid, latitude, longitude, speed } = req.body;

  try {
    const device = await Device.findOne({ where: { device_uid } });
    if (!device) return res.status(404).json({ error: 'Device not found' });

    const gpsLog = await GPSLog.create({
      device_id: device.id,
      latitude,
      longitude,
      speed,
    });

    res.status(201).json({ success: true, gpsLog });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to store GPS data' });
  }
});

// ✅ GET: Fetch last N GPS logs (optionally by device)
router.get('/', async (req, res) => {
  const { device_uid, limit = 10 } = req.query;

  try {
    let deviceFilter = {};
    if (device_uid) {
      const device = await Device.findOne({ where: { device_uid } });
      if (!device) return res.status(404).json({ error: 'Device not found' });
      deviceFilter.device_id = device.id;
    }

    const logs = await GPSLog.findAll({
      where: deviceFilter,
      order: [['timestamp', 'DESC']],
      limit: parseInt(limit),
    });

    res.json({ logs });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve GPS logs' });
  }
});

module.exports = router;