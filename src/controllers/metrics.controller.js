import { 
  getEliminationTrends, 
  getAssassinMetrics,
  getFinancialSummary 
} from '../repositories/metrics.repository.js';
import logger from '../utils/logger.js';

/**
 * GET /api/v1/metrics/eliminations
 */
export const getEliminationMetrics = async (req, res, next) => {
  try {
    const { period = 'month' } = req.query;
    const days = period === 'year' ? 365 : period === 'week' ? 7 : 30;

    const trends = await getEliminationTrends(days);

    const metrics = {
      period,
      totalEliminations: trends.reduce((sum, t) => sum + t.count, 0),
      totalRevenue: trends.reduce((sum, t) => sum + parseFloat(t.revenue), 0),
      averagePerDay: trends.length > 0 
        ? trends.reduce((sum, t) => sum + t.count, 0) / trends.length 
        : 0,
      trends: trends.map(t => ({
        date: t.date,
        count: t.count,
        revenue: parseFloat(t.revenue)
      }))
    };

    res.json(metrics);
  } catch (error) {
    logger.error('Error fetching elimination metrics', { error: error.message });
    next(error);
  }
};

/**
 * GET /api/v1/metrics/financials
 */
export const getFinancialMetrics = async (req, res, next) => {
  try {
    const { period = 'month' } = req.query;

    const financial = await getFinancialSummary(period);

    const metrics = {
      period,
      totalPaid: parseFloat(financial.totalPaid || 0),
      totalTransactions: financial.totalTransactions || 0,
      avgTransaction: parseFloat(financial.avgTransaction || 0),
      highestPayout: parseFloat(financial.highestPayout || 0),
      lowestPayout: parseFloat(financial.lowestPayout || 0)
    };

    res.json(metrics);
  } catch (error) {
    logger.error('Error fetching financial metrics', { error: error.message });
    next(error);
  }
};

/**
 * GET /api/v1/metrics/assassins
 */
export const getAssassinEfficiency = async (req, res, next) => {
  try {
    const assassins = await getAssassinMetrics();

    const metrics = {
      totalAssassins: assassins.length,
      assassins: assassins.map(a => ({
        assassinId: a.assassin_id,
        name: a.name,
        totalEliminations: a.total_eliminations,
        totalEarnings: parseFloat(a.total_coins_earned),
        successRate: parseFloat(a.success_rate),
        recentEliminations: a.recentEliminations,
        recentEarnings: parseFloat(a.recentEarnings || 0),
        efficiency: calculateEfficiency(a)
      }))
    };

    res.json(metrics);
  } catch (error) {
    logger.error('Error fetching assassin metrics', { error: error.message });
    next(error);
  }
};

/**
 * Calculate assassin efficiency score
 */
const calculateEfficiency = (assassin) => {
  const successWeight = 0.4;
  const volumeWeight = 0.3;
  const recentWeight = 0.3;

  const successScore = parseFloat(assassin.success_rate) || 0;
  const volumeScore = Math.min(assassin.total_eliminations / 10, 100); // Normalize to 100
  const recentScore = Math.min(assassin.recentEliminations * 10, 100);

  return (
    successScore * successWeight +
    volumeScore * volumeWeight +
    recentScore * recentWeight
  ).toFixed(2);
};
