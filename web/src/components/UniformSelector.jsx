import { motion } from 'framer-motion'
import { Shirt, X, Briefcase, Star } from 'lucide-react'
import { fetchNUI } from '../nui.js'

export default function UniformSelector({ uniforms, jobData, onClose, addToast }) {
  const handleApply = async (uniform) => {
    await fetchNUI('applyUniform', { uniformId: uniform.id })
    addToast(`Applied: ${uniform.uniform_name}`, 'success')
  }

  const jobLabel = jobData?.label || jobData?.name || 'Unknown'
  const gradeLabel = jobData?.gradeLabel || `Grade ${jobData?.grade ?? ''}`

  return (
    <div
      className="glass-panel"
      style={{ width: 340, maxHeight: '75vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}
    >
      {/* Header */}
      <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 38, height: 38, borderRadius: 10,
          background: 'linear-gradient(135deg, #4f9eff 0%, #7c3aed 100%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <Shirt size={18} color="#fff" />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 16, fontWeight: 700 }}>Job Clothing</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 3 }}>
            <span className="badge badge-blue" style={{ fontSize: 10 }}>
              <Briefcase size={9} style={{ marginRight: 3 }} />{jobLabel}
            </span>
            <span className="badge badge-blue" style={{ fontSize: 10 }}>
              <Star size={9} style={{ marginRight: 3 }} />{gradeLabel}
            </span>
          </div>
        </div>
        <button className="btn btn-ghost btn-icon" onClick={onClose}><X size={15} /></button>
      </div>

      {/* Uniform list */}
      <div style={{ flex: 1, overflowY: 'auto', padding: 12 }}>
        {uniforms.length === 0 ? (
          <div className="empty-state">
            <Shirt size={32} />
            <div>No uniforms available</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {uniforms.map((u, i) => (
              <motion.button
                key={u.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.05 }}
                style={{
                  width: '100%', padding: '12px 14px',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius)',
                  cursor: 'pointer', color: 'var(--text-primary)',
                  display: 'flex', alignItems: 'center', gap: 12,
                  transition: 'all 0.15s',
                  textAlign: 'left',
                }}
                onClick={() => handleApply(u)}
                whileHover={{ scale: 1.01, borderColor: 'var(--accent)', background: 'var(--accent-dim)' }}
                whileTap={{ scale: 0.98 }}
              >
                <div style={{
                  width: 36, height: 36, borderRadius: 8,
                  background: 'var(--bg-panel)',
                  border: '1px solid var(--border)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  <Shirt size={16} color="var(--accent)" />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{u.uniform_name}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>
                    {jobLabel} · Grade {u.job_grade}
                  </div>
                </div>
              </motion.button>
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div style={{ padding: '10px 14px', borderTop: '1px solid var(--border)' }}>
        <button className="btn btn-ghost w-full" style={{ justifyContent: 'center' }} onClick={onClose}>
          Close
        </button>
      </div>
    </div>
  )
}
