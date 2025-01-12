import React, { useState, useEffect } from 'react';
import { Users } from 'lucide-react';
import { getCompanyUsers } from '../lib/roles';
import { updateTaskCollaborators } from '../lib/roles';

interface TaskCollaboratorsProps {
  taskId: string;
  collaborators: string[];
  disabled?: boolean;
  onUpdate?: () => void;
}

export function TaskCollaborators({ 
  taskId, 
  collaborators, 
  disabled = false,
  onUpdate 
}: TaskCollaboratorsProps) {
  const [users, setUsers] = useState<Array<{
    user_id: string;
    email: string;
    full_name: string;
  }>>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
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

  const handleUserToggle = async (userId: string) => {
    if (disabled) return;

    const newCollaborators = collaborators.includes(userId)
      ? collaborators.filter(id => id !== userId)
      : [...collaborators, userId];

    try {
      await updateTaskCollaborators(taskId, newCollaborators);
      onUpdate?.();
    } catch (error) {
      console.error('Failed to update collaborators:', error);
    }
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        disabled={disabled}
        className={`
          flex items-center gap-2 px-3 py-1.5 rounded-md text-sm
          ${disabled 
            ? 'bg-gray-100 text-gray-500 cursor-not-allowed'
            : 'bg-blue-50 text-blue-600 hover:bg-blue-100'
          }
        `}
      >
        <Users className="w-4 h-4" />
        <span>Collaborators ({collaborators.length})</span>
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 mt-2 w-64 bg-white rounded-lg shadow-lg border p-2 z-10">
          <div className="max-h-64 overflow-y-auto">
            {users.map((user) => (
              <label
                key={user.user_id}
                className="flex items-center gap-2 p-2 hover:bg-gray-50 rounded cursor-pointer"
              >
                <input
                  type="checkbox"
                  checked={collaborators.includes(user.user_id)}
                  onChange={() => handleUserToggle(user.user_id)}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <div>
                  <div className="text-sm font-medium text-gray-900">{user.full_name}</div>
                  <div className="text-xs text-gray-500">{user.email}</div>
                </div>
              </label>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}