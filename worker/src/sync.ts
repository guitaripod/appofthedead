import { Env, SyncData, User, Progress, UserAchievement } from './types';

export class SyncService {
  private env: Env;

  constructor(env: Env) {
    this.env = env;
  }

  async syncData(appleId: string, clientData: SyncData): Promise<SyncData> {
    const db = this.env.DB;
    
    try {
      // Get or create user
      let user = await this.getOrCreateUser(appleId, clientData.user);
      
      // Sync progress data
      const syncedProgress = await this.syncProgress(user.id, clientData.progress);
      
      // Sync achievements
      const syncedAchievements = await this.syncAchievements(user.id, clientData.achievements);
      
      // Update user stats based on synced data
      user = await this.updateUserStats(user.id);
      
      const response = {
        user,
        progress: syncedProgress,
        achievements: syncedAchievements,
        lastSyncDate: null,
      };
      
      return response;
    } catch (error) {
      console.error('Sync error:', error);
      throw error;
    }
  }

  private async getOrCreateUser(appleId: string, clientUser: User | null): Promise<User> {
    const db = this.env.DB;
    
    // Check if user exists with this Apple ID
    const existingUser = await db.prepare(
      'SELECT * FROM users WHERE appleId = ?'
    ).bind(appleId).first<User>();
    
    if (existingUser) {
      // Update user if client data is newer
      if (clientUser && new Date(clientUser.updatedAt) > new Date(existingUser.updatedAt)) {
        await db.prepare(`
          UPDATE users 
          SET name = ?, email = ?, totalXP = ?, currentLevel = ?, 
              streakDays = ?, lastActiveDate = ?, updatedAt = ?
          WHERE id = ?
        `).bind(
          clientUser.name,
          clientUser.email,
          clientUser.totalXP,
          clientUser.currentLevel,
          clientUser.streakDays,
          clientUser.lastActiveDate || null,
          clientUser.updatedAt,
          existingUser.id
        ).run();
        
        const updatedUser = { ...existingUser, ...clientUser };
        // Ensure dates are properly formatted
        updatedUser.createdAt = new Date(updatedUser.createdAt).toISOString();
        updatedUser.updatedAt = new Date(updatedUser.updatedAt).toISOString();
        if (updatedUser.lastActiveDate) {
          updatedUser.lastActiveDate = new Date(updatedUser.lastActiveDate).toISOString();
        }
        return updatedUser;
      }
      // Helper function to ensure proper ISO8601 formatting
      const formatDateEx = (dateStr: string) => {
        if (!dateStr) return dateStr;
        const date = new Date(dateStr);
        if (isNaN(date.getTime())) {
          // If date is invalid, try adding UTC timezone
          const dateWithZ = dateStr.endsWith('Z') ? dateStr : dateStr + 'Z';
          const newDate = new Date(dateWithZ);
          return isNaN(newDate.getTime()) ? dateStr : newDate.toISOString();
        }
        return date.toISOString();
      };
      
      // Ensure dates are properly formatted for existing user
      existingUser.createdAt = formatDateEx(existingUser.createdAt);
      existingUser.updatedAt = formatDateEx(existingUser.updatedAt);
      if (existingUser.lastActiveDate) {
        existingUser.lastActiveDate = formatDateEx(existingUser.lastActiveDate);
      }
      return existingUser;
    }
    
    // Create new user
    const newUser: User = {
      id: clientUser?.id || crypto.randomUUID(),
      name: clientUser?.name || 'Learner',
      email: clientUser?.email || `${appleId}@privaterelay.appleid.com`,
      appleId,
      totalXP: clientUser?.totalXP || 0,
      currentLevel: clientUser?.currentLevel || 1,
      streakDays: clientUser?.streakDays || 0,
      lastActiveDate: clientUser?.lastActiveDate || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    const bindValues = [
      newUser.id,
      newUser.name,
      newUser.email,
      newUser.appleId,
      newUser.totalXP,
      newUser.currentLevel,
      newUser.streakDays,
      newUser.lastActiveDate || null,
      newUser.createdAt,
      newUser.updatedAt
    ];
    
    await db.prepare(`
      INSERT INTO users (id, name, email, appleId, totalXP, currentLevel, 
                        streakDays, lastActiveDate, createdAt, updatedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(...bindValues).run();
    return newUser;
  }

  private async syncProgress(userId: string, clientProgress: Progress[]): Promise<Progress[]> {
    const db = this.env.DB;
    const syncedProgress: Progress[] = [];
    
    for (const progress of clientProgress) {
      const existingProgress = await db.prepare(`
        SELECT * FROM progress 
        WHERE userId = ? AND beliefSystemId = ? AND (lessonId = ? OR (lessonId IS NULL AND ? IS NULL))
      `).bind(userId, progress.beliefSystemId, progress.lessonId, progress.lessonId).first<Progress>();
      
      if (existingProgress) {
        // Update if client is newer
        if (new Date(progress.updatedAt) > new Date(existingProgress.updatedAt)) {
          await db.prepare(`
            UPDATE progress 
            SET status = ?, score = ?, earnedXP = ?, completedAt = ?, updatedAt = ?
            WHERE id = ?
          `).bind(
            progress.status,
            progress.score || null,
            progress.earnedXP,
            progress.completedAt || null,
            progress.updatedAt,
            existingProgress.id
          ).run();
          
          syncedProgress.push({ ...existingProgress, ...progress });
        } else {
          syncedProgress.push(existingProgress);
        }
      } else {
        // Insert new progress
        const newProgress: Progress = {
          ...progress,
          id: crypto.randomUUID(),
          userId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        
        await db.prepare(`
          INSERT INTO progress (id, userId, beliefSystemId, lessonId, status, 
                               score, earnedXP, completedAt, createdAt, updatedAt)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          newProgress.id,
          newProgress.userId,
          newProgress.beliefSystemId,
          newProgress.lessonId || null,
          newProgress.status,
          newProgress.score || null,
          newProgress.earnedXP,
          newProgress.completedAt || null,
          newProgress.createdAt,
          newProgress.updatedAt
        ).run();
        
        syncedProgress.push(newProgress);
      }
    }
    
