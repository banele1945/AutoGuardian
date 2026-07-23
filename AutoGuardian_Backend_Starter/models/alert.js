'use strict';

module.exports = (sequelize, DataTypes) => {
  const Alert = sequelize.define('Alert', {
    device_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    type: {
      type: DataTypes.STRING,
      allowNull: false
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    timestamp: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'alerts',
    underscored: true,
    timestamps: false
  });

  Alert.associate = (models) => {
    Alert.belongsTo(models.Device, {
      foreignKey: 'device_id',
      onDelete: 'CASCADE'
    });
  };

  return Alert;
};