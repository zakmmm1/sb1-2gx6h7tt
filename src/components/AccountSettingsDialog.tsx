import React, { useState, useEffect } from 'react';
import { X, Save, User, Mail, Edit2, CreditCard, Building2, Plus, LogOut } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { updateUserSettings, getUserSettings } from '../lib/user';
import { fetchCategories } from '../lib/categories'; 
import { getCompanyUsers } from '../lib/roles';
import { Category } from '../types';
import { EditCategoryDialog } from './EditCategoryDialog';
import { NewCategoryDialog } from './NewCategoryDialog';
import { UserRolesSection } from './UserRolesSection';

export function AccountSettingsDialog({ 
  onClose,
  initialTab = 'profile'
}: {
  onClose: () => void;
  initialTab?: 'profile' | 'categories' | 'company' | 'billing';
}) {
  const { user, updateProfile, updateEmail, updatePassword, logout } = useAuth();
  const [isAdmin, setIsAdmin] = useState(false);
  const [timezone, setTimezone] = useState<string>(Intl.DateTimeFormat().resolvedOptions().timeZone);
  const [availableTimezones] = useState(() => {
    const allTimezones = Intl.supportedValuesOf('timeZone');
    // Get timezone information
    const getTimezoneInfo = (tz: string) => {
      try {
        const date = new Date();
        // Get UTC offset in minutes
        const utcDate = new Date(date.toLocaleString('en-US', { timeZone: 'UTC' }));
        const tzDate = new Date(date.toLocaleString('en-US', { timeZone: tz }));
        const offset = (tzDate.getTime() - utcDate.getTime()) / 1000 / 60;
        
        // Format offset string
        const absOffset = Math.abs(offset);
        const hours = Math.floor(absOffset / 60);
        const minutes = Math.floor(absOffset % 60);
        const sign = offset >= 0 ? '+' : '-';
        const offsetStr = `${sign}${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;

        // Get location parts
        const [region, ...locationParts] = tz.split('/');
        const location = locationParts.join('/').replace(/_/g, ' ');

        // Get abbreviation
        const abbreviation = new Intl.DateTimeFormat('en-US', {
          timeZone: tz,
          timeZoneName: 'short'
        }).formatToParts(date).find(part => part.type === 'timeZoneName')?.value || '';

        return {
          timezone: tz,
          offset,
          offsetStr,
          region,
          location,
          abbreviation
        };
      } catch (e) {
        return {
          timezone: tz,
          offset: 0,
          offsetStr: '+00:00',
          region: '',
          location: tz,
          abbreviation: ''
        };
      }
    };

    // Get and sort timezone information
    const timezoneInfo = allTimezones.map(getTimezoneInfo).sort((a, b) => {
      // Sort by offset first
      if (a.offset !== b.offset) {
        return a.offset - b.offset;
      }
      // Then by region
      if (a.region !== b.region) {
        return a.region.localeCompare(b.region);
      }
      // Finally by location
      return a.location.localeCompare(b.location);
    });

    return timezoneInfo;
  });
  const [categories, setCategories] = useState<Category[]>([]); 
  const [users, setUsers] = useState<Array<{
    user_id: string;
    email: string;
    full_name: string;
    role: 'admin' | 'user';
    can_view_all_tasks: boolean;
  }>>([]);
  const [showNewCategoryDialog, setShowNewCategoryDialog] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  
  // Profile editing states
  const [fullName, setFullName] = useState(user?.user_metadata?.full_name || '');
  const [email, setEmail] = useState(user?.email || '');
  const [error, setError] = useState('');

  useEffect(() => {
    const loadData = async () => {
      if (user) {
        const [settings, categoriesData] = await Promise.all([
          getUserSettings(),
          fetchCategories()
        ]);
        // For now, everyone is admin of their own account
        setIsAdmin(true);

        if (settings) {
          setTimezone(settings.timezone || timezone);
        }
        setCategories(categoriesData.sort((a, b) => a.name.localeCompare(b.name)));
      }
    };
    loadData();
  }, [user]);

  const handleSave = async () => {
    try {
      setError('');
      let needsReload = false;
      
      // Update profile if name changed
      if (fullName !== user?.user_metadata?.full_name) {
        await updateProfile({ full_name: fullName });
        needsReload = true;
      }
      
      // Update email if changed
      if (email !== user?.email) {
        await updateEmail(email);
        needsReload = true;
      }

      // Update company settings
      await updateUserSettings({ 
        timezone 
      });
      needsReload = true;
      
      onClose();
      if (needsReload) {
        window.location.reload();
      }
    } catch (error) {
      setError((error as Error).message);
    }
  };

  const handlePasswordReset = async () => {
    try {
      setError('');
      await updatePassword();
      alert('Check your email for the password reset link');
      onClose();
    } catch (error) {
      setError((error as Error).message);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
      <div className="relative min-h-screen flex items-center justify-center p-4">
        <div className="relative bg-white rounded-lg shadow-xl w-full max-w-2xl">
          <div className="flex justify-between items-center p-6 border-b">
            <h2 className="text-xl font-bold text-gray-900">Account Settings</h2>
            <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div className="p-6 space-y-8">
            {/* Categories Section */}
            <div>
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Task Categories</h3>
                <button
                  onClick={() => setShowNewCategoryDialog(true)}
                  className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-500"
                >
                  <Plus className="w-4 h-4" />
                  Add Category
                </button>
              </div>
              
              <div className="space-y-2">
                {categories.map((category) => (
                  <div 
                    key={category.id}
                    className="flex items-center justify-between p-3 rounded-md"
                    style={{ 
                      backgroundColor: `${category.color}10`,
                      borderColor: `${category.color}40`,
                      border: '1px solid'
                    }}
                  >
                    <div className="flex items-center gap-3">
                      <div 
                        className="w-4 h-4 rounded-full" 
                        style={{ backgroundColor: category.color }}
                      />
                      <span className="font-medium" style={{ color: category.color }}>
                        {category.name}
                      </span>
                    </div>
                    <button
                      onClick={() => setEditingCategory(category)}
                      className="p-1 hover:bg-white/50 rounded-full transition-colors"
                    >
                      <Edit2 className="w-4 h-4" style={{ color: category.color }} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Profile Settings */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Profile Settings</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Full Name</label>
                  <div className="mt-1 relative flex items-center">
                    <div className="absolute left-3 pointer-events-none">
                      <User className="w-5 h-5 text-gray-400" />
                    </div>
                    <input
                      type="text"
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="pl-10 w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Email</label>
                  <div className="mt-1 relative flex items-center">
                    <div className="absolute left-3 pointer-events-none">
                      <Mail className="w-5 h-5 text-gray-400" />
                    </div>
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pl-10 w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="border-t pt-4">
                  <button
                    onClick={handlePasswordReset}
                    className="text-blue-600 hover:text-blue-500 text-sm font-medium flex items-center gap-1"
                  >
                    Forgot Password?
                  </button>
                </div>
              </div>
            </div>

            {/* Timezone Settings */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Timezone Settings</h3>
              <div>
                <label className="block text-sm font-medium text-gray-700">Timezone</label>
                <select
                  value={timezone || Intl.DateTimeFormat().resolvedOptions().timeZone}
                  onChange={(e) => setTimezone(e.target.value)}
                  className="mt-1 block w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  {availableTimezones.map((tz) => {
                    const abbr = tz.abbreviation ? ` (${tz.abbreviation})` : '';
                    const location = tz.location.split('/').pop() || tz.timezone;
                    return (
                      <option key={tz.timezone} value={tz.timezone}>
                        {`(UTC${tz.offsetStr}) ${tz.region} - ${location}${abbr}`}
                      </option>
                    );
                  })}
                </select>
              </div>
            </div>

            {/* User Management Section */}
            {isAdmin && (
              <div>
                <h3 className="flex items-center gap-2 text-lg font-semibold text-gray-900 mb-4">
                  User Management
                  <span className="text-xs font-normal text-green-600">(admin only)</span>
                </h3>
                <div className="space-y-4">
                  <UserRolesSection 
                    users={users} 
                    onUpdate={async () => {
                      const updatedUsers = await getCompanyUsers();
                      setUsers(updatedUsers);
                    }}
                  />
                </div>
              </div>
            )}

            {/* Billing Section */}
            {isAdmin && <div>
              <h3 className="flex items-center gap-2 text-lg font-semibold text-gray-500 mb-4">
                Billing
                <span className="text-xs font-normal text-green-600">(admin only)</span>
                <span className="text-xs font-medium bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full">Coming Soon</span>
              </h3>
              <div className="bg-gray-50 rounded-lg p-6 opacity-60 cursor-not-allowed">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <CreditCard className="w-5 h-5 text-gray-500" />
                    <div>
                      <p className="font-medium text-gray-900">Manage Subscription</p>
                      <p className="text-sm text-gray-500">Update your payment method and billing preferences</p>
                    </div>
                  </div>
                  <button
                    disabled
                    className="px-4 py-2 bg-gray-200 border border-gray-300 rounded-md text-sm font-medium text-gray-500 cursor-not-allowed"
                  >
                    Manage Billing
                  </button>
                </div>
                <div className="mt-6 border-t pt-6">
                  <p className="text-sm text-gray-500 italic text-center">
                    Billing management is coming soon!
                  </p>
                </div>
              </div>
            </div>}

            {error && (
              <div className="text-red-600 text-sm">{error}</div>
            )}
            
            <div className="border-t pt-6 space-y-4">
              <div className="flex justify-end gap-3">
                <button
                  onClick={onClose}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700"
                >
                  <Save className="w-4 h-4" />
                  Save Changes
                </button>
              </div>
              
              <div className="border-t pt-4">
                <button
                  onClick={() => {
                    logout();
                    onClose();
                  }}
                  className="flex items-center gap-2 w-full px-4 py-3 text-red-600 hover:bg-red-50 rounded-md transition-colors"
                >
                  <LogOut className="w-5 h-5" />
                  <span className="font-medium">Sign Out</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {showNewCategoryDialog && (
        <NewCategoryDialog 
          onClose={() => setShowNewCategoryDialog(false)}
          onSuccess={() => {
            setShowNewCategoryDialog(false);
            window.location.reload();
          }}
        />
      )}

      {editingCategory && (
        <EditCategoryDialog
          category={editingCategory}
          onClose={() => setEditingCategory(null)}
        />
      )}
    </div>
  );
}