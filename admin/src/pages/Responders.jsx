import { useEffect, useState } from 'react'
import { api, suspendUser, unsuspendUser, createResponder } from '../services/api'
import { motion } from 'framer-motion'
import { Users, Plus, Shield, ShieldAlert, Phone, Mail, User } from 'lucide-react'
import toast from 'react-hot-toast'
import './Responders.css'
import '../pages/Dashboard.css'

const TYPE_COLOR = { medical: 'blue', crime: 'red' }

function timeAgo(d) {
  const diff = Date.now() - new Date(d)
  const m = Math.floor(diff / 60000)
  if (m < 1) return 'Just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return new Date(d).toLocaleDateString()
}

export default function Responders() {
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [actionLoading, setActionLoading] = useState(null)

  // Registration Form state
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [responderType, setResponderType] = useState('medical')
  const [registering, setRegistering] = useState(false)

  const fetchResponders = () => {
    api.get('/api/auth/users?role=responder')
      .then(res => setResponders(res.data?.users || res.data || []))
      .catch(err => {
        setError(err.response?.data?.message || 'Failed to load responders')
        toast.error('Failed to load responders')
      })
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchResponders() }, [])

  const handleRegister = async (e) => {
    e.preventDefault()
    if (!name || !email || !password || !responderType) {
      toast.error('Please fill in all required fields.')
      return
    }
    setRegistering(true)
    try {
      const res = await createResponder({ name, email, password, phone, responderType })
      toast.success(res.data?.message || 'Responder registered successfully! 🎉')
      setName('')
      setEmail('')
      setPassword('')
      setPhone('')
      setResponderType('medical')
      fetchResponders()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Registration failed')
    } finally {
      setRegistering(false)
    }
  }

  const handleSuspend = async (id, name) => {
    if (!window.confirm(`Suspend "${name}"? They will not be able to log in.`)) return
    setActionLoading(id)
    try {
      await suspendUser(id)
      toast.success(`${name} has been suspended`)
      setResponders(prev => prev.map(r => r._id === id ? { ...r, isSuspended: true } : r))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to suspend')
    } finally {
      setActionLoading(null)
    }
  }

  const handleUnsuspend = async (id, name) => {
    setActionLoading(id)
    try {
      await unsuspendUser(id)
      toast.success(`${name} has been reinstated`)
      setResponders(prev => prev.map(r => r._id === id ? { ...r, isSuspended: false } : r))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to unsuspend')
    } finally {
      setActionLoading(null)
    }
  }

  const filtered = responders.filter(r => {
    const q = search.toLowerCase()
    const matchSearch = !q || r.name?.toLowerCase().includes(q) || r.email?.toLowerCase().includes(q) || r.responderType?.toLowerCase().includes(q)
    const matchType = typeFilter === 'all' || r.responderType === typeFilter
    return matchSearch && matchType
  })

  const medCount = responders.filter(r => r.responderType === 'medical').length
  const crimeCount = responders.filter(r => r.responderType === 'crime').length

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Responders</h1>
          <p className="page-subtitle">Manage emergency responders — register and monitor personnel in your zone</p>
        </div>
        <div className="responders-count">
          <Users size={14} style={{ marginRight: 6 }} />
          {responders.length} Registered
        </div>
      </div>

      {error && <div className="dashboard-error" style={{marginBottom:20}}>{error}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.3fr', gap: 24, alignItems: 'start' }} className="responders-layout-grid">
        {/* Form Card */}
        <div style={{ background: 'var(--bg-card)', border: '1.5px solid rgba(79,110,247,0.2)', borderRadius: 'var(--radius-lg)', padding: 24 }}>
          <h2 style={{ fontSize: 17, fontWeight: 700, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <Plus size={18} /> Register New Responder
          </h2>
          <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 20 }}>
            Create credentials for a new emergency responder. Login details will be emailed to them immediately.
          </p>

          <form onSubmit={handleRegister} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>Full Name *</label>
              <input
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="e.g. Officer Ahmed"
                required
                style={{ background: 'var(--bg-secondary)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-primary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontSize: 14 }}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>Email Address *</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="e.g. responder@safetrack.pk"
                required
                style={{ background: 'var(--bg-secondary)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-primary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontSize: 14 }}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>Password *</label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                style={{ background: 'var(--bg-secondary)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-primary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontSize: 14 }}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>Phone Number</label>
              <input
                type="text"
                value={phone}
                onChange={e => setPhone(e.target.value)}
                placeholder="e.g. +923001234567"
                style={{ background: 'var(--bg-secondary)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-primary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontSize: 14 }}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)' }}>Responder Type *</label>
              <select
                value={responderType}
                onChange={e => setResponderType(e.target.value)}
                required
                style={{ background: 'var(--bg-secondary)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-primary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontSize: 14, cursor: 'pointer' }}
              >
                <option value="medical">🏥 Medical / Ambulance</option>
                <option value="crime">🚔 Crime / Police</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={registering}
              style={{
                marginTop: 8,
                padding: '11px 22px',
                borderRadius: 'var(--radius-md)',
                background: 'var(--accent-primary)',
                color: '#fff',
                fontWeight: 700,
                cursor: 'pointer',
                border: 'none',
                fontFamily: 'var(--font)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 8,
                transition: 'opacity 0.2s'
              }}
            >
              {registering ? 'Registering...' : (
                <>
                  <Plus size={16} /> Register Responder
                </>
              )}
            </button>
          </form>
        </div>

        {/* List Card */}
        <div>
          {/* Type Filter Tabs */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
            {[
              { key: 'all',     label: 'All',           count: responders.length },
              { key: 'medical', label: '🏥 Medical',     count: medCount },
              { key: 'crime',   label: '🚔 Crime',       count: crimeCount },
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setTypeFilter(tab.key)}
                style={{
                  padding: '6px 16px',
                  borderRadius: 999,
                  border: typeFilter === tab.key ? '1.5px solid var(--accent-primary)' : '1.5px solid rgba(255,255,255,0.1)',
                  background: typeFilter === tab.key ? 'rgba(79,110,247,0.18)' : 'transparent',
                  color: typeFilter === tab.key ? 'var(--accent-primary)' : 'var(--text-secondary)',
                  fontWeight: 600,
                  fontSize: 13,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  transition: 'all 0.18s'
                }}
              >
                {tab.label}
                <span style={{
                  background: typeFilter === tab.key ? 'var(--accent-primary)' : 'rgba(255,255,255,0.1)',
                  color: typeFilter === tab.key ? '#fff' : 'var(--text-muted)',
                  borderRadius: 999, padding: '1px 7px', fontSize: 11, fontWeight: 700
                }}>{tab.count}</span>
              </button>
            ))}
          </div>

          {/* Search */}
          <div style={{ marginBottom: 16 }}>
            <div className="search-wrap" style={{ marginLeft: 0, width: '100%' }}>
              <svg className="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input className="search-input" style={{ width: '100%' }} placeholder="Search responders..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
          </div>

          {loading ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {[1, 2, 3].map(i => <div key={i} className="responder-card shimmer" style={{ height: 160 }} />)}
            </div>
          ) : filtered.length === 0 ? (
            <div className="dashboard-section">
              <div className="empty-state">
                {responders.length === 0 ? 'No responders registered yet.' : 'No responders match your search.'}
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {filtered.map(r => {
                const typeColor = TYPE_COLOR[r.responderType] || 'green'
                const isBusy = actionLoading === r._id
                return (
                  <div key={r._id} className={`responder-card ${r.isSuspended ? 'responder-card--suspended' : ''}`} style={{ margin: 0 }}>
                    {r.isSuspended && (
                      <div className="suspension-banner">
                        <ShieldAlert width="12" height="12" style={{ marginRight: 4 }} />
                        SUSPENDED {r.suspendedByName ? `by ${r.suspendedByName}` : ''}
                      </div>
                    )}
                    <div className="responder-card-top">
                      <div className={`responder-avatar ${r.isSuspended ? 'avatar--suspended' : ''}`}>
                        {r.name?.charAt(0)?.toUpperCase() || 'R'}
                      </div>
                      <div>
                        <div className="responder-name">{r.name}</div>
                        <div className="responder-email">{r.email}</div>
                      </div>
                    </div>
                    <div className="responder-divider" />
                    <div className="responder-meta">
                      {r.responderType && (
                        <span className={`badge badge-${typeColor}`}>
                          {r.responderType === 'medical' ? '🏥 Medical' : '🚔 Crime / Police'}
                        </span>
                      )}
                      <div className="responder-info-row">
                        <Phone width="12" height="12" style={{ marginRight: 4 }} />
                        {r.phone || 'Not provided'}
                      </div>
                    </div>

                    <div className="responder-actions">
                      {r.isSuspended ? (
                        <button
                          className="btn-unsuspend"
                          onClick={() => handleUnsuspend(r._id, r.name)}
                          disabled={isBusy}
                        >
                          {isBusy ? <span className="btn-spinner" /> : 'Reinstate'}
                        </button>
                      ) : (
                        <button
                          className="btn-suspend"
                          onClick={() => handleSuspend(r._id, r.name)}
                          disabled={isBusy}
                        >
                          {isBusy ? <span className="btn-spinner" /> : 'Suspend'}
                        </button>
                      )}

                      <div className={`responder-status-dot ${r.isSuspended ? 'suspended' : r.isEmailVerified ? 'verified' : 'unverified'}`}>
                        {r.isSuspended ? '⛔ Suspended' : r.isEmailVerified ? '✓ Verified' : '⚠ Unverified'}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </motion.div>
  )
}
