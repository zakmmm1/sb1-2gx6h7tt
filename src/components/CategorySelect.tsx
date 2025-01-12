import React from 'react';
import { Category } from '../types';

interface CategorySelectProps {
  categories: Category[];
  selectedId?: string;
  optional?: boolean;
  disabled?: boolean;
  onChange: (categoryId: string) => void;
}

export function CategorySelect({ categories, selectedId, onChange, optional = false, disabled = false }: CategorySelectProps) {
  return (
    <select
      value={selectedId || ''}
      onChange={(e) => onChange(e.target.value)}
      className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm ${
        disabled 
          ? 'bg-gray-50 text-gray-700 cursor-default'
          : 'focus:border-blue-500 focus:ring-blue-500'
      }`}
      disabled={disabled}
    >
      <option value="">{optional ? 'Optional - No Category' : 'No Category'}</option>
      {categories.map((category) => (
        <option 
          key={category.id} 
          value={category.id}
          className="py-2"
          style={{ 
            backgroundColor: `${category.color}10`,
            color: category.color
          }}
        >
          {category.name}
        </option>
      ))}
    </select>
  );
}