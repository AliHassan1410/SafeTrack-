import { useEffect, useState } from 'react'
import { getIncidents, updateIncidentStatus, getResponders, assignIncidentResponder } from '../services/api'
import toast from 'react-hot-toast'
import { motion } from 'framer-motion'
import { Download, RefreshCw, Search, MapPin, Clock, User, Shield } from 'lucide-react'
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts'
import './Incidents.css'
import '../pages/Dashboard.css'
import QueryBox, { CHART_TYPE_OPTIONS } from '../components/QueryBox'

const TYPE_OPTIONS = CHART_TYPE_OPTIONS
const DAY_OPTIONS = [7, 30, 60, 90]

const STATUS_COLORS = {


  pending: 'amber', active: 'blue', in_progress: 'blue', accepted: 'blue',
  resolved: 'green', cancelled: 'red',
}

const TYPE_LABELS = {
  crime: { label: 'Crime', color: 'red', hex: '#ef4444' },
  medical: { label: 'Medical', color: 'blue', hex: '#4f6ef7' },
  fire: { label: 'Fire', color: 'amber', hex: '#f59e0b' },
  accident: { label: 'Accident', color: 'purple', hex: '#a855f7' },
  other: { label: 'Other', color: 'green', hex: '#10b981' },
}

const STATUSES = ['all', 'pending', 'active', 'in_progress', 'resolved', 'cancelled']

function qi(list, q) {
  let r = list
  if (q?.days) { const lim = new Date(); lim.setDate(lim.getDate() - q.days); r = r.filter(i => new Date(i.createdAt) >= lim) }
  const t = q?.type
  if (t && t !== 'all' && t !== 'both') r = r.filter(i => (i.type || '').toLowerCase() === t)
  return r
}

function timeAgo(d) {
  const diff = Date.now() - new Date(d)
  const m = Math.floor(diff / 60000)
  if (m < 1) return 'Just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return new Date(d).toLocaleDateString()
}

