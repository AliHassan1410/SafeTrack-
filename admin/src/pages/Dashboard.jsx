import { useEffect, useState } from 'react'
import { getIncidents, getResponders } from '../services/api'
import { motion } from 'framer-motion'
import StatCard from '../components/StatCard'
import QueryBox, { CHART_TYPE_OPTIONS } from '../components/QueryBox'
import {
  ResponsiveContainer, PieChart, Pie, Cell,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  AreaChart, Area
} from 'recharts'
import './Dashboard.css'

const STATUS_COLORS = {
  pending: 'amber',
  active: 'blue',
  resolved: 'green',
  cancelled: 'red',
}

const TYPE_LABELS = {
  crime: { label: 'Crime', color: 'red' },
  medical: { label: 'Medical', color: 'blue' },
  fire: { label: 'Fire', color: 'amber' },
  accident: { label: 'Accident', color: 'purple' },
  other: { label: 'Other', color: 'green' },
}

function getRelativeTime(dateStr) {
  const diff = Date.now() - new Date(dateStr)
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'Just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  return `${Math.floor(hrs / 24)}d ago`
}

function buildTrendData(incidents, daysCount = 7) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  const now = new Date()
  const dataMap = {}
  for (let i = daysCount - 1; i >= 0; i--) {
    const d = new Date()
    d.setDate(now.getDate() - i)
    const dateStr = d.toDateString()
    const label = daysCount <= 7
      ? days[d.getDay()]
      : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    dataMap[dateStr] = { day: label, crime: 0, medical: 0 }
  }
  incidents.forEach(inc => {
    const key = new Date(inc.createdAt).toDateString()
    if (dataMap[key]) {
      const t = (inc.type || '').toLowerCase()
      if (t === 'crime') dataMap[key].crime++
      if (t === 'medical') dataMap[key].medical++
    }
  })
  return Object.values(dataMap)
}

// Filter incidents by query {type, days}
function qi(list, q) {
  let r = list
  if (q?.days) {
    const lim = new Date()
    lim.setDate(lim.getDate() - q.days)
    r = r.filter(i => new Date(i.createdAt) >= lim)
  }
  const t = q?.type
  if (t && t !== 'all' && t !== 'both') {
    r = r.filter(i => (i.type || '').toLowerCase() === t)
  }
  return r
}

const TT = {
  contentStyle: { background: '#13152a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', boxShadow: '0 8px 32px rgba(0,0,0,0.4)' },
  labelStyle: { color: '#e2e8f0', fontWeight: 600, marginBottom: 4 },
  itemStyle: { color: '#94a3b8' },
}

