import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Plus, Trash2, Edit2, Eye, EyeOff, Search, Shirt, Briefcase, ChevronDown, ChevronRight, Save, X } from 'lucide-react'
import ConfirmDialog from './ConfirmDialog.jsx'
import { fetchNUI } from '../nui.js'

export default function UniformManager({ ped, addToast }) {
  const [uniforms, setUniforms]         = useState([])
  const [jobs, setJobs]                 = useState([])
  const [loading, setLoading]           = useState(true)
  const [searchUniform, setSearchUniform] = useState('')
  const [showCreate, setShowCreate]     = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(null)
  const [editingUniform, setEditingUniform] = useState(null)
  const [previewing, setPreviewing]     = useState(null)

  // Create form state
  const [selectedJob, setSelectedJob]   = useState('')
  const [selectedGrade, setSelectedGrade] = useState('')
  const [uniformName, setUniformName]   = useState('')
  const [grades, setGrades]             = useState([])
  const [creating, setCreating]         = useState(false)
  const [pendingOutfit, setPendingOutfit] = useState(null)

  useEffect(() => {
    setLoading(true)
    setUniforms([])
    setShowCreate(false)
    Promise.all([
      fetchNUI('getUniformsForPed', { pedId: ped.id }),
      fetchNUI('getJobs'),
    ]).then(([u, j]) => {
      setUniforms(u || [])
      setJobs(j || [])
      setLoading(false)
    })
  }, [ped.id])

  useEffect(() => {
    if (!selectedJob) { setGrades([]); return }
    fetchNUI('getGrades', { job: selectedJob }).then(setGrades)
  }, [selectedJob])

  const filtered = uniforms.filter(u =>
    u.uniform_name?.toLowerCase().includes(searchUniform.toLowerCase()) ||
    u.job_name?.toLowerCase().includes(searchUniform.toLowerCase())
  )

  // Group by job_name
  const grouped = filtered.reduce((acc, u) => {
    const key = u.job_name
    acc[key] = acc[key] || []
    acc[key].push(u)
    return acc
  }, {})

  const handleOpenEditor = async () => {
    const result = await fetchNUI('openClothingEditor', {})
    if (result?.success && result.outfitData) {
      setPendingOutfit(result.outfitData)
      addToast('Outfit captured. Fill in the details and save.', 'info')
    } else if (!result?.success) {
      addToast(result?.error || 'Clothing editor cancelled', 'error')
    }
  }

  const handlePreview = async (uniform) => {
    if (previewing === uniform.id) {
      await fetchNUI('restoreClothing', {})
      setPreviewing(null)
    } else {
      await fetchNUI('previewUniform', { outfitData: uniform.outfit_data })
      setPreviewing(uniform.id)
    }
  }

  const handleCreate = async () => {
    if (!selectedJob || selectedGrade === '' || !uniformName.trim() || !pendingOutfit) return
    setCreating(true)
    try {
      const result = await fetchNUI('createUniform', {
        pedId: ped.id,
        job: selectedJob,
        grade: parseInt(selectedGrade),
        name: uniformName.trim(),
        outfitData: pendingOutfit,
      })
      if (result?.id) {
        setUniforms(prev => [...prev, result])
        setShowCreate(false)
        setSelectedJob(''); setSelectedGrade(''); setUniformName(''); setPendingOutfit(null)
        addToast('Uniform created!', 'success')
      } else {
        addToast('Failed to save uniform', 'error')
      }
    } finally {
      setCreating(false)
    }
  }

  const handleDelete = async (uniform) => {
    setConfirmDelete(null)
    if (previewing === uniform.id) { await fetchNUI('restoreClothing', {}); setPreviewing(null) }
    const result = await fetchNUI('deleteUniform', { id: uniform.id })
    if (result?.success) {
      setUniforms(prev => prev.filter(u => u.id !== uniform.id))
      addToast('Uniform deleted', 'info')
    } else {
      addToast('Failed to delete uniform', 'error')
    }
  }

  const handleUpdateName = async (uniform, newName) => {
    const result = await fetchNUI('updateUniform', { id: uniform.id, name: newName, outfitData: uniform.outfit_data })
    if (result?.success) {
      setUniforms(prev => prev.map(u => u.id === uniform.id ? { ...u, uniform_name: newName } : u))
      setEditingUniform(null)
      addToast('Uniform updated', 'success')
    }
  }

  const jobLabel = (name) => jobs.find(j => j.name === name)?.label || name
  const gradeLabel = (jobName, grade) => {
    const job = jobs.find(j => j.name === jobName)
    return job?.grades?.find(g => g.grade === grade)?.label || `Grade ${grade}`
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <div style={{ padding: '12px 16px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <Shirt size={15} color="var(--accent)" />
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 600, fontSize: 14 }}>{ped.label || ped.model}</div>
          <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontFamily: 'monospace' }}>{ped.model}</div>
        </div>
        <button className="btn btn-primary btn-sm" onClick={() => setShowCreate(!showCreate)}>
          <Plus size={13} /> Add Uniform
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
            <div style={{ padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div className="section-label">Create Uniform</div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                {/* Job select */}
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginBottom: 4 }}>Job</div>
                  <select
                    className="input"
                    value={selectedJob}
                    onChange={e => { setSelectedJob(e.target.value); setSelectedGrade('') }}
                    style={{ appearance: 'none' }}
                  >
                    <option value="">Select job...</option>
                    {jobs.map(j => <option key={j.name} value={j.name}>{j.label}</option>)}
                  </select>
                </div>

                {/* Grade select */}
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginBottom: 4 }}>Grade / Rank</div>
                  <select
                    className="input"
                    value={selectedGrade}
                    onChange={e => setSelectedGrade(e.target.value)}
                    disabled={!selectedJob}
                    style={{ appearance: 'none' }}
                  >
                    <option value="">Select grade...</option>
                    {grades.map(g => <option key={g.grade} value={g.grade}>{g.label} (#{g.grade})</option>)}
                  </select>
                </div>
              </div>

              {/* Name */}
              <div>
                <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginBottom: 4 }}>Uniform Name</div>
                <input className="input" placeholder="e.g. Patrol, Tactical, Winter..." value={uniformName} onChange={e => setUniformName(e.target.value)} />
              </div>

              {/* Outfit capture */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <button className="btn btn-ghost btn-sm flex-1" onClick={handleOpenEditor}>
                  <Shirt size={13} />
                  {pendingOutfit ? '✓ Outfit Captured — Recapture' : 'Open Clothing Editor'}
                </button>
                {pendingOutfit && (
                  <span className="badge badge-green">Ready</span>
                )}
              </div>

              <div style={{ display: 'flex', gap: 6 }}>
                <button className="btn btn-ghost btn-sm flex-1" onClick={() => { setShowCreate(false); setPendingOutfit(null) }}>Cancel</button>
                <button
                  className="btn btn-primary btn-sm flex-1"
                  onClick={handleCreate}
                  disabled={creating || !selectedJob || selectedGrade === '' || !uniformName.trim() || !pendingOutfit}
                >
                  {creating ? <span className="spinner" style={{ width: 12, height: 12 }} /> : 'Save Uniform'}
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search */}
      <div style={{ padding: '8px 14px', borderBottom: '1px solid var(--border)' }}>
        <div style={{ position: 'relative' }}>
          <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input className="input" style={{ paddingLeft: 30, paddingTop: 7, paddingBottom: 7 }} placeholder="Search uniforms..." value={searchUniform} onChange={e => setSearchUniform(e.target.value)} />
        </div>
      </div>

      {/* Uniform list */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 14px' }}>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 24 }}><div className="spinner" /></div>
        ) : Object.keys(grouped).length === 0 ? (
          <div className="empty-state">
            <Shirt size={36} />
            <div style={{ fontWeight: 600 }}>No uniforms yet</div>
            <div style={{ fontSize: 12 }}>Use "Add Uniform" to configure outfits for this ped.</div>
          </div>
        ) : (
          Object.entries(grouped).map(([jobName, jobUniforms]) => (
            <JobGroup
              key={jobName}
              jobName={jobName}
              jobLabel={jobLabel(jobName)}
              uniforms={jobUniforms}
              gradeLabel={(g) => gradeLabel(jobName, g)}
              previewing={previewing}
              editingUniform={editingUniform}
              onPreview={handlePreview}
              onEdit={setEditingUniform}
              onUpdateName={handleUpdateName}
              onDelete={setConfirmDelete}
            />
          ))
        )}
      </div>

      <AnimatePresence>
        {confirmDelete && (
          <ConfirmDialog
            message={`Delete "${confirmDelete.uniform_name}"?`}
            subtext="This cannot be undone."
            dangerous
            onConfirm={() => handleDelete(confirmDelete)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function JobGroup({ jobName, jobLabel, uniforms, gradeLabel, previewing, editingUniform, onPreview, onEdit, onUpdateName, onDelete }) {
  const [open, setOpen] = useState(true)

  // Sort by grade
  const sorted = [...uniforms].sort((a, b) => a.job_grade - b.job_grade)

  return (
    <div style={{ marginBottom: 10 }}>
      <button
        style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 8, background: 'none', border: 'none', cursor: 'pointer', padding: '6px 4px', color: 'var(--text-primary)' }}
        onClick={() => setOpen(o => !o)}
      >
        {open ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
        <Briefcase size={13} color="var(--accent)" />
        <span style={{ fontWeight: 600, fontSize: 13 }}>{jobLabel}</span>
        <span className="badge badge-blue" style={{ marginLeft: 'auto' }}>{uniforms.length}</span>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            style={{ overflow: 'hidden' }}
          >
            {sorted.map(u => (
              <UniformRow
                key={u.id}
                uniform={u}
                gradeLabel={gradeLabel(u.job_grade)}
                previewing={previewing === u.id}
                editing={editingUniform?.id === u.id}
                onPreview={() => onPreview(u)}
                onEdit={() => onEdit(u)}
                onCancelEdit={() => onEdit(null)}
                onSaveName={(name) => onUpdateName(u, name)}
                onDelete={() => onDelete(u)}
              />
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

function UniformRow({ uniform, gradeLabel, previewing, editing, onPreview, onEdit, onCancelEdit, onSaveName, onDelete }) {
  const [editName, setEditName] = useState(uniform.uniform_name)

  return (
    <div className="card" style={{ marginLeft: 20, marginBottom: 5, padding: '8px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
      {editing ? (
        <input
          className="input"
          style={{ flex: 1, padding: '4px 8px', fontSize: 12 }}
          value={editName}
          onChange={e => setEditName(e.target.value)}
          autoFocus
          onKeyDown={e => {
            if (e.key === 'Enter') onSaveName(editName)
            if (e.key === 'Escape') onCancelEdit()
          }}
        />
      ) : (
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 500, fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {uniform.uniform_name}
          </div>
          <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 1 }}>
            {gradeLabel} · Grade {uniform.job_grade}
          </div>
        </div>
      )}

      <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
        {editing ? (
          <>
            <button className="btn btn-success btn-sm" onClick={() => onSaveName(editName)}><Save size={12} /></button>
            <button className="btn btn-ghost btn-sm" onClick={onCancelEdit}><X size={12} /></button>
          </>
        ) : (
          <>
            <button
              className={`btn btn-sm ${previewing ? 'btn-success' : 'btn-ghost'}`}
              title={previewing ? 'Stop Preview' : 'Preview'}
              onClick={onPreview}
            >
              {previewing ? <EyeOff size={12} /> : <Eye size={12} />}
            </button>
            <button className="btn btn-ghost btn-sm" title="Rename" onClick={onEdit}><Edit2 size={12} /></button>
            <button className="btn btn-danger btn-sm" title="Delete" onClick={onDelete}><Trash2 size={12} /></button>
          </>
        )}
      </div>
    </div>
  )
}
