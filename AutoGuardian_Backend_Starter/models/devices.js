module.exports = (sequelize, DataTypes) => {
  const Device = sequelize.define('Device', {
    device_uid: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    nickname: {
      type: DataTypes.STRING
    }
  }, {
    tableName: 'devices',
    timestamps: true,
    createdAt: 'registered_at',
    updatedAt: false
  });

  Device.associate = models => {
    Device.belongsTo(models.User, { foreignKey: 'user_id' });
    Device.hasMany(models.Alert, { foreignKey: 'device_id' });
    Device.hasMany(models.GPSLog, { foreignKey: 'device_id' });
  };

  return Device;
};