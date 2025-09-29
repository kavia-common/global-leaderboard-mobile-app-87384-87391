-- Schema for mobile gaming leaderboard app

-- Ensure database exists (run at server level)
CREATE DATABASE IF NOT EXISTS myapp;

-- Use database
USE myapp;

-- Regions lookup table for normalized regional data
CREATE TABLE IF NOT EXISTS regions (
  code VARCHAR(10) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users table with regional association
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  region_code VARCHAR(10) NULL,
  avatar_url VARCHAR(255) NULL,
  bio VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_region (region_code),
  CONSTRAINT fk_users_region FOREIGN KEY (region_code)
    REFERENCES regions(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Games metadata
CREATE TABLE IF NOT EXISTS games (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  genre VARCHAR(50) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_games_name (name),
  KEY idx_games_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scores table supports leaderboards (global and per-region)
CREATE TABLE IF NOT EXISTS scores (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  game_id BIGINT UNSIGNED NOT NULL,
  score BIGINT NOT NULL,
  submission_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  region_code VARCHAR(10) NULL,
  PRIMARY KEY (id),
  KEY idx_scores_game_score (game_id, score DESC),
  KEY idx_scores_user (user_id),
  KEY idx_scores_region_game (region_code, game_id, score DESC),
  CONSTRAINT fk_scores_user FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_scores_game FOREIGN KEY (game_id)
    REFERENCES games(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_scores_region FOREIGN KEY (region_code)
    REFERENCES regions(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional aggregated stats to speed up best-score lookups
CREATE TABLE IF NOT EXISTS user_game_stats (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  game_id BIGINT UNSIGNED NOT NULL,
  best_score BIGINT NOT NULL DEFAULT 0,
  last_played DATETIME NULL,
  total_plays INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_game (user_id, game_id),
  KEY idx_stats_best (game_id, best_score DESC),
  CONSTRAINT fk_stats_user FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_stats_game FOREIGN KEY (game_id)
    REFERENCES games(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Additional indexes (MySQL prior to 8.0.13 doesn't support IF NOT EXISTS on CREATE INDEX)
-- Apply conditionally in deployment scripts if necessary:
-- CREATE INDEX idx_scores_submission_date ON scores(submission_date);