    // Get all server progress for this user
    const serverProgress = await db.prepare(
      'SELECT * FROM progress WHERE userId = ?'
    ).bind(userId).all<Progress>();
    
    // Include server progress not in client data
    for (const sp of serverProgress.results) {
      const exists = syncedProgress.find(p => 
        p.beliefSystemId === sp.beliefSystemId && 
        p.lessonId === sp.lessonId
      );
      if (!exists) {
        syncedProgress.push(sp);
      }
    }
    
    return syncedProgress;
  }

  private async syncAchievements(userId: string, clientAchievements: UserAchievement[]): Promise<UserAchievement[]> {
    const db = this.env.DB;
    const syncedAchievements: UserAchievement[] = [];
    
    for (const achievement of clientAchievements) {
      const existingAchievement = await db.prepare(`
        SELECT * FROM user_achievements 
        WHERE userId = ? AND achievementId = ?
      `).bind(userId, achievement.achievementId).first<UserAchievement>();
      
      if (existingAchievement) {
        // Update if client has more progress
        if (achievement.progress > existingAchievement.progress) {
          await db.prepare(`
            UPDATE user_achievements 
            SET progress = ?, isCompleted = ?, completedAt = ?, updatedAt = ?
            WHERE id = ?
          `).bind(
            achievement.progress,
            achievement.isCompleted ? 1 : 0,
            achievement.completedAt || null,
            new Date().toISOString(),
            existingAchievement.id
          ).run();
          
          syncedAchievements.push({ ...existingAchievement, ...achievement });
        } else {
          syncedAchievements.push(existingAchievement);
        }
      } else {
        // Insert new achievement
        const newAchievement: UserAchievement = {
          ...achievement,
          id: crypto.randomUUID(),
          userId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        
        await db.prepare(`
          INSERT INTO user_achievements (id, userId, achievementId, progress, 
                                       isCompleted, completedAt, createdAt, updatedAt)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          newAchievement.id,
          newAchievement.userId,
          newAchievement.achievementId,
          newAchievement.progress,
          newAchievement.isCompleted ? 1 : 0,
          newAchievement.completedAt || null,
          newAchievement.createdAt,
          newAchievement.updatedAt
        ).run();
        
        syncedAchievements.push(newAchievement);
      }
    }
    
    // Get all server achievements for this user
    const serverAchievements = await db.prepare(
      'SELECT * FROM user_achievements WHERE userId = ?'
    ).bind(userId).all<UserAchievement>();
    
    // Include server achievements not in client data
    for (const sa of serverAchievements.results) {
      const exists = syncedAchievements.find(a => a.achievementId === sa.achievementId);
      if (!exists) {
        syncedAchievements.push(sa);
      }
    }
    
    return syncedAchievements;
  }

  private async updateUserStats(userId: string): Promise<User> {
    const db = this.env.DB;
    
    // Calculate total XP from progress
    const xpResult = await db.prepare(`
      SELECT SUM(earnedXP) as totalXP FROM progress WHERE userId = ?
    `).bind(userId).first<{ totalXP: number }>();
    
    const totalXP = xpResult?.totalXP || 0;
    const currentLevel = Math.max(1, Math.floor(totalXP / 100) + 1);
    
    // Update user
    const now = new Date().toISOString();
    await db.prepare(`
      UPDATE users 
      SET totalXP = ?, currentLevel = ?, updatedAt = ?
      WHERE id = ?
    `).bind(totalXP, currentLevel, now, userId).run();
    
    // Return updated user
    const user = await db.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(userId).first<User>();
    
    if (!user) {
      throw new Error('User not found after update');
    }
    
    // Helper function to ensure proper ISO8601 formatting
    const formatDate = (dateStr: string) => {
      if (!dateStr) return dateStr;
      const date = new Date(dateStr);
      if (isNaN(date.getTime())) {
        // If date is invalid, try adding UTC timezone
        const dateWithZ = dateStr.endsWith('Z') ? dateStr : dateStr + 'Z';
        const newDate = new Date(dateWithZ);
        return isNaN(newDate.getTime()) ? dateStr : newDate.toISOString();
      }
      return date.toISOString();
    };
    
    user.createdAt = formatDate(user.createdAt);
    user.updatedAt = formatDate(user.updatedAt);
    if (user.lastActiveDate) {
      user.lastActiveDate = formatDate(user.lastActiveDate);
    }
    
    return user;
  }
}