import React from 'react';
import { ServiceRequest } from '../types';

interface PriorityBadgeProps {
  priority: ServiceRequest['priority'];
}

export const PriorityBadge: React.FC<PriorityBadgeProps> = ({ priority }) => {
  const getPriorityColor = (priority: ServiceRequest['priority']) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(priority)}`}>
      {priority}
    </span>
  );
};