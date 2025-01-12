import React from 'react';
import { CheckCircle, Circle } from 'lucide-react';
import { Subtask } from '../types';

interface SubtaskListProps {
  subtasks: Subtask[];
  onStatusChange: (subtaskId: string, status: Subtask['status']) => void;
}

export const SubtaskList: React.FC<SubtaskListProps> = ({ subtasks, onStatusChange }) => {
  return (
    <div className="space-y-2">
      {subtasks.map((subtask) => (
        <div 
          key={subtask.id}
          className="flex items-center gap-2 p-2 hover:bg-gray-50 rounded-md"
        >
          <button
            onClick={() => onStatusChange(
              subtask.id, 
              subtask.status === 'completed' ? 'new' : 'completed'
            )}
            className="text-gray-400 hover:text-green-500"
          >
            {subtask.status === 'completed' ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <Circle className="w-5 h-5" />
            )}
          </button>
          <span className={subtask.status === 'completed' ? 'line-through text-gray-500' : ''}>
            {subtask.title}
          </span>
        </div>
      ))}
    </div>
  );
};