import Elimination from '../models/elimination.model.js';
import Contract from '../models/contract.model.js';
import { getWriteConnection, getReadConnection } from '../config/database.js';
import logger from '../utils/logger.js';

const masterDb = getWriteConnection();
const slaveDb = getReadConnection();

/**
 * Save elimination data to Master database
 */
export const saveElimination = async (eliminationData) => {
  try {
    const elimination = await Elimination.create(eliminationData);
    logger.info('Elimination saved to database', { 
      id: elimination.id,
      contractId: eliminationData.contractId 
    });
    return elimination;
  } catch (error) {
    logger.error('Error saving elimination', { 
      error: error.message,
      contractId: eliminationData.contractId 
    });
    throw error;
  }
};

/**
 * Update contract metrics in Master database
 */
export const updateContractMetrics = async (contractId, status) => {
  try {
    const [updated] = await Contract.update(
      { 
        status,
        completionDate: new Date()
      },
      { 
        where: { contractId } 
      }
    );
    
    if (updated) {
      logger.info('Contract metrics updated', { contractId, status });
    }
    
    return updated;
  } catch (error) {
    logger.error('Error updating contract metrics', { 
      error: error.message,
      contractId 
    });
    throw error;
  }
};

/**
 * Get eliminations from Slave database (for reporting)
 */
export const getEliminations = async (filters = {}) => {
  try {
    // Create a read-only model from slave connection
    const EliminationRead = slaveDb.define('Elimination', Elimination.rawAttributes, {
      tableName: 'eliminations',
      timestamps: true
    });

    const { startDate, endDate, assassinId, limit = 100 } = filters;
    
    const where = {};
    if (startDate) where.eliminationDate = { [slaveDb.Sequelize.Op.gte]: startDate };
    if (endDate) where.eliminationDate = { [slaveDb.Sequelize.Op.lte]: endDate };
    if (assassinId) where.assassinId = assassinId;

    const eliminations = await EliminationRead.findAll({
      where,
      limit,
      order: [['eliminationDate', 'DESC']]
    });

    return eliminations;
  } catch (error) {
    logger.error('Error fetching eliminations', { error: error.message });
    throw error;
  }
};

/**
 * Get elimination statistics from Slave database
 */
export const getEliminationStats = async (period = 'week') => {
  try {
    const EliminationRead = slaveDb.define('Elimination', Elimination.rawAttributes, {
      tableName: 'eliminations',
      timestamps: true
    });

    const dateFrom = new Date();
    if (period === 'week') dateFrom.setDate(dateFrom.getDate() - 7);
    if (period === 'month') dateFrom.setMonth(dateFrom.getMonth() - 1);
    if (period === 'year') dateFrom.setFullYear(dateFrom.getFullYear() - 1);

    const [results] = await slaveDb.query(`
      SELECT 
        COUNT(*) as totalEliminations,
        SUM(coins_amount) as totalCoins,
        AVG(coins_amount) as avgCoins,
        COUNT(DISTINCT assassin_id) as uniqueAssassins
      FROM eliminations
      WHERE elimination_date >= :dateFrom
    `, {
      replacements: { dateFrom }
    });

    return results[0];
  } catch (error) {
    logger.error('Error fetching elimination stats', { error: error.message });
    throw error;
  }
};
