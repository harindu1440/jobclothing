import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Plus, Search, User, Trash2, MapPin, Shirt, ChevronRight } from 'lucide-react'
import ConfirmDialog from './ConfirmDialog.jsx'
import { fetchNUI } from '../nui.js'

export default function PedList({ peds, loading, selectedPed, onSelectPed, onPedCreated, onPedDeleted, onPedUpdated, addToast }) {
  const [search, setSearch]         = useState('')
  const [showCreate, setShowCreate] = useState(false)
  const [createModel, setCreateModel] = useState('')
  const [createLabel, setCreateLabel] = useState('')
  const [creating, setCreating]     = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(null)

  const filtered = peds.filter(p =>
    p.label?.toLowerCase().includes(search.toLowerCase()) ||
    p.model?.toLowerCase().includes(search.toLowerCase())
  )

  const handleCreate = async () => {
    if (!createModel.trim()) return
    setCreating(true)
    try {
      const result = await fetchNUI('startPedPlacement', { model: createModel.trim(), label: createLabel.trim() || createModel.trim() })
      if (result?.ped) {
        onPedCreated(result.ped)
        setShowCreate(false)
        setCreateModel('')
        setCreateLabel('')
      } else if (!result?.cancelled) {
        addToast(result?.error || 'Failed to create ped', 'error')
      }
    } finally {
      setCreating(false)
    }
  }

  const handleDelete = async (ped) => {
    setConfirmDelete(null)
    const result = await fetchNUI('deletePed', { pedId: ped.id })
    if (result?.success) {
      onPedDeleted(ped.id)
    } else {
      addToast('Failed to delete ped', 'error')
    }
  }

  const handleTeleport = async (ped) => {
    await fetchNUI('teleportToPed', { pedId: ped.id })
    addToast(`Teleporting to ${ped.label}`, 'info')
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Search + Add */}
      <div style={{ padding: '12px 14px', borderBottom: '1px solid var(--border)' }}>
        <div style={{ position: 'relative', marginBottom: 8 }}>
          <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input
            className="input"
            style={{ paddingLeft: 30, paddingTop: 7, paddingBottom: 7 }}
            placeholder="Search peds..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <button className="btn btn-primary w-full" style={{ justifyContent: 'center' }} onClick={() => setShowCreate(!showCreate)}>
          <Plus size={14} />
          Create Clothing Ped
        </button>
      </div>

      {/* Create form */}
      <AnimatePresence>
        {showCreate && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            style={{ overflow: 'hidden', borderBottom: '1px solid var(--border)' }}
          >
            <div style={{ padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div className="section-label">New Clothing Ped</div>
              <input
                className="input"
                placeholder="Ped model (e.g. s_m_y_cop_01)"
                value={createModel}
                onChange={e => setCreateModel(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleCreate()}
              />
              <input
                className="input"
                placeholder="Label (e.g. Police Station)"
                value={createLabel}
                onChange={e => setCreateLabel(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleCreate()}
              />
              <div style={{ display: 'flex', gap: 6 }}>
                <button className="btn btn-ghost btn-sm flex-1" onClick={() => setShowCreate(false)}>Cancel</button>
                <button
                  className="btn btn-primary btn-sm flex-1"
                  onClick={handleCreate}
                  disabled={creating || !createModel.trim()}
                >
                  {creating ? <span className="spinner" style={{ width: 12, height: 12 }} /> : 'Place Ped'}
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Ped list */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px' }}>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 24 }}>
            <div className="spinner" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="empty-state" style={{ padding: 24 }}>
            <User size={28} />
            <div style={{ fontSize: 12 }}>No peds found</div>
          </div>
        ) : (
          <AnimatePresence>
            {filtered.map((ped, i) => (
              <motion.div
                key={ped.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ delay: i * 0.03 }}
                className={`card ${selectedPed?.id === ped.id ? 'selected' : ''}`}
                style={{ cursor: 'pointer', marginBottom: 6, padding: '10px 12px' }}
                onClick={() => onSelectPed(ped)}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{
                    width: 34, height: 34, borderRadius: 8,
                    background: selectedPed?.id === ped.id ? 'var(--accent-dim)' : 'var(--bg-panel)',
                    border: '1px solid var(--border)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0,
                  }}>
                    <User size={15} color={selectedPed?.id === ped.id ? 'var(--accent)' : 'var(--text-secondary)'} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {ped.label || ped.model}
                    </div>
                    <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 1, fontFamily: 'monospace' }}>
                      {ped.model}
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
                    <button
                      className="btn btn-ghost btn-icon"
                      style={{ padding: 5 }}
                      title="Teleport"
                      onClick={e => { e.stopPropagation(); handleTeleport(ped) }}
                    >
                      <MapPin size={13} />
                    </button>
                    <button
                      className="btn btn-danger btn-icon"
                      style={{ padding: 5 }}
                      title="Delete"
                      onClick={e => { e.stopPropagation(); setConfirmDelete(ped) }}
                    >
                      <Trash2 size={13} />
                    </button>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        )}
      </div>

      {/* Confirm delete dialog */}
      <AnimatePresence>
        {confirmDelete && (
          <ConfirmDialog
            message={`Delete "${confirmDelete.label || confirmDelete.model}"?`}
            subtext="This will also remove all associated uniforms."
            dangerous
            onConfirm={() => handleDelete(confirmDelete)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
