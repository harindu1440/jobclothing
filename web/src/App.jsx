import { useState, useEffect, useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import AdminPanel from './components/AdminPanel.jsx'
import UniformSelector from './components/UniformSelector.jsx'
import Toast from './components/Toast.jsx'
import { fetchNUI } from './nui.js'

export default function App() {
  const [visible, setVisible]       = useState(false)
  const [mode, setMode]             = useState('admin')   // 'admin' | 'player'
  const [uniforms, setUniforms]     = useState([])
  const [jobData, setJobData]       = useState(null)
  const [toasts, setToasts]         = useState([])
  const [placementMode, setPlacement] = useState(false)

  // ── Toast system ──────────────────────────────────────────
  const addToast = useCallback((message, type = 'info') => {
    const id = Date.now()
    setToasts(t => [...t, { id, message, type }])
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 4000)
  }, [])

  // ── NUI message handler ───────────────────────────────────
  useEffect(() => {
    const handler = (event) => {
      const { type, payload } = event.data
      switch (type) {
        case 'open':
          if (payload.admin === false) {
            setMode('player')
            setUniforms(payload.uniforms || [])
            setJobData(payload.jobData || null)
          } else {
            setMode('admin')
          }
          setVisible(true)
          break
        case 'close':
          setVisible(false)
          break
        case 'placementStarted':
        case 'editorStarted':
          setPlacement(true)
          setVisible(false)
          break
        case 'placementFinished':
        case 'placementCancelled':
        case 'editorFinished':
          setPlacement(false)
          setVisible(true)
          break
        default:
          break
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  // ── Dev mode: auto-open ───────────────────────────────────
  useEffect(() => {
    const isDev = window.invokeNative === undefined && !navigator.userAgent.includes('FiveM')
    if (isDev) setVisible(true)
  }, [])

  // ── Escape to close ───────────────────────────────────────
  useEffect(() => {
    const handler = (e) => {
      if (e.key === 'Escape' && visible && !placementMode) {
        handleClose()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [visible, placementMode])

  const handleClose = async () => {
    await fetchNUI('close')
    setVisible(false)
  }

  if (!visible) return (
    <Toast toasts={toasts} />
  )

  return (
    <div className="nui-root" style={{ width: '100vw', height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'fixed', inset: 0, background: 'transparent', pointerEvents: 'none' }}>
      <AnimatePresence mode="wait">
        {mode === 'admin' ? (
          <motion.div
            key="admin"
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            style={{ position: 'relative', zIndex: 10, pointerEvents: 'auto' }}
          >
            <AdminPanel onClose={handleClose} addToast={addToast} />
          </motion.div>
        ) : (
          <motion.div
            key="player"
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            style={{ position: 'relative', zIndex: 10, pointerEvents: 'auto' }}
          >
            <UniformSelector
              uniforms={uniforms}
              jobData={jobData}
              onClose={handleClose}
              addToast={addToast}
            />
          </motion.div>
        )}
      </AnimatePresence>

      <div style={{ pointerEvents: 'auto' }}>
        <Toast toasts={toasts} />
      </div>
    </div>
  )
}
