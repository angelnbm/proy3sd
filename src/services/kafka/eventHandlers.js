import axios from 'axios';
import logger from '../../utils/logger.js';
import { saveElimination, updateContractMetrics } from '../../repositories/elimination.repository.js';

const MAX_RETRIES = parseInt(process.env.MAX_RETRIES) || 5;
const RETRY_DELAY = parseInt(process.env.RETRY_DELAY_MS) || 3000;
const BACKOFF_MULTIPLIER = parseInt(process.env.BACKOFF_MULTIPLIER) || 2;

/**
 * Handles EliminationVerified event from Kafka
 * Critical flow:
 * 1. Log event reception
 * 2. Call App 2 through Kong Gateway to close contract
 * 3. Implement retry logic with exponential backoff
 * 4. Update metrics in database
 * 5. Broadcast to WebSocket clients
 */
export const handleEliminationVerified = async (event, io) => {
  const { 
    contractId, 
    assassinId, 
    targetId, 
    eliminationDate,
    verificationStatus,
    coinsAmount 
  } = event.data;

  logger.info('Processing EliminationVerified event', { 
    contractId, 
    assassinId,
    targetId 
  });

  try {
    // Step 1: Close contract through Kong Gateway (with retry logic)
    const contractClosed = await closeContractWithRetry({
      contractId,
      assassinId,
      coinsAmount,
      eliminationDate
    });

    if (!contractClosed) {
      throw new Error('Failed to close contract after max retries');
    }

    // Step 2: Save elimination data to database (Master)
    await saveElimination({
      contractId,
      assassinId,
      targetId,
      eliminationDate,
      verificationStatus,
      coinsAmount,
      processedAt: new Date()
    });

    // Step 3: Update metrics
    await updateContractMetrics(contractId, 'completed');

    // Step 4: Broadcast update to connected clients via WebSocket
    if (io) {
      io.emit('elimination:verified', {
        contractId,
        assassinId,
        targetId,
        timestamp: new Date().toISOString(),
        status: 'completed'
      });
      
      logger.info('Event broadcasted to WebSocket clients', { contractId });
    }

    logger.info('EliminationVerified event processed successfully', { 
      contractId 
    });

  } catch (error) {
    logger.error('Failed to process EliminationVerified event', {
      error: error.message,
      stack: error.stack,
      contractId
    });
    throw error; // Will cause Kafka to not commit the offset
  }
};

/**
 * Calls App 2 to close contract with exponential backoff retry logic
 * Routes through Kong Gateway (LXC 400)
 */
const closeContractWithRetry = async (contractData) => {
  const contractServiceUrl = process.env.CONTRACT_SERVICE_URL || 
    'http://lxc-400:8000/api/v1/contracts';

  let attempt = 0;
  let delay = RETRY_DELAY;

  while (attempt < MAX_RETRIES) {
    try {
      logger.info('Attempting to close contract', { 
        attempt: attempt + 1,
        maxRetries: MAX_RETRIES,
        contractId: contractData.contractId 
      });

      const response = await axios.post(
        `${contractServiceUrl}/${contractData.contractId}/close`,
        {
          assassinId: contractData.assassinId,
          coinsAmount: contractData.coinsAmount,
          eliminationDate: contractData.eliminationDate,
          closedBy: 'dashboard-orchestrator'
        },
        {
          timeout: 10000,
          headers: {
            'Content-Type': 'application/json',
            'X-Service': 'continental-dashboard'
          }
        }
      );

      if (response.status === 200 || response.status === 201) {
        logger.info('Contract closed successfully', { 
          contractId: contractData.contractId,
          attempt: attempt + 1
        });
        return true;
      }

    } catch (error) {
      attempt++;
      
      logger.warn('Failed to close contract', {
        error: error.message,
        attempt,
        maxRetries: MAX_RETRIES,
        contractId: contractData.contractId,
        nextRetryIn: attempt < MAX_RETRIES ? `${delay}ms` : 'none'
      });

      if (attempt >= MAX_RETRIES) {
        logger.error('Max retries reached for closing contract', {
          contractId: contractData.contractId,
          totalAttempts: attempt
        });
        return false;
      }

      // Exponential backoff
      await sleep(delay);
      delay *= BACKOFF_MULTIPLIER;
    }
  }

  return false;
};

/**
 * Sleep utility for retry delays
 */
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
