import express from 'express';
import { 
  getEliminationMetrics, 
  getFinancialMetrics, 
  getAssassinEfficiency 
} from '../controllers/metrics.controller.js';

const router = express.Router();

/**
 * GET /api/v1/metrics/eliminations
 * Returns elimination metrics and trends
 * Query params: ?period=week|month|year
 */
router.get('/eliminations', getEliminationMetrics);

/**
 * GET /api/v1/metrics/financials
 * Returns financial metrics summary
 * Query params: ?period=week|month|year
 */
router.get('/financials', getFinancialMetrics);

/**
 * GET /api/v1/metrics/assassins
 * Returns assassin efficiency metrics
 */
router.get('/assassins', getAssassinEfficiency);

export default router;