export default function Incidents() {
  const [incidents, setIncidents] = useState([])
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')
  const [updating, setUpdating] = useState(null)
  const [error, setError] = useState('')
  const [trendQ, setTrendQ] = useState({ type: 'both', days: 7 })
  const [statusQ, setStatusQ] = useState({ type: 'all', days: 7 })
  const [summaryQ, setSummaryQ] = useState({ type: 'all', days: 7 })

  // Query feather should not be tied to the table filter. Ensure 'All' shows everything.


  const load = () => {
    setLoading(true)
    Promise.all([getIncidents(), getResponders()])
      .then(([incRes, resRes]) => {
        setIncidents(incRes.data)
        setResponders(resRes.data?.users || resRes.data || [])
      })
      .catch(err => {
        setError(err.response?.data?.message || 'Failed to load data')
        toast.error('Failed to load incidents')
      })
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  function buildTrendData(list, daysCount = 7) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    const now = new Date()
    const dataMap = {}
    for (let i = daysCount - 1; i >= 0; i--) {
      const d = new Date()
      d.setDate(now.getDate() - i)
      const dateStr = d.toDateString()
      let label = ''
      if (daysCount <= 7) {
        label = days[d.getDay()]
      } else {
        label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
      }
      dataMap[dateStr] = { label, day: label, dateStr, crime: 0, medical: 0 }
    }
    list.forEach(inc => {
      const key = new Date(inc.createdAt).toDateString()
      if (dataMap[key]) {
        const t = (inc.type || '').toLowerCase()
        if (t === 'crime') dataMap[key].crime++
        if (t === 'medical') dataMap[key].medical++
      }
    })
    return Object.values(dataMap)
  }

  const filtered = incidents.filter(i => {
    const mappedFilterStatus = filter === 'active' ? ['active', 'accepted', 'in_progress'] : [filter]
    const matchStatus = filter === 'all' || mappedFilterStatus.includes(i.status)

    const q = search.toLowerCase()
    const matchSearch = !q ||
      i.description?.toLowerCase().includes(q) ||
      i.type?.toLowerCase().includes(q) ||
      i.reporter?.name?.toLowerCase().includes(q) ||
      i.assignedResponder?.name?.toLowerCase().includes(q)
    return matchStatus && matchSearch
  })

  // --- Analytics Data ---
  const trendInc = qi(incidents, { days: trendQ.days })
  const weeklyData = buildTrendData(trendInc, trendQ.days)

  const statusInc = qi(incidents, statusQ)
  const statusBreakdown = [
    { name: 'Pending', value: statusInc.filter(i => i.status === 'pending').length, color: '#f59e0b' },
    { name: 'Active', value: statusInc.filter(i => ['active', 'accepted', 'in_progress'].includes(i.status)).length, color: '#06b6d4' },
    { name: 'Resolved', value: statusInc.filter(i => i.status === 'resolved').length, color: '#22c55e' },
    { name: 'Cancelled', value: statusInc.filter(i => i.status === 'cancelled').length, color: '#ef4444' },
  ].filter(d => d.value > 0)

  const summaryInc = qi(incidents, summaryQ)

  const handleStatusChange = async (id, newStatus) => {
    setUpdating(id)
    const toastId = toast.loading('Updating status...')
    try {
      await updateIncidentStatus(id, newStatus)
      setIncidents(prev => prev.map(i => i._id === id ? { ...i, status: newStatus } : i))
      toast.success('Status updated successfully', { id: toastId })
    } catch {
      toast.error('Failed to update status', { id: toastId })
    } finally {
      setUpdating(null)
    }
  }

  const handleAssignResponder = async (id, responderId) => {
    if (!responderId) return
    setUpdating(id)
    const toastId = toast.loading('Assigning responder...')
    try {
      const res = await assignIncidentResponder(id, responderId)
      setIncidents(prev => prev.map(i => i._id === id ? res.data.incident : i))
      toast.success('Responder assigned successfully', { id: toastId })
    } catch {
      toast.error('Failed to assign responder', { id: toastId })
    } finally {
      setUpdating(null)
    }
  }

  const downloadCSV = () => {
    if (filtered.length === 0) { toast.error('No incidents to export'); return }
    const headers = ['Type', 'Description', 'Reporter Name', 'Reporter Phone', 'Responder Name', 'Status', 'Date Reported', 'Coordinates']
    const rows = filtered.map(inc => [
      inc.type,
      `"${(inc.description || '').replace(/"/g, '""')}"`,
      `"${inc.reporter?.name || 'Unknown'}"`,
      `"${inc.reporter?.phone || 'N/A'}"`,
      `"${inc.assignedResponder?.name || 'Unassigned'}"`,
      inc.status,
      new Date(inc.createdAt).toLocaleString(),
      inc.location?.coordinates ? `"${inc.location.coordinates[1]}, ${inc.location.coordinates[0]}"` : 'N/A'
    ])
    const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n')
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `safetrack_incidents_${new Date().toISOString().split('T')[0]}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    toast.success('Report downloaded')
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Incidents Management</h1>
          <p className="page-subtitle">Manage, assign, and export emergency incidents</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <button className="refresh-btn" onClick={downloadCSV} style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
            <Download size={16} /> Export CSV
          </button>
          <button className="refresh-btn" onClick={load}>
            <RefreshCw size={16} /> Refresh
          </button>
        </div>
      </div>

      {error && <div className="dashboard-error" style={{ marginBottom: 20 }}>{error}</div>}

      {/* Analytics Charts */}
      {!loading && (

        <div className="incidents-charts-row">

          {/* Full-width Weekly Crime vs Medical Line Chart */}
          <div className="chart-card incidents-weekly-chart" style={{ overflow: 'visible' }}>
            <div className="chart-header" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
              <div>
                <h2 className="chart-title">{trendQ.days === 7 ? 'Weekly' : `${trendQ.days} Days`} Incident Trend</h2>
                <p className="chart-subtitle">Crime vs Medical emergency reports — last {trendQ.days} days</p>
              </div>
              <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexShrink: 0 }}>
                {(trendQ.type === 'both' || trendQ.type === 'crime') && <span className="legend-chip crime">● Crime</span>}
                {(trendQ.type === 'both' || trendQ.type === 'medical') && <span className="legend-chip medical">● Medical</span>}
                <QueryBox typeOptions={CHART_TYPE_OPTIONS} initialType="both" onApply={setTrendQ} />
              </div>
            </div>
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={weeklyData} margin={{ top: 10, right: 24, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" vertical={false} />
                  <XAxis dataKey="day" stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip
                    contentStyle={{ background: '#13152a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', boxShadow: '0 8px 32px rgba(0,0,0,0.4)' }}
                    labelStyle={{ color: '#e2e8f0', fontWeight: 600, marginBottom: 4 }}
                    itemStyle={{ color: '#94a3b8' }}
                  />
                  {(trendQ.type === 'both' || trendQ.type === 'crime') && (
                    <Line type="monotone" dataKey="crime" name="Crime" stroke="#ef4444" strokeWidth={2.5} dot={{ fill: '#ef4444', r: 4, strokeWidth: 0 }} activeDot={{ r: 6, fill: '#ef4444', stroke: 'rgba(239,68,68,0.3)', strokeWidth: 4 }} />
                  )}
                  {(trendQ.type === 'both' || trendQ.type === 'medical') && (
                    <Line type="monotone" dataKey="medical" name="Medical" stroke="#4f6ef7" strokeWidth={2.5} dot={{ fill: '#4f6ef7', r: 4, strokeWidth: 0 }} activeDot={{ r: 6, fill: '#4f6ef7', stroke: 'rgba(79,110,247,0.3)', strokeWidth: 4 }} />
                  )}
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Pie + Summary row */}
          <div className="incidents-sub-charts">
            {/* Status Distribution Pie */}
            <div className="chart-card incidents-chart-sm" style={{ overflow: 'visible' }}>
              <div className="chart-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                <div>
                  <h2 className="chart-title">By Status</h2>
                  <p className="chart-subtitle">Distribution — last {statusQ.days} days</p>
                </div>
                <QueryBox onApply={setStatusQ} />
              </div>
              <div style={{ height: 200 }}>
                {statusBreakdown.length === 0 ? (
                  <div className="empty-state" style={{ padding: 0, marginTop: 40 }}>No status data for selected query</div>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={statusBreakdown}
                        cx="50%"
                        cy="45%"
                        innerRadius={48}
                        outerRadius={68}
                        paddingAngle={3}
                        dataKey="value"
                      >
                        {statusBreakdown.map((entry, idx) => (
                          <Cell key={`cell-${idx}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{ background: '#13152a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px' }}
                        labelStyle={{ color: '#fff' }}
                        itemStyle={{ color: '#94a3b8' }}
                      />
                      <Legend
                        verticalAlign="bottom"
                        iconType="circle"
                        iconSize={7}
                        formatter={(value) => <span style={{ color: '#8b92b8', fontSize: '10px' }}>{value}</span>}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                )}
              </div>
            </div>

            {/* Quick Summary */}
            <div className="incidents-summary-card" style={{ overflow: 'visible' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <h2 className="chart-title" style={{ margin: 0 }}>Quick Summary</h2>
                <QueryBox onApply={setSummaryQ} />
              </div>
              <div className="summary-stats-grid">
                <div className="summary-stat">
                  <div className="summary-stat-val" style={{ color: '#4f6ef7' }}>{summaryInc.length}</div>
                  <div className="summary-stat-lbl">Total</div>
                </div>
                <div className="summary-stat">
                  <div className="summary-stat-val" style={{ color: '#f59e0b' }}>
                    {summaryInc.filter(i => i.status === 'pending').length}
                  </div>
                  <div className="summary-stat-lbl">Pending</div>
                </div>
                <div className="summary-stat">
                  <div className="summary-stat-val" style={{ color: '#06b6d4' }}>
                    {summaryInc.filter(i => ['active', 'accepted', 'in_progress'].includes(i.status)).length}
                  </div>
                  <div className="summary-stat-lbl">Active</div>
                </div>
                <div className="summary-stat">
                  <div className="summary-stat-val" style={{ color: '#22c55e' }}>
                    {summaryInc.filter(i => i.status === 'resolved').length}
                  </div>
                  <div className="summary-stat-lbl">Resolved</div>
                </div>
              </div>
              <div className="summary-responders-info">
                <div className="summary-responders-title">
                  <Shield size={13} /> Responders Active
                </div>
                <div className="summary-responders-count">{responders.length}</div>
              </div>
              <div className="summary-responders-info" style={{ marginTop: 8 }}>
                <div className="summary-responders-title">
                  <User size={13} /> Unassigned Incidents
                </div>
                <div className="summary-responders-count" style={{ color: '#f59e0b' }}>
                  {incidents.filter(i => !i.assignedResponder && i.status === 'pending').length}
                </div>
              </div>
            </div>
          </div>
        </div>
        )}

        {(!loading && incidents.length === 0) && (
          <div className="empty-state">No incidents found.</div>
        )}

      {/* Filters */}

      <div className="incidents-filters">
        <div className="filter-tabs">
          {STATUSES.map(s => (
            <button
              key={s}
              className={`filter-tab${filter === s ? ' active' : ''}`}
              onClick={() => setFilter(s)}
            >
              {s === 'all' ? `All (${incidents.length})` : s.replace('_', ' ')}
            </button>
          ))}
        </div>
        <div className="search-wrap">
          <Search className="search-icon" size={16} />
          <input
            className="search-input"
            placeholder="Search descriptions, reporters..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
      </div>

      {/* Table */}
      <div className="dashboard-section">
        {loading ? (
          <div className="shimmer" style={{ height: 400, margin: 20, borderRadius: 12 }} />
        ) : filtered.length === 0 ? (
          <div className="empty-state">No incidents match your filters.</div>
        ) : (
          <div className="incidents-table-wrap">
            <table className="incidents-table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Description</th>
                  <th>Reporter</th>
                  <th>Location</th>
                  <th>Responder</th>
                  <th>Status</th>
                  <th>Reported</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(inc => {
                  const typeInfo = TYPE_LABELS[inc.type] || TYPE_LABELS.other
                  const availableResponders = responders.filter(r => r.responderType === inc.type)
                  const coords = inc.location?.coordinates

                  return (
                    <motion.tr
                      key={inc._id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                    >
                      <td><span className={`badge badge-${typeInfo.color}`}>{typeInfo.label}</span></td>
                      <td className="incident-desc" title={inc.description}>{inc.description?.slice(0, 50) || '—'}{inc.description?.length > 50 ? '…' : ''}</td>
                      <td className="incident-reporter">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                          <span>{inc.reporter?.name || 'Unknown'}</span>
                          {inc.reporter?.phone && <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{inc.reporter.phone}</span>}
                        </div>
                      </td>
                      <td className="incident-location">
                        {coords ? (
                          <a
                            href={`https://maps.google.com/?q=${coords[1]},${coords[0]}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="location-link"
                          >
                            <MapPin size={12} />
                            {coords[1].toFixed(4)}, {coords[0].toFixed(4)}
                          </a>
                        ) : (
                          <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>N/A</span>
                        )}
                      </td>

                      {/* ASSIGNED RESPONDER FIELD */}
                      <td className="incident-responder">
                        {inc.assignedResponder ? (
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--accent-green)' }}></div>
                            <span title={inc.assignedResponder.name}>{inc.assignedResponder.name?.split(' ')[0] || 'Unknown'}</span>
                          </div>
                        ) : (
                          <select
                            className="status-select"
                            style={{ background: 'rgba(255,255,255,0.03)', width: 110 }}
                            disabled={updating === inc._id || inc.status === 'resolved' || inc.status === 'cancelled'}
                            onChange={e => handleAssignResponder(inc._id, e.target.value)}
                            value=""
                          >
                            <option value="" disabled>Assign...</option>
                            {availableResponders.length > 0
                              ? availableResponders.map(r => (
                                  <option key={r._id} value={r._id}>{r.name?.split(' ')[0] || 'Unknown'} ({r.responderType})</option>
                                ))
                              : responders.map(r => (
                                  <option key={r._id} value={r._id}>{r.name?.split(' ')[0] || 'Unknown'}</option>
                                ))
                            }
                          </select>
                        )}
                      </td>

                      <td><span className={`badge badge-${STATUS_COLORS[inc.status] || 'blue'}`}>{inc.status}</span></td>
                      <td className="incident-time">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                          <span>{timeAgo(inc.createdAt)}</span>
                          <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{new Date(inc.createdAt).toLocaleDateString()}</span>
                        </div>
                      </td>

                      {/* STATUS CHANGE */}
                      <td>
                        <select
                          className="status-select"
                          value={inc.status}
                          disabled={updating === inc._id}
                          onChange={e => handleStatusChange(inc._id, e.target.value)}
                        >
                          <option value="pending">Pending</option>
                          <option value="accepted">Accepted</option>
                          <option value="active">Active</option>
                          <option value="in_progress">In Progress</option>
                          <option value="resolved">Resolved</option>
                          <option value="cancelled">Cancelled</option>
                        </select>
                      </td>
                    </motion.tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </motion.div>
  )
}
