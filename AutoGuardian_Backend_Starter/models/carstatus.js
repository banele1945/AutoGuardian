module.exports = (sequelize, DataTypes) => {
  const CarStatus = sequelize.define('CarStatus', {
    device_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    ignition_on: {
      type: DataTypes.BOOLEAN,
      allowNull: true,
    },
    battery_voltage: {
      type: DataTypes.FLOAT,
      allowNull: true,
    },
    door_open: {
      type: DataTypes.BOOLEAN,
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('ARMED', 'DISARMED'),
      allowNull: false,
    },
    engine_status: {
      type: DataTypes.ENUM('ON', 'OFF'),
      allowNull: false,
    },
    fuel_level: {
      type: DataTypes.FLOAT,
      allowNull: true,
    },
    timestamp: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'car_statuses',
    underscored: true,
    timestamps: false,
  });

  CarStatus.associate = models => {
    CarStatus.belongsTo(models.Device, { foreignKey: 'device_id' });
  };

  return CarStatus;
}; 