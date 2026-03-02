import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchAlerts } from '../api/client';
import SeverityBadge from '../components/SeverityBadge';
import StatusBadge from '../components/StatusBadge';

const ruleLabels = {
  STRUCTURING: 'Structuring',
  HIGH_RISK_JURISDICTION: 'High-Risk Jurisdiction',
  RAPID_FUND_MOVEMENT: 'Rapid Fund Movement',
  VOLUME_SPIKE: 'Volume Spike',
  LARGE_CASH: 'Large Cash',
};

export default function AlertQueue() {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [severityFilter, setSeverityFilter] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    loadAlerts();
  }, [statusFilter, severityFilter]);

  const loadAlerts = async () => {
    setLoading(true);
    try {
      const data = await fetchAlerts(statusFilter || null, severityFilter || null);
      setAlerts(data);
    } catch (e) {
      console.error('Failed to load alerts:', e);
    } finally {
      setLoading(false);
    }
  };

  const FilterButton = ({ label, value, current, setter }) => (
    <button
      onClick={() => setter(current === value ? '' : value)}
      className={`px-3 py-1.5 text-xs font-medium rounded-lg border transition-all duration-200 ${
        current === value
          ? 'bg-amber-500/15 text-amber-400 border-amber-500/30'
          : 'bg-slate-900/50 text-slate-400 border-slate-800/50 hover:text-slate-200 hover:border-slate-700'
      }`}
    >
      {label}
    </button>
  );

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-white">Alert Queue</h2>
          <p className="text-sm text-slate-500 mt-0.5">{alerts.length} alerts found</p>
        </div>
      </div>

      <div className="flex flex-wrap gap-2 mb-5">
        <span className="text-[10px] text-slate-500 uppercase tracking-wider self-center mr-2">Status</span>
        <FilterButton label="New" value="new" current={statusFilter} setter={setStatusFilter} />
        <FilterButton label="Reviewing" value="under_review" current={statusFilter} setter={setStatusFilter} />
        <FilterButton label="SAR Filed" value="sar_filed" current={statusFilter} setter={setStatusFilter} />
        <FilterButton label="Dismissed" value="dismissed" current={statusFilter} setter={setStatusFilter} />
        <div className="w-px h-6 bg-slate-800 self-center mx-2" />
        <span className="text-[10px] text-slate-500 uppercase tracking-wider self-center mr-2">Severity</span>
        <FilterButton label="High" value="high" current={severityFilter} setter={setSeverityFilter} />
        <FilterButton label="Medium" value="medium" current={severityFilter} setter={setSeverityFilter} />
        <FilterButton label="Low" value="low" current={severityFilter} setter={setSeverityFilter} />
      </div>

      <div className="bg-slate-900/30 border border-slate-800/50 rounded-xl overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-800/50">
              <th className="px-5 py-3 text-left text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Customer</th>
              <th className="px-5 py-3 text-left text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Rule Triggered</th>
              <th className="px-5 py-3 text-left text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Severity</th>
              <th className="px-5 py-3 text-right text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Amount</th>
              <th className="px-5 py-3 text-left text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Status</th>
              <th className="px-5 py-3 text-left text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Date</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} className="px-5 py-12 text-center">
                  <svg className="w-6 h-6 animate-spin mx-auto text-amber-500" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                </td>
              </tr>
            ) : alerts.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-5 py-12 text-center text-sm text-slate-500">No alerts match current filters</td>
              </tr>
            ) : (
              alerts.map((alert) => (
                <tr
                  key={alert.id}
                  onClick={() => navigate(`/alert/${alert.id}`)}
                  className="border-b border-slate-800/30 hover:bg-slate-800/20 cursor-pointer transition-colors group"
                >
                  <td className="px-5 py-3.5">
                    <p className="text-sm font-medium text-slate-200 group-hover:text-white transition-colors">{alert.customer?.name || 'Unknown'}</p>
                    <p className="text-[10px] text-slate-500 font-mono mt-0.5">{alert.customer?.accountNumber || ''}</p>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className="text-xs text-slate-300 font-medium">{ruleLabels[alert.ruleTriggered] || alert.ruleTriggered}</span>
                  </td>
                  <td className="px-5 py-3.5"><SeverityBadge severity={alert.severity} /></td>
                  <td className="px-5 py-3.5 text-right">
                    <span className="text-sm font-mono font-semibold text-white">
                      ${Number(alert.totalFlaggedAmount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </span>
                  </td>
                  <td className="px-5 py-3.5"><StatusBadge status={alert.status} /></td>
                  <td className="px-5 py-3.5">
                    <span className="text-xs text-slate-500 font-mono">
                      {alert.detectionDate ? new Date(alert.detectionDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : ''}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
