const db = require('../config/db');
const bcrypt = require('bcryptjs');

exports.receiveAlert = async (req, res) => {
  try {
    const { deviceId, type, timestamp } = req.body;

    if (!deviceId || !type || !timestamp) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const hashedId = bcrypt.hashSync(deviceId, 10);
    console.log(`[ALERT] Device: ${hashedId} | Type: ${type} | Time: ${timestamp}`);

    // TODO: Save to DB (alerts table)

    return res.status(200).json({ message: 'Alert received' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
