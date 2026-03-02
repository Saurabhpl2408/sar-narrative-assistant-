import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { fetchAlertById, updateAlertStatus } from '../api/client';
import SeverityBadge from '../components/SeverityBadge';
import StatusBadge from '../components/StatusBadge';
import CustomerCard from '../components/CustomerCard';
import TransactionTimeline from '../components/TransactionTimeline';
import NarrativeEditor from '../components/NarrativeEditor';

const ruleDescriptions = {
  STRUCTURING: 'Multiple cash transactions below the $10,000 CTR threshold within a 48-hour window, totaling above $10,000. Consistent with deliberate structuring to avoid reporting requirements.',
  HIGH_RISK_JURISDICTION: 'Wire transfers to or from FATF high-risk or OFAC sanctioned jurisdictions. Elevated money laundering and terrorist financing risk.',
  RAPID_FUND_MOVEMENT: 'Large inbound deposit followed by outbound wire within 24 hours. Pass-through pattern consistent with layering to obscure fund origins.',
  VOLUME_SPIKE: "Transaction volume exceeds 3x the customer's 90-day baseline. Sudden deviation from established behavioral patterns.",
  LARGE_CASH: 'Cash transactions of $10,000 or more triggering CTR requirements. Warrants additional review given customer profile.',
};

export default function AlertDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [alert, setAlert] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    loadAlert();
  }, [id]);

  const loadAlert = async () => {
    setLoading(true);
    try {
      const data = await fetchAlertById(id);
      setAlert(data);
    } catch (e) {
      console.error('Failed to load alert:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (newStatus) => {
    setUpdating(true);
    try {
      const updated = await updateAlertStatus(id, newStatus);
      setAlert(prev => ({ ...prev, status: updated.status }));
    } catch (e) {
      console.error('Failed to update status:', e);
    } finally {
      setUpdating(false);
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

  if (!alert) {
    return (
      <div className="text-center py-16">
        <p className="text-slate-400">Alert not found</p>
        <button onClick={() => navigate('/')} className="mt-3 text-sm text-amber-400 hover:text-amber-300">Back to Queue</button>
      </div>
    );
  }

  const StatusButton = ({ status, label, color }) => (
    <button
      onClick={() => handleStatusChange(status)}
      disabled={updating || alert.status === status}
      className={`px-3 py-1.5 text-xs font-medium rounded-lg border transition-all disabled:opacity-30 ${color}`}
    >
      {label}
    </button>
  );

  return (
    <div>
      <button
        onClick={() => navigate('/')}
        className="flex items-center gap-1.5 text-sm text-slate-400 hover:text-slate-200 transition-colors mb-5"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
        </svg>
        Back to Alert Queue
      </button>

      <div className="flex items-start justify-between mb-6">
        <div>
          <div className="flex items-center gap-3">
            <h2 className="text-xl font-bold text-white">{alert.customer?.name || 'Unknown'}</h2>
            <SeverityBadge severity={alert.severity} />
            <StatusBadge status={alert.status} />
          </div>
          <p className="text-sm text-slate-500 mt-1 font-mono">{alert.id}</p>
        </div>
        <div className="flex items-center gap-2">
          <StatusButton status="under_review" label="Mark Reviewing" color="bg-purple-500/15 text-purple-400 border-purple-500/30 hover:bg-purple-500/25" />
          <StatusButton status="sar_filed" label="Mark SAR Filed" color="bg-emerald-500/15 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/25" />
          <StatusButton status="dismissed" label="Dismiss" color="bg-slate-500/15 text-slate-400 border-slate-500/30 hover:bg-slate-500/25" />
        </div>
      </div>

      <div className="bg-slate-900/30 border border-slate-800/50 rounded-xl p-4 mb-6">
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 rounded-lg bg-amber-500/15 flex items-center justify-center flex-shrink-0 mt-0.5">
            <svg className="w-4 h-4 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />
            </svg>
          </div>
          <div>
            <p className="text-xs font-semibold text-amber-400 uppercase tracking-wider">{alert.ruleTriggered?.replace(/_/g, ' ')}</p>
            <p className="text-sm text-slate-400 mt-1 leading-relaxed">{ruleDescriptions[alert.ruleTriggered] || 'Suspicious activity detected.'}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-4 space-y-6">
          <CustomerCard customer={alert.customer} />
          <div className="bg-slate-900/50 border border-slate-800/50 rounded-xl p-5">
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Alert Summary</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Total Flagged</span>
                <span className="text-sm font-mono font-bold text-white">
                  ${Number(alert.totalFlaggedAmount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Transactions</span>
                <span className="text-sm font-mono text-slate-300">{alert.flaggedTransactions?.length || 0}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Detected</span>
                <span className="text-xs font-mono text-slate-300">
                  {alert.detectionDate ? new Date(alert.detectionDate).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }) : 'N/A'}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="col-span-8 space-y-6">
          <div className="bg-slate-900/50 border border-slate-800/50 rounded-xl p-5">
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-4">Flagged Transactions</h3>
            <TransactionTimeline transactions={alert.flaggedTransactions} />
          </div>
          <NarrativeEditor alertId={id} />
        </div>
      </div>
    </div>
  );
}
