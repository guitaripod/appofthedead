-- Users table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  appleId TEXT UNIQUE,
  totalXP INTEGER NOT NULL DEFAULT 0,
  currentLevel INTEGER NOT NULL DEFAULT 1,
  streakDays INTEGER NOT NULL DEFAULT 0,
  lastActiveDate TEXT,
  createdAt TEXT NOT NULL DEFAULT (datetime('now')),
  updatedAt TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Progress table
CREATE TABLE IF NOT EXISTS progress (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  beliefSystemId TEXT NOT NULL,
  lessonId TEXT,
  status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'completed')),
  score INTEGER,
  earnedXP INTEGER NOT NULL DEFAULT 0,
  completedAt TEXT,
  createdAt TEXT NOT NULL DEFAULT (datetime('now')),
  updatedAt TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(userId, beliefSystemId, lessonId)
);

-- User achievements table
CREATE TABLE IF NOT EXISTS user_achievements (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  achievementId TEXT NOT NULL,
  progress REAL NOT NULL DEFAULT 0,
  isCompleted INTEGER NOT NULL DEFAULT 0,
  completedAt TEXT,
  createdAt TEXT NOT NULL DEFAULT (datetime('now')),
  updatedAt TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(userId, achievementId)
);

-- User answers table (for analytics)
CREATE TABLE IF NOT EXISTS user_answers (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  questionId TEXT NOT NULL,
  questionType TEXT NOT NULL,
  beliefSystemId TEXT NOT NULL,
  lessonId TEXT NOT NULL,
  userAnswer TEXT NOT NULL,
  isCorrect INTEGER NOT NULL,
  attemptedAt TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_progress_user ON progress(userId);
CREATE INDEX IF NOT EXISTS idx_progress_belief ON progress(beliefSystemId);
CREATE INDEX IF NOT EXISTS idx_achievements_user ON user_achievements(userId);
CREATE INDEX IF NOT EXISTS idx_answers_user ON user_answers(userId);
CREATE INDEX IF NOT EXISTS idx_users_apple ON users(appleId);

-- Triggers to update timestamps
CREATE TRIGGER IF NOT EXISTS update_users_timestamp 
  AFTER UPDATE ON users
  BEGIN
    UPDATE users SET updatedAt = datetime('now') WHERE id = NEW.id;
  END;

CREATE TRIGGER IF NOT EXISTS update_progress_timestamp 
  AFTER UPDATE ON progress
  BEGIN
    UPDATE progress SET updatedAt = datetime('now') WHERE id = NEW.id;
  END;

CREATE TRIGGER IF NOT EXISTS update_achievements_timestamp 
  AFTER UPDATE ON user_achievements
  BEGIN
    UPDATE user_achievements SET updatedAt = datetime('now') WHERE id = NEW.id;
  END;