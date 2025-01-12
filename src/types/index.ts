import { User, AuthState, LoginCredentials, SignUpCredentials } from './auth';

export interface Category {
  id: string;
  name: string;
  color: string;
  created_at: Date;
  order?: number;
  user_id?: string;
}

export interface ServiceRequest {
  id: string;
  title: string;
  description?: string;
  assignee_id?: string;
  createdAt: Date;
  completedAt?: Date;
  category_id?: string;
  category?: Category;
  notes?: string;
  order?: number;
}

export interface Subtask {
  id: string;
  title: string;
  description: string;
  status: 'new' | 'in-progress' | 'completed';
  task_id: string;
  created_at: Date;
  completed_at?: Date;
}

export interface Comment {
  id: string;
  content: string;
  task_id: string;
  user_id: string;
  created_at: Date;
}

export interface WorkSession {
  id: string;
  task_id: string;
  start_time: Date;
  end_time?: Date;
  user_id: string;
}

export type TimeRange = '24h' | '7d' | '30d' | 'all';

export { User, AuthState, LoginCredentials, SignUpCredentials };