import React, { useState, useEffect } from 'react';
import { PlusCircle, ChevronDown, ChevronUp } from 'lucide-react';
import { ServiceRequest } from './types';
import { useAuth } from './contexts/AuthContext';
import { RequestList } from './components/RequestList';
import { NewRequestDialog } from './components/NewRequestDialog';
import { CompletionStats } from './components/CompletionStats';
import { AuthProvider } from './contexts/AuthContext';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ResetPasswordPage } from './components/auth/ResetPasswordPage';
import { Header } from './components/Header';
import { AuthModal } from './components/auth/AuthModal';
import { fetchTasks, createTask, updateTaskStatus, reorderTasks, deleteTask } from './lib/tasks';
import { fetchCategories, reorderCategories } from './lib/categories';

function AppContent() {
  const { user } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');
  const [showNewRequestDialog, setShowNewRequestDialog] = useState(false);
  const [showCompletedTasks, setShowCompletedTasks] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [categories, setCategories] = useState([]);
  const [tasks, setTasks] = useState<ServiceRequest[]>([]);
  const [filteredCategoryId, setFilteredCategoryId] = useState<string | null>(null);

  const loadData = async () => {
    if (!user) {
      setTasks([]);
      setCategories([]);
      return;
    }

    try {
      setIsLoading(true);
      const [tasksData, categoriesData] = await Promise.all([
        fetchTasks(),
        fetchCategories()
      ]);
      setTasks(tasksData);
      setCategories(categoriesData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    // Only load data when user changes
    loadData();
  }, [user?.id]);

  const handleNewRequest = async (requestData: Omit<ServiceRequest, 'id' | 'createdAt'>) => {
    try {
      await createTask(requestData);
      const [tasksData, categoriesData] = await Promise.all([
        fetchTasks(),
        fetchCategories()
      ]);
      setTasks(tasksData);
      setCategories(categoriesData);
      setShowNewRequestDialog(false);
    } catch (error) {
      console.error('Failed to create task:', error);
    }
  };

  const handleComplete = async (id: string) => {
    try {
      await updateTaskStatus(id, true);
      await loadData();
    } catch (error) {
      console.error('Failed to complete task:', error);
    }
  };

  const handleTaskReorder = async (reorderedTasks: ServiceRequest[]) => {
    try {
      await reorderTasks(reorderedTasks);
      await loadData();
    } catch (error) {
      console.error('Failed to reorder tasks:', error);
      await loadData(); // Reload on error
    }
  };

  const handleBulkDelete = async (ids: string[]) => {
    if (!window.confirm('Are you sure you want to delete all completed tasks?')) {
      return;
    }

    try {
      await Promise.all(ids.map(id => deleteTask(id)));
      await loadData();
    } catch (error) {
      console.error('Failed to delete tasks:', error);
    }
  };

  const filteredTasks = filteredCategoryId
    ? tasks.filter(task => task.category_id === filteredCategoryId)
    : tasks;

  const activeTasks = filteredTasks.filter(task => !task.completedAt);
  const completedTasks = filteredTasks.filter(task => task.completedAt);

  return (
    <div className="min-h-screen bg-gray-50">
      <Header onAuthClick={(mode) => {
        setAuthMode(mode);
        setShowAuthModal(true);
      }} />
      
      <main className="max-w-6xl mx-auto py-4 px-4 sm:py-6 sm:px-6 lg:px-8">
        {user ? (
          <>
            <div className="flex justify-center mb-4 sm:mb-6">
              <button 
                onClick={() => setShowNewRequestDialog(true)}
                className="flex items-center justify-center gap-2 w-full max-w-md px-4 py-2 bg-blue-600 text-white text-base rounded-lg hover:bg-blue-700 transition-colors"
              >
                <PlusCircle className="w-4 h-4 sm:w-5 sm:h-5" />
                New Task
              </button>
            </div>

            {isLoading ? (
              <div className="flex justify-center items-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            ) : (
              <>
                <div className="space-y-4 sm:space-y-6">
                  <div>
                    <h2 className="text-lg sm:text-xl font-semibold text-gray-900 mb-3 sm:mb-4">Active Tasks</h2>
                    <div className="flex flex-wrap gap-2 mb-4">
                      {[...categories].sort((a, b) => a.name.localeCompare(b.name)).map((category) => (
                        <button
                          key={category.id}
                          onClick={() => setFilteredCategoryId(
                            filteredCategoryId === category.id ? null : category.id
                          )}
                          className={`px-3 py-1.5 rounded-full text-sm transition-colors ${
                            filteredCategoryId === category.id ? 'ring-2 ring-offset-2' : ''
                          }`}
                          style={{ 
                            backgroundColor: `${category.color}20`,
                            color: category.color,
                            ringColor: category.color
                          }}
                        >
                          {category.name}
                        </button>
                      ))}
                    </div>
                    <RequestList
                      requests={activeTasks}
                      onReorder={handleTaskReorder}
                      onComplete={handleComplete}
                    />
                  </div>

                  <CompletionStats requests={tasks} />

                  {completedTasks.length > 0 && (
                    <div className="border rounded-lg bg-white shadow">
                      <button
                        onClick={() => setShowCompletedTasks(!showCompletedTasks)}
                        className="w-full flex items-center justify-between p-3 sm:px-4 sm:py-3 hover:bg-gray-50"
                      >
                        <div className="flex items-center gap-2">
                          <h2 className="text-lg sm:text-xl font-semibold text-gray-900">Completed Tasks</h2>
                          <span className="text-xs sm:text-sm text-gray-500">({completedTasks.length})</span>
                        </div>
                        {showCompletedTasks ? (
                          <ChevronUp className="w-4 h-4 sm:w-5 sm:h-5 text-gray-400" />
                        ) : (
                          <ChevronDown className="w-4 h-4 sm:w-5 sm:h-5 text-gray-400" />
                        )}
                      </button>
                      
                      {showCompletedTasks && (
                        <div className="border-t">
                          <RequestList
                            requests={completedTasks}
                            archived
                            onReorder={handleTaskReorder}
                            onBulkDelete={handleBulkDelete}
                          />
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </>
            )}

            {showNewRequestDialog && (
              <NewRequestDialog
                onClose={() => setShowNewRequestDialog(false)}
                onSubmit={handleNewRequest}
              />
            )}
          </>
        ) : (
          <div className="text-center py-8 sm:py-12 px-4">
            <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-3 sm:mb-4">Welcome to DoneTasker.com</h2>
            <p className="text-gray-600 mb-6 sm:mb-8">Effortlessly monitor task progress and optimize your team's productivity.</p>
            <div className="flex items-center justify-center gap-4">
              <button
                onClick={() => {
                  setAuthMode('login');
                  setShowAuthModal(true);
                }}
                className="px-5 py-2.5 sm:px-6 sm:py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm sm:text-base"
              >
                Sign In
              </button>
              <button
                onClick={() => {
                  setAuthMode('signup');
                  setShowAuthModal(true);
                }}
                className="px-5 py-2.5 sm:px-6 sm:py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm sm:text-base"
              >
                Sign Up for Free
              </button>
            </div>
          </div>
        )}
      </main>

      {showAuthModal && (
        <AuthModal 
          onClose={() => setShowAuthModal(false)} 
          initialMode={authMode}
        />
      )}
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="*" element={<AppContent />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}