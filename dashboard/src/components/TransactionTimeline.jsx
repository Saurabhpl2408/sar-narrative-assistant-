import React from 'react';

export default function TransactionTimeline({ transactions }) {
  if (!transactions || transactions.length === 0) {
    return (
      <div className="text-center py-8 text-slate-500 text-sm">
        No flagged transactions found
      </div>
    );
  }

  const directionIcon = (dir) =>
    dir === 'inbound' ? (
      <svg className="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 13.5 12 21m0 0-7.5-7.5M12 21V3" />
      </svg>
    ) : (
      <svg className="w-4 h-4 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 10.5 12 3m0 0 7.5 7.5M12 3v18" />
      </svg>
    );

  const typeLabels = {
    cash_deposit: 'Cash Deposit',
    cash_withdrawal: 'Cash Withdrawal',
    wire_transfer: 'Wire Transfer',
    ach: 'ACH',
    check: 'Check',
  };

  return (
    <div className="space-y-2">
      {transactions.map((txn, idx) => (
        <div
          key={txn.id || idx}
          className="flex items-center gap-4 p-3 rounded-lg bg-slate-900/30 border border-slate-800/30 hover:border-slate-700/50 transition-colors"
        >
          <div className="flex-shrink-0">
            {directionIcon(txn.direction)}
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium text-slate-300">
                {typeLabels[txn.type] || txn.type}
              </span>
              <span className="text-[10px] text-slate-600 font-mono">
                {txn.transactionDate ? new Date(txn.transactionDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''}
              </span>
            </div>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-[10px] text-slate-500 truncate">
                {txn.counterpartyName || 'N/A'}
              </span>
              {txn.counterpartyCountry && txn.counterpartyCountry !== 'USA' && (
                <span className="text-[10px] px-1.5 py-0.5 rounded bg-red-500/10 text-red-400 border border-red-500/20 font-mono">
                  {txn.counterpartyCountry}
                </span>
              )}
              {txn.branch && (
                <span className="text-[10px] text-slate-600">{txn.branch}</span>
              )}
            </div>
          </div>

          <div className="flex-shrink-0 text-right">
            <span className={`text-sm font-mono font-semibold ${txn.direction === 'inbound' ? 'text-emerald-400' : 'text-red-400'}`}>
              {txn.direction === 'inbound' ? '+' : '-'}${Number(txn.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}
