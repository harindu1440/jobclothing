import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, Shirt, Briefcase, Users, ChevronRight, Trash2, Edit2, MapPin, Plus, User, Search } from 'lucide-react'
import PedList from './PedList.jsx'
import UniformManager from './UniformManager.jsx'
import { fetchNUI } from '../nui.js'

const TABS = [
  { id: 'peds', label: 'Clothing Peds', icon: User },
]

export default function AdminPanel({ onClose, addToast }) {
  const [tab, setTab]               = useState('peds')
  const [peds, setPeds]             = useState([])
  const [loading, setLoading]       = useState(true)
  const [selectedPed, setSelectedPed] = useState(null)
  const [systemInfo, setSystemInfo] = useState(null)

  useEffect(() => {
    Promise.all([
      fetchNUI('getPeds'),
      fetchNUI('getSystemInfo'),
    ]).then(([p, info]) => {
      setPeds(p || [])
      setSystemInfo(info)
      setLoading(false)
    })
  }, [])

  const handlePedCreated = (ped) => {
    setPeds(prev => [...prev, ped])
    addToast('Ped created successfully', 'success')
  }

  const handlePedDeleted = (id) => {
    setPeds(prev => prev.filter(p => p.id !== id))
    if (selectedPed?.id === id) setSelectedPed(null)
    addToast('Ped deleted', 'info')
  }

  const handlePedUpdated = (updatedPed) => {
    setPeds(prev => prev.map(p => p.id === updatedPed.id ? updatedPed : p))
    addToast('Ped updated', 'success')
  }

  return (
    <div className="glass-panel" style={{ width: 860, maxHeight: '85vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {/* Header */}
      <div style={{ padding: '18px 20px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: 'linear-gradient(135deg, #4f9eff 0%, #7c3aed 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Shirt size={18} color="#fff" />
          </div>
          <div>
            <h2 style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>Job Clothing</h2>
            <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 1 }}>
              {systemInfo ? `Clothing: ${systemInfo.clothing}` : 'Loading...'}
            </div>
          </div>
        </div>

        {/* System info badges */}
        {systemInfo && (
          <div style={{ display: 'flex', gap: 6 }}>
            <span className="badge badge-blue" style={{ fontSize: 10 }}>
              {systemInfo.clothing}
            </span>
          </div>
        )}

        <button className="btn btn-ghost btn-icon" onClick={onClose} title="Close">
          <X size={16} />
        </button>
      </div>

      {/* Content: two-column layout */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* Left: Ped list */}
        <div style={{ width: 300, borderRight: '1px solid var(--border)', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          <PedList
            peds={peds}
            loading={loading}
            selectedPed={selectedPed}
            onSelectPed={setSelectedPed}
            onPedCreated={handlePedCreated}
            onPedDeleted={handlePedDeleted}
            onPedUpdated={handlePedUpdated}
            addToast={addToast}
          />
        </div>

        {/* Right: Uniform manager */}
        <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
          <AnimatePresence mode="wait">
            {selectedPed ? (
              <motion.div
                key={selectedPed.id}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.15 }}
                style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}
              >
                <UniformManager
                  ped={selectedPed}
                  addToast={addToast}
                />
              </motion.div>
            ) : (
              <motion.div
                key="empty"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <div className="empty-state">
                  <Shirt size={40} />
                  <div style={{ fontSize: 15, fontWeight: 600 }}>Select a ped</div>
                  <div style={{ fontSize: 12, maxWidth: 200 }}>
                    Choose a clothing ped from the left panel to manage its uniforms.
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  )
}
