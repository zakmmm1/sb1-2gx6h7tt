export interface User {
  id: string;
  email: string;
  full_name?: string;
  avatar_url?: string;
  created_at: Date;
  last_login?: Date;
}

export interface AuthState {
  user: User | null;
  loading: boolean;
  error: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface SignUpCredentials extends LoginCredentials {
  full_name: string;
}