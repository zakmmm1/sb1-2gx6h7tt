import React, { useState } from 'react';
import { ServiceRequest, TimeRange } from '../types';
import { filterByTimeRange, calculateCompletionTime } from '../utils/statsUtils';
import { formatDuration } from '../utils/timeUtils';

interface CompletionStatsProps {
  requests: ServiceRequest[];
}

export const CompletionStats: React.FC<CompletionStatsProps> = ({ requests }) => {
  const [timeRange, setTimeRange] = useState<TimeRange>('24h');

  const calculateStats = () => {
    const completedRequests = requests.filter(
      req => req.completedAt && filterByTimeRange(req.completedAt, timeRange)
    );

    if (completedRequests.length === 0) {
      return { averageTime: 0, count: 0 };
    }

    const totalTime = completedRequests.reduce((sum, req) => {
      if (!req.completedAt) return sum;
      const completionTime = (req.completedAt.getTime() - req.createdAt.getTime()) / (1000 * 60 * 60); // Convert to hours
      return sum + completionTime;
    }, 0);

    return {
      averageTime: totalTime / completedRequests.length,
      count: completedRequests.length
    };
  };

  const stats = calculateStats();

  return (
    <div className="bg-white rounded-lg shadow p-4 mb-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-semibold text-gray-900">Completion Statistics</h2>
        <select
          value={timeRange}
          onChange={(e) => setTimeRange(e.target.value as TimeRange)}
          className="rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        >
          <option value="24h">Last 24 Hours</option>
          <option value="7d">Last 7 Days</option>
          <option value="30d">Last 30 Days</option>
          <option value="all">All Time</option>
        </select>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-gray-50 p-4 rounded-lg">
          <p className="text-sm text-gray-500">Average Completion Time</p>
          <p className="text-2xl font-bold text-gray-900">
            {formatDuration(stats.averageTime)}
          </p>
        </div>
        <div className="bg-gray-50 p-4 rounded-lg">
          <p className="text-sm text-gray-500">Completed Tasks</p>
          <p className="text-2xl font-bold text-gray-900">{stats.count}</p>
        </div>
      </div>
    </div>
  );
};