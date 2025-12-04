-- Continental Dashboard Database Schema

-- Eliminations table
CREATE TABLE IF NOT EXISTS eliminations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  contract_id VARCHAR(50) NOT NULL,
  assassin_id VARCHAR(50) NOT NULL,
  target_id VARCHAR(50) NOT NULL,
  elimination_date DATETIME NOT NULL,
  verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'verified',
  coins_amount DECIMAL(10, 2) NOT NULL,
  processed_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_contract_id (contract_id),
  INDEX idx_assassin_id (assassin_id),
  INDEX idx_elimination_date (elimination_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Contracts table
CREATE TABLE IF NOT EXISTS contracts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  contract_id VARCHAR(50) NOT NULL UNIQUE,
  assassin_id VARCHAR(50) NOT NULL,
  target_id VARCHAR(50) NOT NULL,
  status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
  coins_offered DECIMAL(10, 2) NOT NULL,
  start_date DATETIME NOT NULL,
  completion_date DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_contract_id (contract_id),
  INDEX idx_status (status),
  INDEX idx_assassin_id (assassin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Assassins table
CREATE TABLE IF NOT EXISTS assassins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  assassin_id VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  total_eliminations INT DEFAULT 0,
  total_coins_earned DECIMAL(10, 2) DEFAULT 0,
  success_rate DECIMAL(5, 2) DEFAULT 0,
  avg_time_to_complete INT NULL COMMENT 'Average time in hours',
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_assassin_id (assassin_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dashboard Metrics table
CREATE TABLE IF NOT EXISTS dashboard_metrics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  metric_date DATE NOT NULL UNIQUE,
  total_eliminations INT DEFAULT 0,
  total_contracts INT DEFAULT 0,
  active_contracts INT DEFAULT 0,
  completed_contracts INT DEFAULT 0,
  total_coins_paid DECIMAL(12, 2) DEFAULT 0,
  active_assassins INT DEFAULT 0,
  avg_contract_value DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_metric_date (metric_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample data for testing
INSERT INTO assassins (assassin_id, name, total_eliminations, total_coins_earned, success_rate, status) VALUES
('ASN-001', 'John Wick', 47, 2350000.00, 98.50, 'active'),
('ASN-002', 'Cassian', 32, 1600000.00, 94.20, 'active'),
('ASN-003', 'Ares', 28, 1400000.00, 89.75, 'active'),
('ASN-004', 'Zero', 41, 2050000.00, 96.80, 'active'),
('ASN-005', 'Sofia', 35, 1750000.00, 92.10, 'active');

INSERT INTO contracts (contract_id, assassin_id, target_id, status, coins_offered, start_date, completion_date) VALUES
('CNT-2024-001', 'ASN-001', 'TGT-789', 'completed', 50000.00, '2024-01-15 10:00:00', '2024-01-16 14:30:00'),
('CNT-2024-002', 'ASN-002', 'TGT-790', 'completed', 75000.00, '2024-02-01 08:00:00', '2024-02-03 18:45:00'),
('CNT-2024-003', 'ASN-001', 'TGT-791', 'active', 100000.00, '2024-12-01 09:00:00', NULL),
('CNT-2024-004', 'ASN-004', 'TGT-792', 'active', 85000.00, '2024-12-02 11:00:00', NULL);
