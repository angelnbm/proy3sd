import { DataTypes } from 'sequelize';
import { getWriteConnection, getReadConnection } from '../config/database.js';

const masterDb = getWriteConnection();

const Elimination = masterDb.define('Elimination', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  contractId: {
    type: DataTypes.STRING(50),
    allowNull: false,
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
  eliminationDate: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'elimination_date'
  },
  verificationStatus: {
    type: DataTypes.ENUM('pending', 'verified', 'rejected'),
    defaultValue: 'verified',
    field: 'verification_status'
  },
  coinsAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    field: 'coins_amount'
  },
  processedAt: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'processed_at'
  }
}, {
  tableName: 'eliminations',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

export default Elimination;
