'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('alerts', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      device_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'devices',
          key: 'id'
        },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE'
      },
      type: {
        type: Sequelize.ENUM('ARM', 'DISARM', 'TAMPER', 'POWER_CUT'),
        allowNull: true
      },
      message: { type: Sequelize.TEXT },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.NOW }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('alerts');
  }
};