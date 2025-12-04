import { DataTypes } from 'sequelize';
import { getWriteConnection } from '../config/database.js';

const masterDb = getWriteConnection();

const Contract = masterDb.define('Contract', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  contractId: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
    field: 'contract_id'
  },
  assassinId: {
    type: DataTypes.STRING(50),
    allowNull: false,
    field: 'assassin_id'
  },
  targetId: {
    type: DataTypes.STRING(50),
    allowNull: false,
    field: 'target_id'
  },
  status: {
    type: DataTypes.ENUM('active', 'completed', 'cancelled'),
    defaultValue: 'active',
    field: 'status'
  },
  coinsOffered: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    field: 'coins_offered'
  },
  startDate: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'start_date'
  },
  completionDate: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'completion_date'
  }
}, {
  tableName: 'contracts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

export default Contract;
