const { Device, CarStatus } = require('../models');

exports.postCarStatus = async (req, res) => {
  try {
    const { device_uid, status, engine_status } = req.body;
    const device = await Device.findOne({ where: { device_uid } });
    if (!device) return res.status(404).json({ error: 'Device not found' });
    const carStatus = await CarStatus.create({
      device_id: device.id,
      status,
      engine_status
    });
    res.status(201).json(carStatus);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getCarStatus = async (req, res) => {
  try {
    const { device_uid } = req.params;
    const device = await Device.findOne({ where: { device_uid } });
    if (!device) return res.status(404).json({ error: 'Device not found' });
    const carStatus = await CarStatus.findOne({
      where: { device_id: device.id },
      order: [['timestamp', 'DESC']]
    });
    if (!carStatus) return res.status(404).json({ error: 'No car status found for this device' });
    res.json({
      device_uid,
      status: carStatus.status,
      engine_status: carStatus.engine_status,
      timestamp: carStatus.timestamp
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}; 