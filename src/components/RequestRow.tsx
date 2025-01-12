import React, { useState, useRef, useEffect } from 'react';
import { MoreVertical, CheckCircle, ChevronDown, ChevronUp, Trash2, Square } from 'lucide-react';
import confetti from 'canvas-confetti';
import { ServiceRequest } from '../types';
import { TimeTracker } from './TimeTracker';
import { CategoryBadge } from './CategoryBadge';
import { TaskDetails } from './TaskDetails';
import { deleteTask } from '../lib/tasks';

interface RequestRowProps {
  request: ServiceRequest;
  position: number;
  archived?: boolean;
  onComplete?: (id: string) => void;
  selected?: boolean;
  onSelect?: (id: string) => void;
}
import { formatInTimezone } from '../utils/timeUtils';
import { useAuth } from '../contexts/AuthContext';
import { getUserSettings } from '../lib/user';

export function RequestRow({ 
  request, 
  position,
  archived = false,
  onComplete,
  selected = false,
  onSelect
}: RequestRowProps) {
  const { user } = useAuth();
  const [isExpanded, setIsExpanded] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [userTimezone, setUserTimezone] = useState<string>();
  const menuRef = useRef<HTMLDivElement>(null);
  const completeButtonRef = useRef<HTMLButtonElement>(null);
  const isCompleted = !!request.completedAt;
  
  useEffect(() => {
    const loadTimezone = async () => {
      if (user) {
        const settings = await getUserSettings();
        setUserTimezone(settings?.timezone);
      }
    };
    loadTimezone();
  }, [user]);
  const triggerConfetti = () => {
    const colors = ['#2563eb', '#16a34a', '#dc2626', '#9333ea', '#ea580c'];

    // Create a burst from multiple points
    const burst = (x: number) => {
      return confetti({
        particleCount: 15,
        startVelocity: 45,
        spread: 90,
        origin: { x, y: 0.5 },
        colors,
        ticks: 200,
        gravity: 1.2,
        scalar: 0.8,
        drift: 0.1
      });
    };

    // Fire multiple bursts across the screen
    burst(0.25);
    burst(0.5);
    burst(0.75);
  };

  const handleComplete = async () => {
    if (onComplete) {
      triggerConfetti();
      await onComplete(request.id);
    }
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setShowMenu(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this task?')) {
      try {
        await deleteTask(request.id);
        window.location.reload();
      } catch (error) {
        console.error('Failed to delete task:', error);
      }
    }
    setShowMenu(false);
  };

  return (
    <div className="border-b last:border-b-0">
      <div className="grid grid-cols-12 gap-4 items-center p-3 hover:bg-gray-50">
        {onSelect && (
          <div className="col-span-1">
            <button
              onClick={() => onSelect(request.id)}
              className="p-1 hover:bg-gray-100 rounded flex items-center justify-center"
            >
              <div className={`w-4 h-4 rounded border transition-colors ${
                selected 
                  ? 'bg-blue-600 border-blue-600' 
                  : 'border-gray-400'
              }`}>
                {selected && (
                  <div className="w-full h-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-sm"></div>
                  </div>
                )}
              </div>
            </button>
          </div>
        )}
        <div className={onSelect ? 'col-span-4' : 'col-span-5'}>
          <div className="flex items-center gap-1 sm:gap-2 mb-1">
            <button 
              onClick={() => setIsExpanded(!isExpanded)}
              className="p-0.5 hover:bg-gray-100 rounded-full flex-shrink-0"
            >
              {isExpanded ? (
                <ChevronUp className="w-3 h-3 sm:w-4 sm:h-4 text-gray-500" />
              ) : (
                <ChevronDown className="w-3 h-3 sm:w-4 sm:h-4 text-gray-500" />
              )}
            </button>
            <h3 className="font-medium text-sm sm:text-base text-gray-900 truncate">{request.title}</h3>
            {request.category && <CategoryBadge category={request.category} />}
          </div>
        </div>
        <div className="hidden sm:block text-xs sm:text-sm text-gray-600 col-span-3 min-w-0">
          <p className="truncate" title={request.description || ''}>
            {request.description || <span className="text-gray-400 italic">No description</span>}
          </p>
        </div>
        <div className="col-span-3 sm:col-span-2 min-w-0">
          <TimeTracker 
            createdAt={request.createdAt}
            completedAt={request.completedAt}
          />
        </div>
        <div className="flex items-center justify-end gap-1 sm:gap-2 col-span-4 sm:col-span-2 flex-shrink-0">
          {!archived && !isCompleted && onComplete && (
            <button 
              ref={completeButtonRef}
              onClick={handleComplete}
              className="flex items-center justify-center w-20 h-8 sm:w-auto sm:h-auto sm:px-3 sm:py-1.5 text-xs text-white bg-green-600 hover:bg-green-700 rounded-md flex-shrink-0 whitespace-nowrap"
            >
              <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5" />
              <span className="hidden sm:inline ml-1">Complete</span>
            </button>
          )}
          {isCompleted && (
            <span className="flex items-center gap-1 px-2 py-1 text-xs sm:text-sm text-green-600 bg-green-50 rounded-md">
              <CheckCircle className="w-3 h-3 sm:w-4 sm:h-4" />
              <span className="hidden sm:inline">Completed</span>
            </span>
          )}
          <div className="relative" ref={menuRef}>
            <button 
              onClick={() => setShowMenu(!showMenu)}
              className="p-1 hover:bg-gray-100 rounded-full flex items-center justify-center"
            >
              <MoreVertical className="w-3 h-3 sm:w-4 sm:h-4 text-gray-500" />
            </button>
            {showMenu && (
              <div className="absolute right-0 mt-1 w-36 sm:w-48 bg-white rounded-md shadow-lg z-10 border">
                <div className="py-1">
                  <button
                    onClick={handleDelete}
                    className="flex items-center gap-2 w-full px-3 py-2 text-xs sm:text-sm text-red-600 hover:bg-red-50"
                  >
                    <Trash2 className="w-3 h-3 sm:w-4 sm:h-4" />
                    Delete Task
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      
      {isExpanded && (
        <TaskDetails 
          request={request}
          archived={archived}
        />
      )}
    </div>
  );
}