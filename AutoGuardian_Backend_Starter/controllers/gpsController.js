exports.receiveGPS = async (req, res) => {
  try {
    const { deviceId, lat, lon, timestamp } = req.body;

    if (!deviceId || !lat || !lon || !timestamp) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    console.log(`[GPS] Device: ${deviceId} | Lat: ${lat} | Lon: ${lon} | Time: ${timestamp}`);

    // TODO: Save to DB (gps_logs table)

    return res.status(200).json({ message: 'GPS logged' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
