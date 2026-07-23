// models/gpslog.js

'use strict';
module.exports = (sequelize, DataTypes) => {
  const GPSLog = sequelize.define('GPSLog', {
    device_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 7),
      allowNull: false,
    },
    longitude: {
      type: DataTypes.DECIMAL(10, 7),
      allowNull: false,
    },
    speed: {
      type: DataTypes.FLOAT,
      allowNull: true,
    },
    timestamp: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'gps_logs',
    underscored: true,
    timestamps: false,
  });

  GPSLog.associate = (models) => {
    GPSLog.belongsTo(models.Device, {
      foreignKey: 'device_id',
      onDelete: 'CASCADE',
    });
  };

  return GPSLog;
};