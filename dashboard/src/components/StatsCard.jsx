import React from 'react';

export default function StatsCard({ title, value, subtitle, icon, accent = 'amber' }) {
  const accentStyles = {
    amber: 'from-amber-500/20 to-orange-500/10 border-amber-500/20',
    red: 'from-red-500/20 to-rose-500/10 border-red-500/20',
    emerald: 'from-emerald-500/20 to-teal-500/10 border-emerald-500/20',
    blue: 'from-blue-500/20 to-indigo-500/10 border-blue-500/20',
    purple: 'from-purple-500/20 to-violet-500/10 border-purple-500/20',
  };

  return (
    <div className={`bg-gradient-to-br ${accentStyles[accent]} border rounded-xl p-5 backdrop-blur-sm`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-slate-400 font-medium uppercase tracking-wider">{title}</p>
          <p className="text-3xl font-bold text-white mt-2 font-mono">{value}</p>
          {subtitle && <p className="text-xs text-slate-500 mt-1">{subtitle}</p>}
        </div>
        {icon && <div className="text-slate-500">{icon}</div>}
      </div>
    </div>
  );
}
