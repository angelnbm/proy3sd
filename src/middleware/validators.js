import Joi from 'joi';
import logger from '../utils/logger.js';

/**
 * Validate alert creation payload
 */
export const validateAlert = (req, res, next) => {
  const schema = Joi.object({
    type: Joi.string()
      .valid('elimination_threshold', 'revenue_drop', 'assassin_inactive', 'contract_delay')
      .required(),
    threshold: Joi.number()
      .positive()
      .required(),
    notification: Joi.object({
      email: Joi.string().email().optional(),
      webhook: Joi.string().uri().optional(),
      slack: Joi.string().optional()
    }).required()
  });

  const { error, value } = schema.validate(req.body);

  if (error) {
    logger.warn('Alert validation failed', { 
      error: error.details[0].message,
      body: req.body 
    });
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: error.details[0].message
    });
  }

  req.validatedData = value;
  next();
};
