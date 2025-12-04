import { 
  getDashboardOverview, 
  getEliminationTrends,
  getAssassinMetrics,
  getFinancialSummary 
} from '../repositories/metrics.repository.js';
import logger from '../utils/logger.js';

/**
 * GET /api/v1/dashboard/overview
 * Returns comprehensive dashboard overview
 */
export const getOverview = async (req, res, next) => {
  try {
    const startTime = Date.now();

    // Fetch all metrics in parallel for performance
    const [overview, trends, topAssassins, financial] = await Promise.all([
      getDashboardOverview(),
      getEliminationTrends(30),
      getAssassinMetrics(),
      getFinancialSummary('month')
    ]);

    const response = {
      timestamp: new Date().toISOString(),
      overview: {
        activeContracts: overview.activeContracts || 0,
        completedContracts: overview.completedContracts || 0,
        todayEliminations: overview.todayEliminations || 0,
        monthlyRevenue: parseFloat(overview.monthlyRevenue || 0),
        activeAssassins: overview.activeAssassins || 0,
        avgContractValue: parseFloat(overview.avgContractValue || 0)
      },
      trends: trends.map(t => ({
        date: t.date,
        eliminations: t.count,
        revenue: parseFloat(t.revenue)
      })),
      topAssassins: topAssassins.slice(0, 10).map(a => ({
        assassinId: a.assassin_id,
        name: a.name,
        totalEliminations: a.total_eliminations,
        totalEarnings: parseFloat(a.total_coins_earned),
        successRate: parseFloat(a.success_rate),
        recentEliminations: a.recentEliminations,
        recentEarnings: parseFloat(a.recentEarnings || 0)
      })),
      financial: {
        totalPaid: parseFloat(financial.totalPaid || 0),
        totalTransactions: financial.totalTransactions || 0,
        avgTransaction: parseFloat(financial.avgTransaction || 0),
        highestPayout: parseFloat(financial.highestPayout || 0),
        lowestPayout: parseFloat(financial.lowestPayout || 0)
      }
    };

    const loadTime = Date.now() - startTime;
    logger.info('Dashboard overview loaded', { loadTimeMs: loadTime });

    // SLO: Load time < 2 seconds
    if (loadTime > 2000) {
      logger.warn('Dashboard load time exceeded SLO', { loadTimeMs: loadTime });
    }

    res.json(response);
  } catch (error) {
    logger.error('Error fetching dashboard overview', { 
      error: error.message,
      stack: error.stack 
    });
    next(error);
  }
};

/**
 * GET /api/v1/dashboard/reports
 * Generate executive reports
 */
export const getReports = async (req, res, next) => {
  try {
    const { period = 'month', format = 'json' } = req.query;

    const [trends, assassins, financial] = await Promise.all([
      getEliminationTrends(period === 'year' ? 365 : period === 'week' ? 7 : 30),
      getAssassinMetrics(),
      getFinancialSummary(period)
    ]);

    const report = {
      generatedAt: new Date().toISOString(),
      period,
      summary: {
        totalEliminations: trends.reduce((sum, t) => sum + t.count, 0),
        totalRevenue: trends.reduce((sum, t) => sum + parseFloat(t.revenue), 0),
        averageDaily: trends.length > 0 
          ? trends.reduce((sum, t) => sum + t.count, 0) / trends.length 
          : 0
      },
      trends,
      assassins,
      financial
    };

    if (format === 'csv') {
      // Generate CSV format
      const csv = generateCSV(report);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="continental-report-${period}.csv"`);
      res.send(csv);
    } else {
      res.json(report);
    }

  } catch (error) {
    logger.error('Error generating report', { 
      error: error.message,
      stack: error.stack 
    });
    next(error);
  }
};

/**
 * POST /api/v1/dashboard/alerts
 * Configure dashboard alerts
 */
export const createAlert = async (req, res, next) => {
  try {
    const { type, threshold, notification } = req.body;

    // TODO: Implement alert configuration storage
    // For now, just acknowledge the alert creation

    const alert = {
      id: `alert-${Date.now()}`,
      type,
      threshold,
      notification,
      createdAt: new Date().toISOString(),
      status: 'active'
    };

    logger.info('Alert created', { alert });

    res.status(201).json({
      success: true,
      alert
    });

  } catch (error) {
    logger.error('Error creating alert', { 
      error: error.message,
      stack: error.stack 
    });
    next(error);
  }
};

/**
 * Helper: Generate CSV from report data
 */
const generateCSV = (report) => {
  let csv = 'Date,Eliminations,Revenue\n';
  report.trends.forEach(t => {
    csv += `${t.date},${t.count},${t.revenue}\n`;
  });
  return csv;
};
