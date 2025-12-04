import { getReadConnection } from '../config/database.js';
import logger from '../utils/logger.js';

const slaveDb = getReadConnection();

/**
 * Get dashboard overview metrics from Slave database
 */
export const getDashboardOverview = async () => {
  try {
    const [results] = await slaveDb.query(`
      SELECT 
        (SELECT COUNT(*) FROM contracts WHERE status = 'active') as activeContracts,
        (SELECT COUNT(*) FROM contracts WHERE status = 'completed') as completedContracts,
        (SELECT COUNT(*) FROM eliminations WHERE DATE(elimination_date) = CURDATE()) as todayEliminations,
        (SELECT SUM(coins_amount) FROM eliminations WHERE MONTH(elimination_date) = MONTH(CURDATE())) as monthlyRevenue,
        (SELECT COUNT(DISTINCT assassin_id) FROM eliminations WHERE MONTH(elimination_date) = MONTH(CURDATE())) as activeAssassins,
        (SELECT AVG(coins_amount) FROM contracts WHERE status = 'completed') as avgContractValue
    `);

    return results[0];
  } catch (error) {
    logger.error('Error fetching dashboard overview', { error: error.message });
    throw error;
  }
};

/**
 * Get elimination trends for charts
 */
export const getEliminationTrends = async (days = 30) => {
  try {
    const [results] = await slaveDb.query(`
      SELECT 
        DATE(elimination_date) as date,
        COUNT(*) as count,
        SUM(coins_amount) as revenue
      FROM eliminations
      WHERE elimination_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
      GROUP BY DATE(elimination_date)
      ORDER BY date ASC
    `, {
      replacements: { days }
    });

    return results;
  } catch (error) {
    logger.error('Error fetching elimination trends', { error: error.message });
    throw error;
  }
};

/**
 * Get assassin efficiency metrics
 */
export const getAssassinMetrics = async () => {
  try {
    const [results] = await slaveDb.query(`
      SELECT 
        a.assassin_id,
        a.name,
        a.total_eliminations,
        a.total_coins_earned,
        a.success_rate,
        COUNT(e.id) as recentEliminations,
        SUM(e.coins_amount) as recentEarnings
      FROM assassins a
      LEFT JOIN eliminations e ON a.assassin_id = e.assassin_id 
        AND e.elimination_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      WHERE a.status = 'active'
      GROUP BY a.id, a.assassin_id, a.name, a.total_eliminations, a.total_coins_earned, a.success_rate
      ORDER BY a.total_eliminations DESC
      LIMIT 20
    `);

    return results;
  } catch (error) {
    logger.error('Error fetching assassin metrics', { error: error.message });
    throw error;
  }
};

/**
 * Get financial summary
 */
export const getFinancialSummary = async (period = 'month') => {
  try {
    let dateCondition = 'MONTH(elimination_date) = MONTH(CURDATE())';
    if (period === 'week') dateCondition = 'elimination_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)';
    if (period === 'year') dateCondition = 'YEAR(elimination_date) = YEAR(CURDATE())';

    const [results] = await slaveDb.query(`
      SELECT 
        SUM(coins_amount) as totalPaid,
        COUNT(*) as totalTransactions,
        AVG(coins_amount) as avgTransaction,
        MAX(coins_amount) as highestPayout,
        MIN(coins_amount) as lowestPayout
      FROM eliminations
      WHERE ${dateCondition}
    `);

    return results[0];
  } catch (error) {
    logger.error('Error fetching financial summary', { error: error.message });
    throw error;
  }
};
