'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('devices', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'SET NULL'
      },
      device_uid: { type: Sequelize.STRING, allowNull: true, unique: true },
      nickname: { type: Sequelize.STRING },
      registered_at: { type: Sequelize.DATE, defaultValue: Sequelize.NOW }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('devices');
  }
};