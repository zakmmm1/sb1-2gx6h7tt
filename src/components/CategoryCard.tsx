import React, { useState } from 'react';
import { Eye, EyeOff, Edit2, Plus, GripVertical } from 'lucide-react';
import { Category } from '../types';
import { EditCategoryDialog } from './EditCategoryDialog';
import { NewRequestDialog } from './NewRequestDialog';

interface CategoryCardProps {
  category: Category;
  onFilter: (categoryId: string | null) => void;
  isFiltered: boolean;
  onNewTask?: (data: Omit<ServiceRequest, 'id' | 'createdAt'>) => Promise<void>;
}

export const CategoryCard: React.FC<CategoryCardProps> = ({ 
  category, 
  onFilter,
  isFiltered,
  onNewTask
}) => {
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showNewTaskDialog, setShowNewTaskDialog] = useState(false);

  return (
    <>
      <div
        className="p-3 rounded-lg border transition-colors text-left relative group"
        style={{ 
          borderColor: `${category.color}40`,
          backgroundColor: `${category.color}10`
        }}
      >
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <h3 
              className="font-medium text-sm"
              style={{ color: category.color }}
            >
              {category.name}
            </h3>
          </div>
          <div className="flex gap-1">
            <button
              onClick={() => onFilter(isFiltered ? null : category.id)}
              className="p-1 rounded-full hover:bg-white/50 transition-colors"
              title={isFiltered ? "Show all tasks" : "Filter by category"}
            >
              {isFiltered ? (
                <EyeOff className="w-3.5 h-3.5" style={{ color: category.color }} />
              ) : (
                <Eye className="w-3.5 h-3.5" style={{ color: category.color }} />
              )}
            </button>
            <button
              onClick={() => setShowEditDialog(true)}
              className="p-1 rounded-full hover:bg-white/50 transition-colors"
              title="Edit category"
            >
              <Edit2 className="w-3.5 h-3.5" style={{ color: category.color }} />
            </button>
            <button
              onClick={() => setShowNewTaskDialog(true)}
              className="p-1 rounded-full hover:bg-white/50 transition-colors"
              title="Add new task"
            >
              <Plus className="w-3.5 h-3.5" style={{ color: category.color }} />
            </button>
          </div>
        </div>
      </div>

      {showEditDialog && (
        <EditCategoryDialog
          category={category}
          onClose={() => setShowEditDialog(false)}
        />
      )}

      {showNewTaskDialog && (
        <NewRequestDialog
          onClose={() => setShowNewTaskDialog(false)}
          onSubmit={async (data: Omit<ServiceRequest, 'id' | 'createdAt'>) => {
            if (onNewTask) {
              await onNewTask(data);
            }
            setShowNewTaskDialog(false);
          }}
          initialCategory={category}
        />
      )}
    </>
  );
};