import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, AuthState } from '../types/auth';
import { supabase } from '../lib/supabase';

interface AuthContextType extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  signUp: (data: {
    email: string;
    password: string;
    fullName: string;
    companyName: string;
    timezone: string;
    phoneNumber: string;
  }) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (data: { full_name: string }) => Promise<void>;
  updateEmail: (email: string) => Promise<void>;
  updatePassword: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    const initializeAuth = async () => {
      try {
        // Get current session
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError) {
          // If there's an error getting the session, clear the state
          setState(prev => ({ 
            ...prev, 
            user: null,
            loading: false 
          }));
          return;
        }

        if (session) {
          setState(prev => ({
            ...prev,
            user: session.user as User,
            loading: false,
          }));
        } else {
          setState(prev => ({ 
            ...prev, 
            user: null,
            loading: false 
          }));
        }

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
          if (event === 'TOKEN_REFRESHED') {
            // Successfully refreshed token
            setState(prev => ({
              ...prev,
              user: session?.user as User || null,
              loading: false,
            }));
          } else if (event === 'SIGNED_OUT' || event === 'USER_DELETED') {
            // Clear state on sign out or user deletion
            setState(prev => ({
              ...prev,
              user: null,
              loading: false,
            }));
          } else {
            // Handle other auth state changes
            setState(prev => ({
              ...prev,
              user: session?.user as User || null,
              loading: false,
            }));
          }
        });

        return () => {
          subscription.unsubscribe();
        };
      } catch (error) {
        console.error('Auth initialization error:', error);
        setState(prev => ({ 
          ...prev, 
          user: null,
          loading: false 
        }));
      }
    };

    initializeAuth();
  }, []);

  const handleAuthError = (error: any) => {
    if (error.message?.includes('refresh_token_not_found')) {
      // Handle invalid refresh token by signing out
      logout();
      setState(prev => ({ 
        ...prev, 
        error: 'Your session has expired. Please sign in again.' 
      }));
    } else {
      setState(prev => ({ 
        ...prev, 
        error: error.message 
      }));
    }
  };

  const login = async (email: string, password: string) => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (error) {
      handleAuthError(error);
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const signUp = async ({
    email,
    password,
    fullName,
    companyName,
    timezone,
    phoneNumber
  }) => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      
      // First create the user account
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { 
            full_name: fullName,
            timezone: timezone,
            phone_number: phoneNumber
          }
        }
      });
      
      if (error) throw error;

      // Get the newly created user's ID
      const { data: { user: newUser } } = await supabase.auth.getUser();
      if (!newUser?.id) throw new Error('Failed to get user ID');

      // Then create initial user settings with company name
      const { error: settingsError } = await supabase
        .from('user_settings')
        .insert([{
          user_id: newUser.id,
          company_name: companyName,
          timezone: timezone
        }]);

      if (settingsError) throw settingsError;

      // Finally create the initial company_users entry
      const { error: companyError } = await supabase
        .from('company_users')
        .insert([{
          user_id: newUser.id,
          company_name: companyName,
          role: 'owner',
          email: email,
          full_name: fullName
        }]);

      if (companyError) throw companyError;

      // Wait a moment for the database to propagate the changes
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (error) {
      setState(prev => ({ 
        ...prev, 
        error: error.message || 'An error occurred during signup'
      }));
      throw error;
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const logout = async () => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      setState(prev => ({ ...prev, user: null }));
    } catch (error) {
      handleAuthError(error);
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const updateProfile = async (data: { full_name: string }) => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.updateUser({
        data: { full_name: data.full_name }
      });
      if (error) throw error;
    } catch (error) {
      handleAuthError(error);
      throw error;
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const updateEmail = async (email: string) => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.updateUser({ email });
      if (error) throw error;
    } catch (error) {
      handleAuthError(error);
      throw error;
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const updatePassword = async () => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      const siteUrl = window.location.origin;
        
      const { error } = await supabase.auth.resetPasswordForEmail(
        state.user?.email || '',
        { 
          redirectTo: `${siteUrl}/reset-password`,
          captchaToken: undefined // Disable captcha for now
        }
      );
      if (error) throw error;
      alert('Check your email for the password reset link');
    } catch (error) {
      handleAuthError(error);
      throw error;
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  return (
    <AuthContext.Provider value={{ 
      ...state, 
      login, 
      signUp, 
      logout,
      updateProfile,
      updateEmail,
      updatePassword
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};