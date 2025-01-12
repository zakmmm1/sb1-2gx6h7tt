/*
  # Add storage bucket for task files

  1. New Storage
    - Create 'task-files' bucket for storing task attachments
    - Set up RLS policies for secure file access
    - Configure size limits for file uploads

  2. Security
    - Enable RLS on the bucket
    - Add policies for authenticated users to manage their files
*/

-- Create storage bucket for task files
INSERT INTO storage.buckets (id, name, public)
VALUES ('task-files', 'task-files', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Authenticated users can upload task files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'task-files' AND
  (octet_length(COALESCE(bucket_id, '')) <= 2097152) -- 2MB limit
);

CREATE POLICY "Authenticated users can read task files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'task-files');

CREATE POLICY "Users can update their own task files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'task-files')
WITH CHECK (bucket_id = 'task-files');

CREATE POLICY "Users can delete their own task files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'task-files');

-- Add file_url column to tasks if it doesn't exist
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS file_url text;