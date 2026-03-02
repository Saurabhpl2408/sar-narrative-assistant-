import React, { useState, useEffect } from 'react';
import { generateNarrative, fetchNarratives, updateNarrative } from '../api/client';

export default function NarrativeEditor({ alertId }) {
  const [narratives, setNarratives] = useState([]);
  const [currentText, setCurrentText] = useState('');
  const [currentId, setCurrentId] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [edited, setEdited] = useState(false);

  useEffect(() => {
    loadNarratives();
  }, [alertId]);

  const loadNarratives = async () => {
    try {
      const data = await fetchNarratives(alertId);
      setNarratives(data);
      if (data.length > 0) {
        setCurrentText(data[0].narrative_text);
        setCurrentId(data[0].id);
        setEdited(false);
      }
    } catch (e) {
      console.error('Failed to load narratives:', e);
    }
  };

  const handleGenerate = async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await generateNarrative(alertId);
      setCurrentText(result.narrative_text);
      setCurrentId(result.id);
      setEdited(false);
      await loadNarratives();
    } catch (e) {
      setError('Failed to generate narrative. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!currentId) return;
    setSaving(true);
    try {
      await updateNarrative(currentId, currentText);
      setEdited(false);
      await loadNarratives();
    } catch (e) {
      setError('Failed to save changes.');
    } finally {
      setSaving(false);
    }
  };

  const handleTextChange = (e) => {
    setCurrentText(e.target.value);
    setEdited(true);
  };

  const selectVersion = (narrative) => {
    setCurrentText(narrative.narrative_text);
    setCurrentId(narrative.id);
    setEdited(false);
  };

  return (
    <div className="bg-slate-900/50 border border-slate-800/50 rounded-xl overflow-hidden">
      <div className="px-5 py-4 border-b border-slate-800/50 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h3 className="text-sm font-semibold text-white">SAR Narrative</h3>
          {narratives.length > 0 && (
            <span className="text-[10px] text-slate-500 font-mono">
              v{narratives[0]?.version || 1} &middot; {narratives[0]?.llm_model || 'unknown'}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          {edited && (
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-3 py-1.5 text-xs font-medium rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/30 transition-colors disabled:opacity-50"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          )}
          <button
            onClick={handleGenerate}
            disabled={loading}
            className="px-3 py-1.5 text-xs font-medium rounded-lg bg-amber-500/20 text-amber-400 border border-amber-500/30 hover:bg-amber-500/30 transition-colors disabled:opacity-50 flex items-center gap-1.5"
          >
            {loading ? (
              <>
                <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Generating...
              </>
            ) : (
              <>
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09Z" />
                </svg>
                {narratives.length > 0 ? 'Regenerate' : 'Generate Narrative'}
              </>
            )}
          </button>
        </div>
      </div>

      {error && (
        <div className="px-5 py-2 bg-red-500/10 border-b border-red-500/20">
          <p className="text-xs text-red-400">{error}</p>
        </div>
      )}

      <div className="p-5">
        {currentText ? (
          <textarea
            value={currentText}
            onChange={handleTextChange}
            rows={14}
            className="w-full bg-slate-950/50 border border-slate-800/50 rounded-lg p-4 text-sm text-slate-300 leading-relaxed resize-y focus:outline-none focus:border-amber-500/30 focus:ring-1 focus:ring-amber-500/20 font-sans"
          />
        ) : (
          <div className="text-center py-12">
            <svg className="w-12 h-12 mx-auto text-slate-700 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
            </svg>
            <p className="text-sm text-slate-500">No narrative generated yet</p>
            <p className="text-xs text-slate-600 mt-1">Click "Generate Narrative" to create a SAR draft</p>
          </div>
        )}
      </div>

      {narratives.length > 1 && (
        <div className="px-5 pb-4 border-t border-slate-800/50 pt-3">
          <p className="text-[10px] text-slate-500 uppercase tracking-wider mb-2">Version History</p>
          <div className="flex gap-2 flex-wrap">
            {narratives.map((n) => (
              <button
                key={n.id}
                onClick={() => selectVersion(n)}
                className={`px-2.5 py-1 text-[10px] font-mono rounded-md border transition-colors ${
                  n.id === currentId
                    ? 'bg-amber-500/15 text-amber-400 border-amber-500/30'
                    : 'bg-slate-800/50 text-slate-500 border-slate-700/50 hover:text-slate-300'
                }`}
              >
                v{n.version} &middot; {n.generated_by}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
