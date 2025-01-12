import React, { useState } from 'react';
import { ServiceRequest } from '../types';
import { RequestRow } from './RequestRow';
import { ArrowUpDown, ArrowUp, ArrowDown, Trash2, Square } from 'lucide-react';

interface RequestListProps {
  requests: ServiceRequest[];
  archived?: boolean;
  onComplete?: (id: string) => void;
  onBulkDelete?: (ids: string[]) => void;
}

type SortField = 'title' | 'assignee' | 'createdAt' | 'completedAt';
type SortDirection = 'asc' | 'desc';

const ITEMS_PER_PAGE = 10;

export function RequestList({
  requests,
  archived = false,
  onComplete,
  onBulkDelete
}: RequestListProps) {
  const [sortField, setSortField] = useState<SortField>('createdAt');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  const [selectedTasks, setSelectedTasks] = useState<Set<string>>(new Set());
  const [currentPage, setCurrentPage] = useState(0);

  const handleSort = (field: SortField) => {
    if (field === sortField) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const getSortIcon = (field: SortField) => {
    if (field !== sortField) return <ArrowUpDown className="w-3 h-3 sm:w-4 sm:h-4" />;
    return sortDirection === 'asc' ? 
      <ArrowUp className="w-3 h-3 sm:w-4 sm:h-4" /> : 
      <ArrowDown className="w-3 h-3 sm:w-4 sm:h-4" />;
  };

  const sortedRequests = [...requests].sort((a, b) => {
    const direction = sortDirection === 'asc' ? 1 : -1;
    
    switch (sortField) {
      case 'title':
        return direction * a.title.localeCompare(b.title);
      case 'assignee':
        return direction * (a.assignee || '').localeCompare(b.assignee || '');
      case 'createdAt':
        return direction * (a.createdAt.getTime() - b.createdAt.getTime());
      case 'completedAt':
        if (!a.completedAt && !b.completedAt) return 0;
        if (!a.completedAt) return direction;
        if (!b.completedAt) return -direction;
        return direction * (a.completedAt.getTime() - b.completedAt.getTime());
      default:
        return 0;
    }
  });

  const totalPages = Math.ceil(sortedRequests.length / ITEMS_PER_PAGE);
  const startIndex = currentPage * ITEMS_PER_PAGE;
  const paginatedRequests = sortedRequests.slice(startIndex, startIndex + ITEMS_PER_PAGE);

  const handleBulkDelete = (selectedOnly: boolean = false) => {
    if (onBulkDelete) {
      const tasksToDelete = selectedOnly 
        ? Array.from(selectedTasks)
        : paginatedRequests.map(request => request.id);
      
      if (tasksToDelete.length === 0) {
        alert('Please select at least one task to delete');
        return;
      }
      
      onBulkDelete(tasksToDelete);
      setSelectedTasks(new Set());
    }
  };

  const toggleTaskSelection = (taskId: string) => {
    const newSelection = new Set(selectedTasks);
    if (newSelection.has(taskId)) {
      newSelection.delete(taskId);
    } else {
      newSelection.add(taskId);
    }
    setSelectedTasks(newSelection);
  };

  const toggleAllTasks = () => {
    if (selectedTasks.size === paginatedRequests.length) {
      setSelectedTasks(new Set());
    } else {
      setSelectedTasks(new Set(paginatedRequests.map(r => r.id)));
    }
  };
  return (
    <div className={`bg-white rounded-lg shadow ${archived ? 'opacity-75' : ''}`}>
      <div className="grid grid-cols-12 gap-4 p-3 bg-gray-50 border-b text-sm font-medium text-gray-500">
        {archived && (
          <div className="col-span-1">
            <button
              onClick={toggleAllTasks}
              className="p-1 hover:bg-gray-100 rounded"
              title={selectedTasks.size === paginatedRequests.length ? "Deselect all" : "Select all"}
            >
              <Square className={`w-4 h-4 ${
                selectedTasks.size === paginatedRequests.length ? 'text-blue-600' : 'text-gray-400'
              }`} />
            </button>
          </div>
        )}
        <button 
          onClick={() => handleSort('title')} 
          className={`flex items-center gap-2 hover:text-gray-700 ${archived ? 'col-span-4' : 'col-span-5'}`}
        >
          Tasks {getSortIcon('title')}
        </button>
        <div 
          className="hidden sm:block col-span-3 text-sm font-medium text-gray-500"
        >
          Description
        </div>
        <button 
          onClick={() => handleSort('createdAt')}
          className="col-span-5 sm:col-span-2 flex items-center gap-2 hover:text-gray-700"
        >
          Time {getSortIcon('createdAt')}
        </button>
        <div className="flex items-center justify-end col-span-2">
          {archived && onBulkDelete && (
            <div className="flex items-center gap-2">
              <button 
                onClick={() => handleBulkDelete(true)}
                className={`flex items-center gap-1 px-2 py-1 text-xs sm:text-sm rounded-md ${
                  selectedTasks.size > 0 
                    ? 'text-red-600 hover:bg-red-50' 
                    : 'text-gray-400 cursor-not-allowed'
                }`}
                disabled={selectedTasks.size === 0}
                title="Delete selected tasks"
              >
                <Trash2 className="w-3 h-3 sm:w-4 sm:h-4" />
                <span className="hidden sm:inline">Delete Selected</span>
              </button>
            </div>
          )}
        </div>
      </div>
      
      <div>
        {paginatedRequests.map((request, index) => (
          <RequestRow 
            key={request.id}
            request={request}
            position={index}
            onComplete={onComplete}
            archived={archived}
            selected={selectedTasks.has(request.id)}
            onSelect={archived ? toggleTaskSelection : undefined}
          />
        ))}
      </div>

      {totalPages > 1 && (
        <div className="flex justify-between items-center px-4 py-2 border-t text-sm">
          <button
            onClick={() => setCurrentPage(prev => Math.max(0, prev - 1))}
            disabled={currentPage === 0}
            className="px-2 py-1 sm:px-3 sm:py-1 text-gray-600 hover:bg-gray-100 rounded-md disabled:opacity-50"
          >
            Previous
          </button>
          <span className="text-xs sm:text-sm text-gray-600">
            Page {currentPage + 1} of {totalPages}
          </span>
          <button
            onClick={() => setCurrentPage(prev => Math.min(totalPages - 1, prev + 1))}
            disabled={currentPage === totalPages - 1}
            className="px-2 py-1 sm:px-3 sm:py-1 text-gray-600 hover:bg-gray-100 rounded-md disabled:opacity-50"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}