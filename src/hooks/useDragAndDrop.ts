import { useState } from 'react';

interface DraggableItem {
  id: string;
  [key: string]: any;
}

export function useDragAndDrop<T extends DraggableItem>(initialItems: T[]) {
  const [items, setItems] = useState<T[]>(initialItems);

  const handleDragStart = (e: React.DragEvent, position: number) => {
    e.dataTransfer.setData('text/plain', position.toString());
    e.currentTarget.classList.add('opacity-50');
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  };

  const handleDragEnd = (e: React.DragEvent) => {
    e.currentTarget.classList.remove('opacity-50');
  };

  const handleDrop = (e: React.DragEvent, dropPosition: number) => {
    e.preventDefault();
    const dragPosition = parseInt(e.dataTransfer.getData('text/plain'), 10);
    
    if (dragPosition === dropPosition) return;

    const newItems = [...items];
    const [draggedItem] = newItems.splice(dragPosition, 1);
    newItems.splice(dropPosition, 0, draggedItem);
    
    setItems(newItems);
    return newItems;
  };

  return {
    items,
    setItems,
    handleDragStart,
    handleDragOver,
    handleDragEnd,
    handleDrop
  };
}