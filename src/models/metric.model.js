import { DataTypes } from 'sequelize';
import { getWriteConnection } from '../config/database.js';

const masterDb = getWriteConnection();

const DashboardMetric = masterDb.define('DashboardMetric', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  metricDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    field: 'metric_date'
  },
  totalEliminations: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'total_eliminations'
  },
  totalContracts: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'total_contracts'
  },
  activeContracts: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'active_contracts'
  },
  completedContracts: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'completed_contracts'
  },
  totalCoinsPaid: {
    type: DataTypes.DECIMAL(12, 2),
    defaultValue: 0,
    field: 'total_coins_paid'
  },
  activeAssassins: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'active_assassins'
  },
  averageContractValue: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
    field: 'avg_contract_value'
  }
}, {
  tableName: 'dashboard_metrics',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      unique: true,
      fields: ['metric_date']
    }
  ]
});

export default DashboardMetric;
