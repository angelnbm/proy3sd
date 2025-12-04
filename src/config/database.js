import { Sequelize } from 'sequelize';
import logger from '../utils/logger.js';

// Master connection (writes) - LXC 302
const masterConnection = new Sequelize({
  host: process.env.DB_MASTER_HOST,
  port: process.env.DB_MASTER_PORT || 3306,
  database: process.env.DB_MASTER_DATABASE,
  username: process.env.DB_MASTER_USER,
  password: process.env.DB_MASTER_PASSWORD,
  dialect: 'mysql',
  logging: (msg) => logger.debug(msg),
  pool: {
    max: 10,
    min: 2,
    acquire: 30000,
    idle: 10000
  },
  dialectOptions: {
    connectTimeout: 10000
  }
});

// Slave connection (reads) - LXC 303
const slaveConnection = new Sequelize({
  host: process.env.DB_SLAVE_HOST,
  port: process.env.DB_SLAVE_PORT || 3306,
  database: process.env.DB_SLAVE_DATABASE,
  username: process.env.DB_SLAVE_USER,
  password: process.env.DB_SLAVE_PASSWORD,
  dialect: 'mysql',
  logging: (msg) => logger.debug(msg),
  pool: {
    max: 15,
    min: 5,
    acquire: 30000,
    idle: 10000
  },
  dialectOptions: {
    connectTimeout: 10000
  }
});

// Test connections
const connectDatabase = async () => {
  try {
    await masterConnection.authenticate();
    logger.info('Master database connection established', { 
      host: process.env.DB_MASTER_HOST 
    });
    
    await slaveConnection.authenticate();
    logger.info('Slave database connection established', { 
      host: process.env.DB_SLAVE_HOST 
    });
    
    return true;
  } catch (error) {
    logger.error('Database connection failed', { 
      error: error.message,
      stack: error.stack 
    });
    throw error;
  }
};

// Helper function to get the appropriate connection
const getWriteConnection = () => masterConnection;
const getReadConnection = () => slaveConnection;

export {
  masterConnection,
  slaveConnection,
  connectDatabase,
  getWriteConnection,
  getReadConnection
};
