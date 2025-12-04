import { DataTypes } from 'sequelize';
import { getWriteConnection } from '../config/database.js';

const masterDb = getWriteConnection();

const Assassin = masterDb.define('Assassin', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  assassinId: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
    field: 'assassin_id'
  },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  totalEliminations: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'total_eliminations'
  },
  totalCoinsEarned: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
    field: 'total_coins_earned'
  },
  successRate: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 0,
    field: 'success_rate'
  },
  averageTimeToComplete: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'Average time in hours',
    field: 'avg_time_to_complete'
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'suspended'),
    defaultValue: 'active'
  }
}, {
  tableName: 'assassins',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

export default Assassin;
