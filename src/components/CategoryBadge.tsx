import React from 'react';
import { Category } from '../types';

interface CategoryBadgeProps {
  category?: Category;
}

export const CategoryBadge: React.FC<CategoryBadgeProps> = ({ category }) => {
  if (!category) return null;

  return (
    <span 
      className="px-2 py-1 rounded-full text-xs font-medium"
      style={{ 
        backgroundColor: `${category.color}20`,
        color: category.color 
      }}
    >
      {category.name}
    </span>
  );
};