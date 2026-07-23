require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const app = express();
const db = require('./models');

const alertRoutes = require('./routes/alert');
const gpsRoutes = require('./routes/gps');
const authRoutes = require('./routes/auth');
const carStatusRoutes = require('./routes/carStatus');
const authenticateToken = require('./middleware/auth');

app.use(helmet());
app.use(express.json());
app.use('/api/alert', authenticateToken, alertRoutes);
app.use('/api/gps', authenticateToken, gpsRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/car-status', carStatusRoutes);

app.get('/api/ping', (req, res) => {
  res.send({ message: 'AutoGuardian backend is running.' });
});

// Example: protect alert and gps routes
app.use('/api/alert', authenticateToken, alertRoutes);
app.use('/api/gps', authenticateToken, gpsRoutes);

db.sequelize.authenticate()
  .then(() => console.log('✅ Database connected'))
  .catch(err => console.error('❌ Database error:', err));

db.sequelize.sync({ alter: true }) // or force: true for hard reset
  .then(() => console.log('✅ Sequelize synced with database'))
  .catch(err => console.error('❌ Sync error:', err));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});