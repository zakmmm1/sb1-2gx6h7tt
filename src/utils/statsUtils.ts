import { ServiceRequest } from '../types';

export const calculateCompletionTime = (request: ServiceRequest): number => {
  if (!request.completedAt) return 0;
  return (request.completedAt.getTime() - request.createdAt.getTime()) / (1000 * 60 * 60); // in hours
};

export const filterByTimeRange = (date: Date, range: string): boolean => {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const hours = diff / (1000 * 60 * 60);

  switch (range) {
    case '24h': return hours <= 24;
    case '7d': return hours <= 168; // 7 * 24
    case '30d': return hours <= 720; // 30 * 24
    default: return true;
  }
};