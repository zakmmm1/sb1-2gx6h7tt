import { supabase } from './supabase';
import { Subtask } from '../types';

export async function fetchSubtasks(taskId: string) {
  const { data, error } = await supabase
    .from('subtasks')
    .select('*')
    .eq('task_id', taskId)
    .order('created_at');

  if (error) throw error;

  return data.map((subtask): Subtask => ({
    id: subtask.id,
    title: subtask.title,
    description: subtask.description,
    status: subtask.status,
    task_id: subtask.task_id,
    created_at: new Date(subtask.created_at),
    completed_at: subtask.completed_at ? new Date(subtask.completed_at) : undefined
  }));
}

export async function createSubtask(subtask: Omit<Subtask, 'id' | 'created_at' | 'completed_at'>) {
  const { data, error } = await supabase
    .from('subtasks')
    .insert([{
      ...subtask,
      user_id: (await supabase.auth.getUser()).data.user?.id
    }])
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateSubtaskStatus(id: string, status: Subtask['status']) {
  const { error } = await supabase
    .from('subtasks')
    .update({ 
      status,
      completed_at: status === 'completed' ? new Date().toISOString() : null
    })
    .eq('id', id);

  if (error) throw error;
}