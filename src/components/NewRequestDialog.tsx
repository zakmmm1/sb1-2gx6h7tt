import React, { useState, useEffect, useRef } from 'react';
import { X } from 'lucide-react';
import { ServiceRequest, Category } from '../types';
import { CategorySelect } from './CategorySelect';
import { fetchCategories } from '../lib/categories';
import { AccountSettingsDialog } from './AccountSettingsDialog';
import { useAuth } from '../contexts/AuthContext';

interface NewRequestDialogProps {
  onClose: () => void;
  onSubmit: (request: Omit<ServiceRequest, 'id' | 'createdAt'>) => void;
  initialCategory?: Category;
}

export function NewRequestDialog({ onClose, onSubmit, initialCategory }: NewRequestDialogProps) {
  const { user } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [formData, setFormData] = useState({
    title: '',
    description: '' as string | undefined,
    assignee_id: user?.id || '',
    category_id: initialCategory?.id || undefined as string | undefined
  });
  const [showSettings, setShowSettings] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        const categoriesData = await fetchCategories();
        setCategories(categoriesData);
        
        // Set default assignee to current user
        if (user?.id && !formData.assignee_id) {
          setFormData(prev => ({ ...prev, assignee_id: user.id }));
        }
      } catch (error) {
        console.error('Failed to load data:', error);
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    onSubmit(formData);
    onClose();
  };

  if (isLoading) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
        <div className="bg-white rounded-lg p-6">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
      <div className="relative min-h-screen flex items-center justify-center p-4">
        <div className="relative bg-white rounded-lg shadow-xl w-full max-w-2xl">
          <div className="flex justify-between items-center p-6 border-b">
            <h2 className="text-xl font-bold text-gray-900">New Task</h2>
            <button 
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="p-6 space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Task <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Category</label>
              <CategorySelect
                optional
                categories={categories}
                selectedId={formData.category_id}
                onChange={(categoryId) => setFormData({ ...formData, category_id: categoryId || undefined })}
              />
              <button
                type="button"
                onClick={() => setShowSettings(true)}
                className="mt-2 text-sm text-blue-600 hover:text-blue-500"
              >
                Manage categories
              </button>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Description</label>
              <textarea
                placeholder="Optional task description..."
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                rows={5}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value || undefined })}
              />
            </div>

            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700"
              >
                Create Task
              </button>
            </div>
          </form>
        </div>
      </div>
      
      {showSettings && (
        <AccountSettingsDialog 
          onClose={() => setShowSettings(false)}
          initialTab="categories"
        />
      )}
    </div>
  );
}