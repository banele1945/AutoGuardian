module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    username: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false
    },
    password_hash: {
      type: DataTypes.STRING,
      allowNull: false
    }
  }, {
    tableName: 'users',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  User.associate = models => {
    User.hasMany(models.Device, { foreignKey: 'user_id' });
  };

  return User;
};