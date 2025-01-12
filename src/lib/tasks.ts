import { supabase } from './supabase';
import { ServiceRequest, Comment, WorkSession } from '../types';

export async function fetchTasks() {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { data, error } = await supabase
    .from('tasks')
    .select(`
      *,
      categories (*),
      subtasks (*)
    `)
    .order('order', { ascending: true });

  if (error) throw error;

  return data.map((task): ServiceRequest => ({
    id: task.id,
    title: task.title,
    description: task.description || undefined,
    assignee_id: task.assignee_id,
    createdAt: new Date(task.created_at),
    completedAt: task.completed_at ? new Date(task.completed_at) : undefined,
    category_id: task.category_id,
    category: task.categories,
    notes: task.notes,
    order: task.order
  }));
}

export async function createTask(task: Omit<ServiceRequest, 'id' | 'createdAt'>) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { data: assigneeData } = await supabase
    .from('company_users')
    .select('email')
    .eq('user_id', task.assignee_id)
    .maybeSingle();

  const assigneeEmail = assigneeData?.email || user.email;

  const { data, error } = await supabase
    .from('tasks')
    .insert([{
      title: task.title,
      description: task.description,
      assignee_id: task.assignee_id || user.id,
      category_id: task.category_id || null,
      user_id: user.id
    }])
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateTaskStatus(id: string, completed: boolean) {
  // First stop any active timer
  const activeSession = await fetchActiveWorkSession(id);
  if (activeSession) {
    await stopTaskTimer(id);
  }

  // Then mark the task as completed
  const { error } = await supabase
    .from('tasks')
    .update({ 
      completed_at: completed ? new Date().toISOString() : null
    })
    .eq('id', id);

  if (error) throw error;
}

export async function updateTaskTitle(id: string, title: string) {
  const { error } = await supabase
    .from('tasks')
    .update({ title: title.trim() })
    .eq('id', id);

  if (error) throw error;
}

export async function updateTaskDescription(id: string, description: string) {
  const { error } = await supabase
    .from('tasks')
    .update({ 
      description: description.trim() || null 
    })
    .eq('id', id);

  if (error) throw error;
}

export async function updateTaskNotes(id: string, notes: string) {
  const { error } = await supabase
    .from('tasks')
    .update({ 
      notes: notes.trim() || null 
    })
    .eq('id', id);

  if (error) throw error;
}

export async function updateTaskCategory(id: string, categoryId: string | null) {
  const { error } = await supabase
    .from('tasks')
    .update({ category_id: categoryId })
    .eq('id', id);

  if (error) throw error;
}

export async function deleteTask(id: string) {
  // First delete related records
  await Promise.all([
    supabase.from('work_sessions').delete().eq('task_id', id),
    supabase.from('comments').delete().eq('task_id', id),
    supabase.from('subtasks').delete().eq('task_id', id)
  ]);

  // Then delete the task itself
  const { error } = await supabase
    .from('tasks')
    .delete()
    .eq('id', id);

  if (error) throw error;
}

export async function reorderTasks(tasks: ServiceRequest[]) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { error } = await supabase
    .from('tasks')
    .upsert(
      tasks.map((task, index) => ({
        id: task.id,
        order: index
      }))
    )
    .eq('user_id', user.id);

  if (error) throw error;
}

export async function addComment(taskId: string, content: string) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { data, error } = await supabase
    .from('comments')
    .insert([{
      task_id: taskId,
      content,
      user_id: user.id
    }])
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function fetchComments(taskId: string): Promise<Comment[]> {
  const { data, error } = await supabase
    .from('comments')
    .select('*')
    .eq('task_id', taskId)
    .order('created_at', { ascending: true });

  if (error) throw error;

  return data.map((comment): Comment => ({
    id: comment.id,
    content: comment.content,
    task_id: comment.task_id,
    user_id: comment.user_id,
    created_at: new Date(comment.created_at)
  }));
}

export async function fetchActiveWorkSession(taskId: string): Promise<WorkSession | null> {
  const { data, error } = await supabase
    .from('work_sessions')
    .select('*')
    .eq('task_id', taskId)
    .is('end_time', null)
    .maybeSingle();

  if (error) throw error;

  if (!data) return null;

  return {
    id: data.id,
    task_id: data.task_id,
    start_time: new Date(data.start_time),
    end_time: data.end_time ? new Date(data.end_time) : undefined,
    user_id: data.user_id
  };
}

export async function startTaskTimer(taskId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { error } = await supabase
    .from('work_sessions')
    .insert([{
      task_id: taskId,
      user_id: user.id
    }]);

  if (error) throw error;
}

export async function stopTaskTimer(taskId: string) {
  const { error } = await supabase
    .from('work_sessions')
    .update({ end_time: new Date().toISOString() })
    .eq('task_id', taskId)
    .is('end_time', null);

  if (error) throw error;
}

export async function calculateTotalTime(taskId: string): Promise<string> {
  const { data, error } = await supabase
    .from('work_sessions')
    .select('start_time, end_time')
    .eq('task_id', taskId)
    .not('end_time', 'is', null);

  if (error) throw error;

  const totalMilliseconds = data.reduce((total, session) => {
    const start = new Date(session.start_time);
    const end = new Date(session.end_time);
    return total + (end.getTime() - start.getTime());
  }, 0);

  const hours = Math.floor(totalMilliseconds / (1000 * 60 * 60));
  const minutes = Math.floor((totalMilliseconds % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((totalMilliseconds % (1000 * 60)) / 1000);

  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
}