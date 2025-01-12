import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Timer, Settings } from 'lucide-react';
import { AccountSettingsDialog } from './AccountSettingsDialog';
import { getUserSettings } from '../lib/user';

interface HeaderProps {
  onAuthClick: (mode: 'login' | 'signup') => void;
}

export function Header({ onAuthClick }: HeaderProps) {
  const { user, logout } = useAuth();
  const [showSettings, setShowSettings] = useState(false);
  const [companyName, setCompanyName] = useState<string | null>(null);
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');

  useEffect(() => {
    const fetchCompanyName = async () => {
      if (!user) return;

      try {
        const settings = await getUserSettings();
        if (settings?.company_name) {
          setCompanyName(settings.company_name);
        } else {
          // Fallback to user metadata or default
          setCompanyName(user.user_metadata?.company_name || 'My Company');
        }
      } catch (error) {
        console.error('Failed to fetch company name:', error);
        // Fallback to user metadata or default on error
        setCompanyName(user.user_metadata?.company_name || 'My Company');
      }
    };

    fetchCompanyName();
  }, [user]);

  return (
    <header className="bg-white shadow">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <a 
              href="/"
              onClick={(e) => e.preventDefault()}
              className="flex items-center gap-2 hover:opacity-80 transition-opacity"
            >
              <Timer className="w-6 h-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">DoneTasker.com</h1>
            </a>
          </div>
          
          <div className="flex items-center">
            {user ? (
              <div className="flex items-center">
                <span className="text-gray-700 px-4 flex items-center gap-2 min-w-[120px]">
                  {companyName === null ? (
                    <div className="w-20 h-4 bg-gray-100 animate-pulse rounded"></div>
                  ) : (
                    companyName || 'My Company'
                  )}
                  <button
                    onClick={() => window.location.reload()}
                    className="p-1.5 hover:bg-gray-100 rounded-full transition-colors"
                    title="Refresh app"
                  >
                    <svg
                      className="w-4 h-4 text-gray-500 hover:text-gray-700"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                      />
                    </svg>
                  </button>
                </span>
                <div className="flex items-center gap-2 pl-4 border-l border-gray-200">
                  <div className="relative group">
                    <button
                      onClick={() => setShowSettings(true)}
                      className="p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors"
                      aria-label="Settings"
                    >
                      <Settings className="w-5 h-5" />
                    </button>
                    <div className="absolute left-1/2 -translate-x-1/2 top-full mt-1 hidden group-hover:block">
                      <div className="bg-gray-800 text-white text-xs rounded px-2 py-1 whitespace-nowrap">
                        Settings
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-3">
                <button
                  onClick={() => onAuthClick('login')}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
                >
                  Sign In
                </button>
                <button
                  onClick={() => onAuthClick('signup')}
                  data-action="signup"
                  className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
                >
                  Sign Up
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {showSettings && <AccountSettingsDialog onClose={() => setShowSettings(false)} />}
    </header>
  );
}