export default function Dashboard() {
  const [incidents, setIncidents] = useState([])
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Per-statcard query states
  const [totalQ, setTotalQ] = useState({ type: 'all', days: 7 })
  const [pendingQ, setPendingQ] = useState({ type: 'all', days: 7 })
  const [activeQ, setActiveQ] = useState({ type: 'all', days: 7 })
  const [resolvedQ, setResolvedQ] = useState({ type: 'all', days: 7 })

  // Per-chart query states
  const [statusQ, setStatusQ] = useState({ type: 'all', days: 7 })
  const [workloadQ, setWorkloadQ] = useState({ type: 'all', days: 7 })
  const [trendQ, setTrendQ] = useState({ type: 'both', days: 7 })

  useEffect(() => {
    Promise.all([getIncidents(), getResponders()])
      .then(([incRes, resRes]) => {
        setIncidents(incRes.data || [])
        setResponders(resRes.data?.users || resRes.data || [])
      })
      .catch(err => {
        if (err.response?.status === 403 || err.response?.status === 401) {
          setError('Access denied. Only admins can view this.')
        } else {
          setError('Failed to load data. Make sure the backend is running.')
        }
      })
      .finally(() => setLoading(false))
  }, [])

  // Stat card computed values
  const totalVal = qi(incidents, totalQ).length
  const pendingVal = qi(incidents, pendingQ).filter(i => i.status === 'pending').length
  const activeVal = qi(incidents, activeQ).filter(i => ['active', 'in_progress', 'accepted'].includes(i.status)).length
  const resolvedVal = qi(incidents, resolvedQ).filter(i => i.status === 'resolved').length


  // Status doughnut
  const statusInc = qi(incidents, statusQ)
  const statusData = [
    { name: 'Pending', value: statusInc.filter(i => i.status === 'pending').length, color: '#f59e0b' },
    { name: 'Active / In Progress', value: statusInc.filter(i => ['active', 'in_progress', 'accepted'].includes(i.status)).length, color: '#06b6d4' },
    { name: 'Resolved', value: statusInc.filter(i => i.status === 'resolved').length, color: '#22c55e' },
    { name: 'Cancelled', value: statusInc.filter(i => i.status === 'cancelled').length, color: '#ef4444' },
  ].filter(d => d.value > 0)

  // Trend line (type handled per-Line render, filter by days only)
  const trendInc = qi(incidents, { days: trendQ.days })
  const weeklyData = buildTrendData(trendInc, trendQ.days)

  // Workload area
  const workloadInc = qi(incidents, workloadQ)
  const workloadData = responders.length > 0
    ? responders.map(r => {
        const assigned = workloadInc.filter(i => i.assignedResponder?._id === r._id || i.assignedResponder === r._id)
        return { name: r.name ? r.name.split(' ')[0] : 'Unknown', assigned: assigned.length, resolved: assigned.filter(i => i.status === 'resolved').length }
      }).slice(0, 7)
    : [{ name: 'Police A', assigned: 4, resolved: 3 }, { name: 'Medic B', assigned: 5, resolved: 4 }, { name: 'Fire C', assigned: 2, resolved: 1 }]

  const recent = [...incidents].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 8)

  if (loading) return <DashboardSkeleton />

  return (
    <motion.div className="dashboard" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">Overview of SafeTrack emergency response activity</p>
        </div>
        <div className="live-badge"><span className="live-dot" />Live</div>
      </div>

      {error && (
        <div className="dashboard-error">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          {error}
        </div>
      )}

      {/* Stats Grid — each card with its own Query box */}
      <div className="stats-grid">
        <StatCard
          label="Total Incidents"
          value={totalVal}
          color="blue"
          icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>}
          headerAction={<QueryBox compact onApply={setTotalQ} />}
        />
        <StatCard
          label="Pending"
          value={pendingVal}
          color="amber"
          icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
          headerAction={<QueryBox compact onApply={setPendingQ} />}
        />
        <StatCard
          label="Active / In Progress"
          value={activeVal}
          color="red"
          icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>}
          headerAction={<QueryBox compact onApply={setActiveQ} />}
        />
        <StatCard
          label="Resolved"
          value={resolvedVal}
          color="green"
          icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>}
          headerAction={<QueryBox compact onApply={setResolvedQ} />}
        />
      </div>

      {/* 2-col charts */}
      <div className="charts-grid">
          {/* Doughnut — Incident Status */}
        <div className="chart-card" style={{ overflow: 'visible' }}>
          <div className="chart-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 className="chart-title">Incident Status</h2>
              <p className="chart-subtitle">Breakdown of incident states</p>
            </div>
            <QueryBox onApply={setStatusQ} />
          </div>

          <div className="chart-container">
            {statusData.length === 0 ? (
              <div className="empty-state" style={{ padding: 0 }}>No data for selected query</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={statusData} cx="50%" cy="45%" innerRadius={55} outerRadius={75} paddingAngle={4} dataKey="value">
                    {statusData.map((e, i) => <Cell key={i} fill={e.color} />)}
                  </Pie>
                  <Tooltip {...TT} />
                  <Legend verticalAlign="bottom" iconType="circle" iconSize={8} formatter={v => <span style={{ color: '#8b92b8', fontSize: '11px' }}>{v}</span>} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Area — Responder Workload */}
        <div className="chart-card" style={{ overflow: 'visible' }}>
          <div className="chart-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 className="chart-title">Responder Workload</h2>
              <p className="chart-subtitle">Assigned vs resolved per responder</p>
            </div>
            <QueryBox showType={false} onApply={setWorkloadQ} />
          </div>
          <div className="chart-container">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={workloadData} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                <defs>
                  <linearGradient id="cA" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#4f6ef7" stopOpacity={0.2}/><stop offset="95%" stopColor="#4f6ef7" stopOpacity={0}/></linearGradient>
                  <linearGradient id="cR" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#22c55e" stopOpacity={0.2}/><stop offset="95%" stopColor="#22c55e" stopOpacity={0}/></linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                <XAxis dataKey="name" stroke="#5c6188" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#5c6188" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                <Tooltip {...TT} />
                <Legend verticalAlign="top" height={28} iconType="circle" iconSize={8} formatter={v => <span style={{ color: '#8b92b8', fontSize: '11px' }}>{v.charAt(0).toUpperCase() + v.slice(1)}</span>} />
                <Area type="monotone" dataKey="assigned" stroke="#4f6ef7" strokeWidth={2} fillOpacity={1} fill="url(#cA)" />
                <Area type="monotone" dataKey="resolved" stroke="#22c55e" strokeWidth={2} fillOpacity={1} fill="url(#cR)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Full-width Trend Chart */}
      <div className="chart-card dashboard-weekly-chart" style={{ overflow: 'visible' }}>
        <div className="chart-header" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <div>
            <h2 className="chart-title">{trendQ.days === 7 ? 'Weekly' : `${trendQ.days}-Day`} Incident Trend</h2>
            <p className="chart-subtitle">Crime vs Medical emergency reports</p>
          </div>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            {(trendQ.type === 'both' || trendQ.type === 'crime') && <span className="legend-chip crime">● Crime</span>}
            {(trendQ.type === 'both' || trendQ.type === 'medical') && <span className="legend-chip medical">● Medical</span>}
            <QueryBox typeOptions={CHART_TYPE_OPTIONS} initialType="both" onApply={setTrendQ} />
          </div>
        </div>
        <div style={{ height: 260 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={weeklyData} margin={{ top: 10, right: 24, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" vertical={false} />
              <XAxis dataKey="day" stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} />
              <YAxis stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} allowDecimals={false} />
              <Tooltip {...TT} />
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

      {/* Recent Incidents */}
      <div className="dashboard-section" style={{ marginTop: 24 }}>
        <div className="section-header">
          <h2 className="section-title">Recent Incidents</h2>
          <span className="section-count">{incidents.length} total</span>
        </div>
        {incidents.length === 0 && !error ? (
          <div className="empty-state">No incidents reported yet.</div>
        ) : (
          <div className="incidents-table-wrap">
            <table className="incidents-table">
              <thead>
                <tr>
                  <th>Type</th><th>Description</th><th>Reporter</th><th>Status</th><th>Reported</th>
                </tr>
              </thead>
              <tbody>
                {recent.map(inc => {
                  const typeInfo = TYPE_LABELS[inc.type] || TYPE_LABELS.other
                  const statusColor = STATUS_COLORS[inc.status] || 'blue'
                  return (
                    <tr key={inc._id}>
                      <td><span className={`badge badge-${typeInfo.color}`}>{typeInfo.label}</span></td>
                      <td className="incident-desc">{inc.description?.slice(0, 60) || '—'}{inc.description?.length > 60 ? '…' : ''}</td>
                      <td className="incident-reporter">{inc.reporter?.name || 'Unknown'}</td>
                      <td><span className={`badge badge-${statusColor}`}>{inc.status}</span></td>
                      <td className="incident-time">{getRelativeTime(inc.createdAt)}</td>
                    </tr>
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

function DashboardSkeleton() {
  return (
    <div className="dashboard">
      <div className="page-header">
        <div>
          <div className="shimmer" style={{ width: 160, height: 28, borderRadius: 8, marginBottom: 8 }} />
          <div className="shimmer" style={{ width: 260, height: 16, borderRadius: 6 }} />
        </div>
      </div>
      <div className="stats-grid">
        {[1,2,3,4].map(i => <div key={i} className="stat-card shimmer" style={{ height: 100 }} />)}
      </div>
      <div className="shimmer" style={{ height: 300, borderRadius: 16, marginTop: 24 }} />
    </div>
  )
}
