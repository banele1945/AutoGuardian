'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('car_statuses', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      device_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'devices',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      status: { type: Sequelize.ENUM('ARMED', 'DISARMED'), allowNull: false },
      engine_status: { type: Sequelize.ENUM('ON', 'OFF'), allowNull: false },
      fuel_level: { type: Sequelize.FLOAT, allowNull: true },
      timestamp: { type: Sequelize.DATE, defaultValue: Sequelize.NOW }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('car_statuses');
  }
}; 