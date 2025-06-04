export interface Env {
  DB: D1Database;
  APPLE_TEAM_ID: string;
  APPLE_CLIENT_ID: string;
  APPLE_KEY_ID: string;
  APPLE_PRIVATE_KEY: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  appleId: string;
  totalXP: number;
  currentLevel: number;
  streakDays: number;
  lastActiveDate: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Progress {
  id: string;
  userId: string;
  beliefSystemId: string;
  lessonId: string | null;
  status: 'not_started' | 'in_progress' | 'completed';
  score: number | null;
  earnedXP: number;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface UserAchievement {
  id: string;
  userId: string;
  achievementId: string;
  progress: number;
  isCompleted: boolean;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface SyncData {
  user: User | null;
  progress: Progress[];
  achievements: UserAchievement[];
  lastSyncDate: string | null;
}

export interface AppleTokenPayload {
  iss: string;
  aud: string;
  exp: number;
  iat: number;
  sub: string;
  email?: string;
  email_verified?: string;
  auth_time: number;
}