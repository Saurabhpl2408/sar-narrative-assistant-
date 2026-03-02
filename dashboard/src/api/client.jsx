const TXN_API = process.env.REACT_APP_TRANSACTION_API || 'http://localhost:8080';
const SAR_API = process.env.REACT_APP_SAR_ENGINE_API || 'http://localhost:8000';

export async function fetchAlerts(status, severity) {
  const params = new URLSearchParams();
  if (status) params.append('status', status);
  if (severity) params.append('severity', severity);
  const query = params.toString() ? `?${params.toString()}` : '';
  const res = await fetch(`${TXN_API}/api/alerts${query}`);
  if (!res.ok) throw new Error('Failed to fetch alerts');
  return res.json();
}

export async function fetchAlertById(id) {
  const res = await fetch(`${TXN_API}/api/alerts/${id}`);
  if (!res.ok) throw new Error('Failed to fetch alert');
  return res.json();
}

export async function updateAlertStatus(id, status) {
  const res = await fetch(`${TXN_API}/api/alerts/${id}/status`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });
  if (!res.ok) throw new Error('Failed to update alert status');
  return res.json();
}

export async function fetchDashboardStats() {
  const res = await fetch(`${TXN_API}/api/dashboard/stats`);
  if (!res.ok) throw new Error('Failed to fetch stats');
  return res.json();
}

export async function runScan(from, to) {
  const res = await fetch(`${TXN_API}/api/transactions/scan`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ from, to }),
  });
  if (!res.ok) throw new Error('Failed to run scan');
  return res.json();
}

export async function generateNarrative(alertId) {
  const res = await fetch(`${SAR_API}/api/generate-narrative`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ alert_id: alertId }),
  });
  if (!res.ok) throw new Error('Failed to generate narrative');
  return res.json();
}

export async function fetchNarratives(alertId) {
  const res = await fetch(`${SAR_API}/api/narratives/${alertId}`);
  if (!res.ok) throw new Error('Failed to fetch narratives');
  return res.json();
}

export async function updateNarrative(narrativeId, narrativeText) {
  const res = await fetch(`${SAR_API}/api/narratives/${narrativeId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ narrative_text: narrativeText }),
  });
  if (!res.ok) throw new Error('Failed to update narrative');
  return res.json();
}
