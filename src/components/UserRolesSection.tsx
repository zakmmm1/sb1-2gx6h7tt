import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import { Switch } from './ui/Switch';
import { updateUserRole } from '../lib/roles';
import { AddUserForm } from './AddUserForm';

interface UserRolesSectionProps {
  users: Array<{
    user_id: string;
    email: string;
    full_name: string;
    role: 'admin' | 'user';
    can_view_all_tasks: boolean;
  }>;
  onUpdate: () => void;
}

export function UserRolesSection({ users, onUpdate }: UserRolesSectionProps) {
  const [showAddUser, setShowAddUser] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const handleRoleChange = async (userId: string, newRole: 'admin' | 'user') => {
    setIsLoading(true);
    try {
      if (!userId) {
        console.error('No user ID provided');
        return;
      }

      await updateUserRole(userId, { 
        role: newRole,
        // When changing to admin, always set can_view_all_tasks to true
        can_view_all_tasks: newRole === 'admin' ? true : undefined
      });
      onUpdate();
    } catch (error) {
      console.error('Failed to update role:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleViewPermissionChange = async (userId: string, canViewAll: boolean) => {
    setIsLoading(true);
    try {
      if (!userId) {
        console.error('No user ID provided');
        return;
      }

      await updateUserRole(userId, { can_view_all_tasks: canViewAll });
      onUpdate();
    } catch (error) {
      console.error('Failed to update permissions:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h3 className="text-lg font-semibold text-gray-900">User Roles & Permissions</h3>
        <button
          onClick={() => setShowAddUser(true)}
          className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-500"
        >
          <Plus className="w-4 h-4" />
          Add User
        </button>
      </div>

      {showAddUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">Add New User</h2>
              <button
                onClick={() => setShowAddUser(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                ×
              </button>
            </div>
            <AddUserForm
              onSuccess={() => {
                setShowAddUser(false);
                onUpdate();
              }}
            />
          </div>
        </div>
      )}
      
      <div className="space-y-4">
        {users.map((user) => (
          <div
            key={user.user_id}
            className="bg-white p-4 rounded-lg border shadow-sm space-y-3"
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-medium text-gray-900">{user.full_name}</h4>
                <p className="text-sm text-gray-500">{user.email}</p>
              </div>
              <select
                value={user.role}
                onChange={(e) => handleRoleChange(user.user_id, e.target.value as 'admin' | 'user')}
                className="rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </select>
            </div>

            {user.role === 'user' && (
              <div className="flex items-center justify-between pt-2 border-t">
                <div>
                  <p className="text-sm font-medium text-gray-900">View All Tasks</p>
                  <p className="text-xs text-gray-500">Allow user to see all company tasks</p>
                </div>
                <Switch
                  checked={user.can_view_all_tasks}
                  onCheckedChange={(checked) => handleViewPermissionChange(user.user_id, checked)}
                />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}