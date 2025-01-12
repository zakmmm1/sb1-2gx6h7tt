import React from 'react';
import { getCompanyUsers } from '../lib/permissions';

interface TaskUserSelectProps {
  selectedUsers: string[];
  onChange: (userIds: string[]) => void;
  disabled?: boolean;
}

export function TaskUserSelect({ selectedUsers, onChange, disabled = false }: TaskUserSelectProps) {
  const [users, setUsers] = React.useState<Array<{
    user_id: string;
    email: string;
    full_name: string;
  }>>([]);

  React.useEffect(() => {
    const loadUsers = async () => {
      try {
        const companyUsers = await getCompanyUsers();
        setUsers(companyUsers);
      } catch (error) {
        console.error('Failed to load users:', error);
      }
    };
    loadUsers();
  }, []);

  const handleUserToggle = (userId: string) => {
    const newUsers = selectedUsers.includes(userId)
      ? selectedUsers.filter(id => id !== userId)
      : [...selectedUsers, userId];
    onChange(newUsers);
  };

  return (
    <div className="space-y-2">
      {users.map((user) => (
        <label
          key={user.user_id}
          className={`
            flex items-center gap-2 p-2 rounded-md hover:bg-gray-50
            ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
          `}
        >
          <input
            type="checkbox"
            checked={selectedUsers.includes(user.user_id)}
            onChange={() => !disabled && handleUserToggle(user.user_id)}
            disabled={disabled}
            className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <div>
            <div className="font-medium text-gray-900">{user.full_name}</div>
            <div className="text-sm text-gray-500">{user.email}</div>
          </div>
        </label>
      ))}
    </div>
  );
}