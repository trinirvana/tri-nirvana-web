-- Tri Nirvana AI Platform Database Schema

USE tri_nirvana;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    experience_level ENUM('beginner', 'intermediate', 'advanced', 'elite') DEFAULT 'beginner',
    preferred_units ENUM('metric', 'imperial') DEFAULT 'metric',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Race predictions table
CREATE TABLE IF NOT EXISTS race_predictions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(255),
    race_distance VARCHAR(50) NOT NULL,
    swim_pace VARCHAR(10),
    bike_speed DECIMAL(5,2),
    run_pace VARCHAR(10),
    predicted_time INT,
    belt_ranking VARCHAR(20),
    environmental_factors JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (user_email),
    INDEX idx_race_distance (race_distance),
    INDEX idx_created_at (created_at)
);

-- Workout sessions table
CREATE TABLE IF NOT EXISTS workout_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(255),
    workout_type VARCHAR(50) NOT NULL,
    rpe_level INT CHECK (rpe_level BETWEEN 1 AND 10),
    duration INT,
    generated_workout TEXT,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (user_email),
    INDEX idx_workout_type (workout_type),
    INDEX idx_created_at (created_at)
);

-- Tool usage analytics table
CREATE TABLE IF NOT EXISTS tool_usage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    user_email VARCHAR(255),
    session_id VARCHAR(255),
    usage_data JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tool_name (tool_name),
    INDEX idx_user_email (user_email),
    INDEX idx_created_at (created_at)
);

-- Performance data table (for future advanced analytics)
CREATE TABLE IF NOT EXISTS performance_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(255),
    discipline ENUM('swim', 'bike', 'run', 'transition') NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,3),
    metric_unit VARCHAR(20),
    test_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (user_email),
    INDEX idx_discipline (discipline),
    INDEX idx_test_date (test_date)
);

-- Insert sample data for development
INSERT IGNORE INTO users (email, name, experience_level) VALUES 
('demo@trinirvana.com', 'Demo User', 'intermediate'),
('coach@trinirvana.com', 'Coach Sam', 'elite');

-- Create views for common queries
CREATE OR REPLACE VIEW user_activity_summary AS
SELECT 
    u.email,
    u.name,
    COUNT(DISTINCT rp.id) as race_predictions_count,
    COUNT(DISTINCT ws.id) as workout_sessions_count,
    COUNT(DISTINCT tu.id) as tool_usage_count,
    MAX(tu.created_at) as last_activity
FROM users u
LEFT JOIN race_predictions rp ON u.email = rp.user_email
LEFT JOIN workout_sessions ws ON u.email = ws.user_email
LEFT JOIN tool_usage tu ON u.email = tu.user_email
GROUP BY u.id, u.email, u.name;