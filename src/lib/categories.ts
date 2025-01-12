import { supabase } from './supabase';
import { Category } from '../types';

export async function fetchCategories() {
  const { data, error } = await supabase
    .from('categories')
    .select('*');

  if (error) throw error;

  return data.map((category): Category => ({
    id: category.id,
    name: category.name,
    color: category.color,
    created_at: new Date(category.created_at),
    order: category.order
  }));
}

export async function createCategory({ name, color }: Pick<Category, 'name' | 'color'>) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { data, error } = await supabase
    .from('categories')
    .insert([{
      name,
      color,
      user_id: user.id
    }])
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateCategory(
  id: string, 
  { name, color }: Pick<Category, 'name' | 'color'>
) {
  const { error } = await supabase
    .from('categories')
    .update({ name, color })
    .eq('id', id);

  if (error) throw error;
}

export async function deleteCategory(id: string) {
  const { error } = await supabase
    .from('categories')
    .delete()
    .eq('id', id);

  if (error) throw error;
}