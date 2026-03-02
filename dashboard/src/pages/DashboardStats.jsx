import React, { useState, useEffect } from 'react';
import { fetchDashboardStats } from '../api/client';
import StatsCard from '../components/StatsCard';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const RULE_COLORS = {
  STRUCTURING: '#f59e0b',
  HIGH_RISK_JURISDICTION: '#ef4444',
  RAPID_FUND_MOVEMENT: '#8b5cf6',
  VOLUME_SPIKE: '#3b82f6',
  LARGE_CASH: '#10b981',
};

const SEVERITY_COLORS = {
  high: '#ef4444',
  medium: '#f59e0b',
  low: '#10b981',
};

const ruleLabels = {
  STRUCTURING: 'Structuring',
  HIGH_RISK_JURISDICTION: 'High-Risk Juris.',
  RAPID_FUND_MOVEMENT: 'Rapid Movement',
  VOLUME_SPIKE: 'Volume Spike',
  LARGE_CASH: 'Large Cash',
};

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 shadow-xl">
      <p className="text-xs text-slate-400">{label}</p>
      <p className="text-sm font-mono font-bold text-white">{payload[0].value}</p>
    </div>
  );
};

export default function DashboardStats() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const data = await fetchDashboardStats();
      setStats(data);
    } catch (e) {
      console.error('Failed to load stats:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <svg className="w-8 h-8 animate-spin text-amber-500" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      </div>
    );
  }

  if (!stats) return <p className="text-slate-500">Failed to load dashboard data.</p>;

  const ruleData = stats.byRule
    ? Object.entries(stats.byRule).map(([key, value]) => ({
        name: ruleLabels[key] || key,
        count: value,
        fill: RULE_COLORS[key] || '#64748b',
      }))
    : [];

  const severityData = stats.bySeverity
    ? Object.entries(stats.bySeverity)
        .filter(([_, v]) => v > 0)
        .map(([key, value]) => ({
          name: key.charAt(0).toUpperCase() + key.slice(1),
          value: value,
        }))
    : [];

  const statusData = stats.byStatus
    ? Object.entries(stats.byStatus).map(([key, value]) => ({
        name: key.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase()),
        count: value,
      }))
    : [];

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-xl font-bold text-white">Dashboard</h2>
        <p className="text-sm text-slate-500 mt-0.5">Overview of transaction monitoring activity</p>
      </div>

      <div className="grid grid-cols-4 gap-4 mb-8">
        <StatsCard title="Total Alerts" value={stats.totalAlerts || 0} subtitle={`${stats.alertsThisWeek || 0} this week`} accent="amber" />
        <StatsCard title="New Alerts" value={stats.byStatus?.new || 0} subtitle="Awaiting review" accent="blue" />
        <StatsCard title="SARs Filed" value={stats.byStatus?.sar_filed || 0} subtitle="Completed filings" accent="emerald" />
        <StatsCard title="Total Transactions" value={stats.totalTransactions || 0} subtitle={`${stats.totalCustomers || 0} customers`} accent="purple" />
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div className="bg-slate-900/30 border border-slate-800/50 rounded-xl p-5">
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-5">Alerts by Detection Rule</h3>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={ruleData} layout="vertical" margin={{ left: 10, right: 20 }}>
              <XAxis type="number" tick={{ fill: '#64748b', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fill: '#94a3b8', fontSize: 11 }} axisLine={false} tickLine={false} width={110} />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(255,255,255,0.03)' }} />
              <Bar dataKey="count" radius={[0, 4, 4, 0]} barSize={20}>
                {ruleData.map((entry, i) => (
                  <Cell key={i} fill={entry.fill} fillOpacity={0.8} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-slate-900/30 border border-slate-800/50 rounded-xl p-5">
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-5">Severity Distribution</h3>
          <div className="flex items-center justify-center">
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie data={severityData} cx="50%" cy="50%" innerRadius={60} outerRadius={100} paddingAngle={4} dataKey="value" stroke="none">
                  {severityData.map((entry, i) => (
                    <Cell key={i} fill={SEVERITY_COLORS[entry.name.toLowerCase()] || '#64748b'} fillOpacity={0.8} />
                  ))}
                </Pie>
                <Tooltip content={<CustomTooltip />} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center gap-5 mt-2">
            {severityData.map((entry, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: SEVERITY_COLORS[entry.name.toLowerCase()] || '#64748b' }} />
                <span className="text-xs text-slate-400">{entry.name}: <span className="font-mono text-white">{entry.value}</span></span>
              </div>
            ))}
          </div>
        </div>

        <div className="col-span-2 bg-slate-900/30 border border-slate-800/50 rounded-xl p-5">
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-4">Alert Status Breakdown</h3>
          <div className="grid grid-cols-4 gap-4">
            {statusData.map((item, i) => (
              <div key={i} className="text-center p-4 rounded-lg bg-slate-950/50 border border-slate-800/30">
                <p className="text-2xl font-mono font-bold text-white">{item.count}</p>
                <p className="text-xs text-slate-500 mt-1">{item.name}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
