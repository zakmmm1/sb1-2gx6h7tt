import React, { useState } from 'react';
import { Mail, User, Lock } from 'lucide-react';
import { Switch } from './ui/Switch';
import { addCompanyUser } from '../lib/user';

interface AddUserFormProps {
  onSuccess: () => void;
}

export function AddUserForm({ onSuccess }: AddUserFormProps) {
  const [formData, setFormData] = useState({
    email: '',
    fullName: '',
    password: '',
    role: 'user' as const,
    canViewAllTasks: false
  });
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.email || !formData.fullName || !formData.password) {
      setError('Please fill in all required fields');
      return;
    }

    setIsLoading(true);

    try {
      await addCompanyUser({
        email: formData.email.toLowerCase().trim(),
        full_name: formData.fullName.trim(),
        password: formData.password,
        role: formData.role,
        can_view_all_tasks: formData.canViewAllTasks
      });
      
      onSuccess();
    } catch (error) {
      setError((error as Error).message);
      console.error('Failed to add user:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700">Email</label>
        <div className="mt-1 relative">
          <Mail className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="email"
            required
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            className="pl-10 w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="user@example.com"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Full Name</label>
        <div className="mt-1 relative">
          <User className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="text"
            required
            value={formData.fullName}
            onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
            className="pl-10 w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="John Doe"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Password</label>
        <div className="mt-1 relative">
          <Lock className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="password"
            required
            minLength={8}
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            className="pl-10 w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="Minimum 8 characters"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Role</label>
        <select
          value={formData.role}
          onChange={(e) => setFormData({ 
            ...formData, 
            role: e.target.value as 'admin' | 'user',
            canViewAllTasks: e.target.value === 'admin' ? true : formData.canViewAllTasks
          })}
          className="mt-1 block w-full rounded-md border border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        >
          <option value="user">User</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      {formData.role === 'user' && (
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-900">View All Tasks</p>
            <p className="text-xs text-gray-500">Allow user to see all company tasks</p>
          </div>
          <Switch
            checked={formData.canViewAllTasks}
            onCheckedChange={(checked) => setFormData({ ...formData, canViewAllTasks: checked })}
          />
        </div>
      )}

      {error && (
        <div className="text-sm text-red-600">{error}</div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className={`
          w-full flex justify-center py-2 px-4 border border-transparent rounded-md 
          shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700
          focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 
          disabled:opacity-50 transition-colors
        `}
      >
        {isLoading ? 'Adding User...' : 'Add User'}
      </button>
    </form>
  );
}