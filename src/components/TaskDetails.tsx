import React, { useState, useEffect } from 'react';
import { Edit2, Save, Play, Pause, Clock, MessageSquare, Send, Type, Tag } from 'lucide-react';
import { ServiceRequest, Comment } from '../types';
import { 
  updateTaskDescription, 
  updateTaskNotes, 
  updateTaskTitle,
  updateTaskCategory,
  startTaskTimer, 
  stopTaskTimer,
  fetchActiveWorkSession,
  calculateTotalTime,
  addComment,
  fetchComments
} from '../lib/tasks';
import { fetchCategories } from '../lib/categories';
import { CategorySelect } from './CategorySelect';
import { AccountSettingsDialog } from './AccountSettingsDialog';
import { TaskTimer } from './TaskTimer';
import { useAuth } from '../contexts/AuthContext';

interface TaskDetailsProps {
  request: ServiceRequest;
  archived?: boolean;
}
import { formatInTimezone } from '../utils/timeUtils';
import { getUserSettings } from '../lib/user';

export const TaskDetails: React.FC<TaskDetailsProps> = ({ request, archived = false }) => {
  const { user } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [title, setTitle] = useState(request.title);
  const [description, setDescription] = useState(request.description);
  const [categoryId, setCategoryId] = useState(request.category_id);
  const [notes, setNotes] = useState(request.notes || '');
  const [userTimezone, setUserTimezone] = useState<string>();
  const [categories, setCategories] = useState([]);
  const [showCategorySettings, setShowCategorySettings] = useState(false);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [timerStartTime, setTimerStartTime] = useState<Date>();
  const [totalTime, setTotalTime] = useState('00:00:00');
  const [newComment, setNewComment] = useState('');
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      if (user) {
        const [settings, activeSession, total, taskComments, categoriesData] = await Promise.all([
          getUserSettings(),
          fetchActiveWorkSession(request.id),
          calculateTotalTime(request.id),
          fetchComments(request.id),
          fetchCategories()
        ]);

        setUserTimezone(settings?.timezone);
        setCategories(categoriesData);

        if (activeSession) {
          setTimerStartTime(activeSession.start_time);
          setIsTimerRunning(true);
        }
        setTotalTime(total);
        setComments(taskComments);
      }
    };

    // Reset timer state when task is completed
    if (request.completedAt) {
      setIsTimerRunning(false);
      setTimerStartTime(undefined);
    }

    loadData().catch(error => {
      console.error('Failed to load task data:', error);
    });
  }, [request.id]);

  const reloadTaskData = async () => {
    setIsLoading(true);
    try {
      const [activeSession, total, taskComments, categoriesData] = await Promise.all([
        fetchActiveWorkSession(request.id),
        calculateTotalTime(request.id),
        fetchComments(request.id),
        fetchCategories()
      ]);

      setCategories(categoriesData);
      if (activeSession) {
        setTimerStartTime(activeSession.start_time);
        setIsTimerRunning(true);
      }
      setTotalTime(total);
      setComments(taskComments);
    } catch (error) {
      console.error('Failed to reload task data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setIsLoading(true);
      setIsEditing(false);
      
      const updates = [
        updateTaskTitle(request.id, title),
        updateTaskDescription(request.id, description || ''),
        updateTaskNotes(request.id, notes || ''),
        updateTaskCategory(request.id, categoryId || null)
      ];
      
      await Promise.all(updates);
      await reloadTaskData();
    } catch (error) {
      console.error('Failed to update task:', error);
      setIsEditing(true); // Revert to editing mode on error
    } finally {
      setIsLoading(false);
    }
  };

  const handleCategoryChange = async (categoryId: string) => {
    setCategoryId(categoryId || undefined);
  };

  const toggleTimer = async () => {
    try {
      if (isTimerRunning) {
        await stopTaskTimer(request.id);
        setTimerStartTime(undefined);
        const total = await calculateTotalTime(request.id);
        setTotalTime(total);
      } else {
        await startTaskTimer(request.id);
        setTimerStartTime(new Date());
      }
      setIsTimerRunning(!isTimerRunning);
    } catch (error) {
      console.error('Failed to toggle timer:', error);
    }
  };

  const handleAddComment = async () => {
    if (!newComment.trim()) return;
    
    try {
      await addComment(request.id, newComment);
      const updatedComments = await fetchComments(request.id);
      setComments(updatedComments);
      setNewComment('');
    } catch (error) {
      console.error('Failed to add comment:', error);
    }
  };

  return (
    <div className="px-4 py-6 bg-gray-50 border-b">
      <div className="max-w-3xl mx-auto space-y-6">
        {isLoading && (
          <div className="absolute inset-0 bg-white/50 flex items-center justify-center z-10">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        )}
        {/* Edit/Save Button */}
        {!archived && (
          <div className="flex justify-end">
            <button
              onClick={() => isEditing ? handleSave() : setIsEditing(true)}
              className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-500"
            >
              {isEditing ? (
                <>
                  <Save className="w-4 h-4" />
                  Save Changes
                </>
              ) : (
                <>
                  <Edit2 className="w-4 h-4" />
                  Edit Task
                </>
              )}
            </button>
          </div>
        )}

        {/* Task Name section */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-2">Task Name</h4>
          {isEditing ? (
            <div className="relative">
              <Type className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full pl-10 p-2 border rounded-md"
                placeholder="Task name"
              />
            </div>
          ) : (
            <p className="text-gray-900 font-medium">
              {title}
            </p>
          )}
        </div>

        {/* Completion Time */}
        {request.completedAt && (
          <div className="bg-green-50 p-3 rounded-md">
            <p className="text-sm text-green-700">
              Completed on {formatInTimezone(request.completedAt, userTimezone)}
            </p>
          </div>
        )}

        {/* Category section */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
            <Tag className="w-4 h-4 text-gray-500" />
            Category
          </h4>
          {isEditing ? (
            <div className="space-y-2">
              <CategorySelect
                categories={categories}
                selectedId={categoryId}
                onChange={handleCategoryChange}
                optional
              />
              <button
                onClick={() => setShowCategorySettings(true)}
                className="text-sm text-blue-600 hover:text-blue-500"
              >
                Manage categories
              </button>
            </div>
          ) : (
            <CategorySelect
              categories={categories}
              selectedId={categoryId}
              onChange={() => {}}
              optional
              disabled
            />
          )}
        </div>

        {/* Description section */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-2">Description</h4>
          {isEditing ? (
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full p-2 border rounded-md"
              rows={3}
            />
          ) : (
            <p className="text-gray-600">
              {description || (
                <span className="text-gray-400 italic">No description provided</span>
              )}
            </p>
          )}
        </div>

        {/* Notes section */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-2">Notes</h4>
          {isEditing ? (
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full p-2 border rounded-md"
              rows={3}
              placeholder="Add notes about this task..."
            />
          ) : (
            <p className="text-gray-600">
              {notes || <span className="text-gray-400 italic">No notes added yet</span>}
            </p>
          )}
        </div>

        {/* Timer section */}
        <div>
          <div className="flex items-center gap-4">
            {!archived && !request.completedAt && (
              <button
                onClick={toggleTimer}
                className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium ${
                  isTimerRunning
                    ? 'bg-red-100 text-red-700 hover:bg-red-200'
                    : 'bg-green-100 text-green-700 hover:bg-green-200'
                }`}
              >
                {isTimerRunning ? (
                  <>
                    <Pause className="w-4 h-4" />
                    Pause Timer
                  </>
                ) : (
                  <>
                    <Play className="w-4 h-4" />
                    Start Timer
                  </>
                )}
              </button>
            )}
            {!request.completedAt && isTimerRunning && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Clock className="w-4 h-4" />
                Current session: <TaskTimer startTime={timerStartTime} isRunning={isTimerRunning} />
              </div>
            )}
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Clock className="w-4 h-4" />
              Total time tracked: {totalTime}
              <button
                onClick={reloadTaskData}
                disabled={isLoading}
                className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                title="Refresh timer"
              >
                <svg
                  className={`w-4 h-4 text-gray-500 ${isLoading ? 'animate-spin' : ''}`}
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Comments section */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-4">Comments</h4>
          
          {/* Add comment */}
          {!archived && (
            <div className="flex gap-2 mb-4">
              <input
                type="text"
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="Add a comment..."
                className="flex-1 p-2 border rounded-md"
                onKeyPress={(e) => e.key === 'Enter' && handleAddComment()}
              />
              <button
                onClick={handleAddComment}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                <Send className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Comments list */}
          <div className="space-y-4">
            {comments.map((comment) => (
              <div key={comment.id} className="flex gap-3 p-3 bg-white rounded-lg shadow-sm">
                <MessageSquare className="w-5 h-5 text-gray-400" />
                <div>
                  <p className="text-gray-600">{comment.content}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {formatInTimezone(comment.created_at, userTimezone)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      
      {showCategorySettings && (
        <AccountSettingsDialog 
          onClose={() => setShowCategorySettings(false)}
          initialTab="categories"
        />
      )}
    </div>
  );
};