import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { Category } from '../types';
import { CategoryCard } from './CategoryCard';
import { NewCategoryDialog } from './NewCategoryDialog';

interface CategoryGridProps {
  categories: Category[];
  onFilter: (categoryId: string | null) => void;
  filteredCategoryId: string | null;
  onNewTask?: (data: Omit<ServiceRequest, 'id' | 'createdAt'>) => Promise<void>;
}

export function CategoryGrid({ 
  categories, 
  onFilter,
  filteredCategoryId,
  onNewTask
}: CategoryGridProps) {
  const [showNewCategoryDialog, setShowNewCategoryDialog] = useState(false);
  
  // Sort categories by name
  const sortedCategories = [...categories].sort((a, b) => a.name.localeCompare(b.name));

  return (
    <div className="mb-8">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-semibold text-gray-900">Categories</h2>
        <button
          onClick={() => setShowNewCategoryDialog(true)}
          className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-500"
        >
          <Plus className="w-4 h-4" />
          Add Category
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {sortedCategories.map((category) => (
          <div
            key={category.id}
            className="transition-colors duration-200"
          >
            <CategoryCard
              category={category}
              onFilter={onFilter}
              isFiltered={filteredCategoryId === category.id}
              onNewTask={onNewTask}
            />
          </div>
        ))}
      </div>

      {showNewCategoryDialog && (
        <NewCategoryDialog 
          onClose={() => setShowNewCategoryDialog(false)}
          onSuccess={() => setShowNewCategoryDialog(false)}
        />
      )}
    </div>
  );
}