import React from 'react';

const statusConfig = {
  new: { bg: 'bg-blue-500/15', text: 'text-blue-400', border: 'border-blue-500/30', label: 'NEW' },
  under_review: { bg: 'bg-purple-500/15', text: 'text-purple-400', border: 'border-purple-500/30', label: 'REVIEWING' },
  sar_filed: { bg: 'bg-emerald-500/15', text: 'text-emerald-400', border: 'border-emerald-500/30', label: 'SAR FILED' },
  dismissed: { bg: 'bg-slate-500/15', text: 'text-slate-400', border: 'border-slate-500/30', label: 'DISMISSED' },
};

export default function StatusBadge({ status }) {
  const config = statusConfig[status] || statusConfig.new;
  return (
    <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-[10px] font-bold tracking-wider border ${config.bg} ${config.text} ${config.border}`}>
      {config.label}
    </span>
  );
}
