import React from 'react';

export default function CustomerCard({ customer }) {
  if (!customer) return null;

  const riskColors = {
    low: 'text-emerald-400 bg-emerald-500/15 border-emerald-500/30',
    medium: 'text-amber-400 bg-amber-500/15 border-amber-500/30',
    high: 'text-red-400 bg-red-500/15 border-red-500/30',
    critical: 'text-red-300 bg-red-500/20 border-red-500/40',
  };

  const riskClass = riskColors[customer.riskRating] || riskColors.low;

  return (
    <div className="bg-slate-900/50 border border-slate-800/50 rounded-xl p-5">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-sm font-bold text-amber-400">
          {customer.name?.split(' ').map(n => n[0]).join('')}
        </div>
        <div>
          <h3 className="text-sm font-semibold text-white">{customer.name}</h3>
          <p className="text-xs text-slate-500 font-mono">{customer.accountNumber}</p>
        </div>
      </div>

      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <span className="text-xs text-slate-500">Account Type</span>
          <span className="text-xs text-slate-300 capitalize">{customer.accountType}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-xs text-slate-500">Risk Rating</span>
          <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded border ${riskClass}`}>
            {customer.riskRating}
          </span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-xs text-slate-500">Occupation</span>
          <span className="text-xs text-slate-300">{customer.occupation || 'N/A'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-xs text-slate-500">Account Opened</span>
          <span className="text-xs text-slate-300 font-mono">{customer.openedDate}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-xs text-slate-500">Country</span>
          <span className="text-xs text-slate-300">{customer.country}</span>
        </div>
      </div>
    </div>
  );
}
