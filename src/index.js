import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import logger from './utils/logger.js';
import { connectDatabase } from './config/database.js';
import { initKafkaConsumer } from './services/kafka/consumer.js';
import dashboardRoutes from './routes/dashboard.routes.js';
import metricsRoutes from './routes/metrics.routes.js';
import errorHandler from './middleware/errorHandler.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST']
  },
  path: process.env.SOCKET_IO_PATH || '/socket.io'
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'Continental Dashboard',
    timestamp: new Date().toISOString()
  });
});

app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/metrics', metricsRoutes);

// Error handling
app.use(errorHandler);

// WebSocket connection
io.on('connection', (socket) => {
  logger.info('Client connected to WebSocket', { socketId: socket.id });
  
  socket.on('disconnect', () => {
    logger.info('Client disconnected from WebSocket', { socketId: socket.id });
  });
});

// Make io available globally for event broadcasting
app.set('io', io);

// Initialize services
const startServer = async () => {
  try {
    // Connect to database
    await connectDatabase();
    logger.info('Database connection established');

    // Initialize Kafka consumer
    await initKafkaConsumer(io);
    logger.info('Kafka consumer initialized');

    // Start server
    const PORT = process.env.PORT || 3000;
    const HOST = process.env.HOST || '0.0.0.0';
    
    httpServer.listen(PORT, HOST, () => {
      logger.info(`Continental Dashboard running on ${HOST}:${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV}`);
    });

  } catch (error) {
    logger.error('Failed to start server', { error: error.message, stack: error.stack });
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async () => {
  logger.info('Shutting down gracefully...');
  
  httpServer.close(() => {
    logger.info('HTTP server closed');
  });

  // Close database connections
  // Close Kafka consumer
  
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start the server
startServer();

export { app, io };
