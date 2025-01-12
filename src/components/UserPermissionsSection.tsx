import React from 'react';
import { Switch } from './ui/Switch';
import { updateUserPermissions } from '../lib/permissions';

interface UserPermissionsSectionProps {
  users: Array<{
    user_id: string;
    email: string;
    full_name: string;
    role: 'admin' | 'user';
    can_view_all_tasks: boolean;
  }>;
  onUpdate: () => void;
}

export function UserPermissionsSection({ users, onUpdate }: UserPermissionsSectionProps) {
  const handleRoleChange = async (userId: string, newRole: 'admin' | 'user') => {
    await updateUserPermissions(userId, { role: newRole });
    onUpdate();
  };

  const handleViewPermissionChange = async (userId: string, canViewAll: boolean) => {
    await updateUserPermissions(userId, { can_view_all_tasks: canViewAll });
    onUpdate();
  };

  return (
    <div className="space-y-6">
      <h3 className="text-lg font-semibold text-gray-900">User Permissions</h3>
      
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
                <span className="text-sm text-gray-600">Can view all tasks</span>
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