'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('gps_logs', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      device_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'devices',
          key: 'id'
        },
        onDelete: 'SET NULL'
      },
      latitude: {
        type: Sequelize.DECIMAL(9, 6),
        allowNull: false
      },
      longitude: {
        type: Sequelize.DECIMAL(9, 6),
        allowNull: false
      },
      speed_kph: {
        type: Sequelize.FLOAT
      },
      logged_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('gps_logs');
  }
};