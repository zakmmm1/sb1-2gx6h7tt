import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { LoginForm } from './LoginForm';
import { SignUpForm } from './SignUpForm';
import { useAuth } from '../../contexts/AuthContext';

interface AuthModalProps {
  onClose: () => void;
  initialMode?: 'login' | 'signup';
}

export function AuthModal({ onClose, initialMode = 'login' }: AuthModalProps) {
  const [isLogin, setIsLogin] = useState(initialMode === 'login');
  const { user } = useAuth();

  // Close modal when user is authenticated
  useEffect(() => {
    if (user) {
      onClose();
    }
  }, [user, onClose]);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">{isLogin ? 'Sign In' : 'Create Account'}</h2>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded-full">
            <X className="w-5 h-5" />
          </button>
        </div>

        {isLogin ? <LoginForm /> : <SignUpForm />}

        <div className="mt-4 text-center">
          <button
            data-action="switch-to-signup"
            onClick={() => setIsLogin(!isLogin)}
            className="text-sm text-blue-600 hover:text-blue-500"
          >
            {isLogin ? "Don't have an account? Sign up" : 'Already have an account? Sign in'}
          </button>
        </div>
      </div>
    </div>
  );
}