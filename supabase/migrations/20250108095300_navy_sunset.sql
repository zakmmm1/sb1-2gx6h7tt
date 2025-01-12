/*
  # Add order column to categories table

  1. Changes
    - Add order column to categories table
    - Update existing categories to have sequential order
    - Add index for better performance

  2. Notes
    - Uses safe operations that won't affect existing data
    - Ensures backward compatibility
*/

-- Add order column if it doesn't exist
ALTER TABLE categories 
ADD COLUMN IF NOT EXISTS "order" integer DEFAULT 0;

-- Update existing categories to have sequential order
WITH numbered_categories AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM categories
)
UPDATE categories
SET "order" = numbered_categories.row_num
FROM numbered_categories
WHERE categories.id = numbered_categories.id;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_categories_order 
  ON categories("order");