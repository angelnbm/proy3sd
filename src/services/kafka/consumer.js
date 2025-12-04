import { Kafka, logLevel } from 'kafkajs';
import logger from '../../utils/logger.js';
import { handleEliminationVerified } from './eventHandlers.js';

const kafka = new Kafka({
  clientId: process.env.KAFKA_CLIENT_ID || 'continental-dashboard',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
  logLevel: logLevel.INFO,
  retry: {
    initialRetryTime: 300,
    retries: 8
  }
});

const consumer = kafka.consumer({ 
  groupId: process.env.KAFKA_GROUP_ID || 'dashboard-consumer-group',
  sessionTimeout: 30000,
  heartbeatInterval: 3000
});

let io = null;

const initKafkaConsumer = async (socketIo) => {
  io = socketIo;
  
  try {
    await consumer.connect();
    logger.info('Kafka consumer connected');

    await consumer.subscribe({ 
      topic: process.env.KAFKA_TOPIC || 'continental.events',
      fromBeginning: false 
    });
    logger.info('Subscribed to topic', { topic: process.env.KAFKA_TOPIC });

    await consumer.run({
      autoCommit: false, // Manual commit for retry logic
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const event = JSON.parse(message.value.toString());
          logger.info('Event received from Kafka', { 
            topic, 
            partition,
            offset: message.offset,
            eventType: event.eventType 
          });

          // Route events based on type
          switch (event.eventType) {
            case 'EliminationVerified':
              await handleEliminationVerified(event, io);
              break;
            default:
              logger.warn('Unknown event type', { eventType: event.eventType });
          }

          // Commit only after successful processing
          await consumer.commitOffsets([{
            topic,
            partition,
            offset: (parseInt(message.offset) + 1).toString()
          }]);
          
          logger.info('Event processed successfully', { 
            offset: message.offset,
            eventType: event.eventType 
          });

        } catch (error) {
          logger.error('Error processing Kafka message', {
            error: error.message,
            stack: error.stack,
            topic,
            partition,
            offset: message.offset
          });
          
          // Don't commit - message will be reprocessed
          // This ensures at-least-once delivery semantics
        }
      }
    });

  } catch (error) {
    logger.error('Failed to initialize Kafka consumer', {
      error: error.message,
      stack: error.stack
    });
    throw error;
  }
};

const disconnectConsumer = async () => {
  try {
    await consumer.disconnect();
    logger.info('Kafka consumer disconnected');
  } catch (error) {
    logger.error('Error disconnecting Kafka consumer', { error: error.message });
  }
};

export { initKafkaConsumer, disconnectConsumer };
