import express from 'express';
import { 
  getOverview, 
  getReports, 
  createAlert 
} from '../controllers/dashboard.controller.js';
import { validateAlert } from '../middleware/validators.js';

const router = express.Router();

/**
 * GET /api/v1/dashboard/overview
 * Returns main dashboard view with key metrics
 */
router.get('/overview', getOverview);

/**
 * GET /api/v1/dashboard/reports
 * Downloads executive reports
 * Query params: ?period=week|month|year&format=json|csv
 */
router.get('/reports', getReports);

/**
 * POST /api/v1/dashboard/alerts
 * Configure dashboard alerts
 * Body: { type, threshold, notification }
 */
router.post('/alerts', validateAlert, createAlert);

export default router;
