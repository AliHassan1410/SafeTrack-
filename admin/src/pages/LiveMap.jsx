import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import { getIncidents } from '../services/api'
import { useAuth } from '../context/AuthContext'
import { motion } from 'framer-motion'
import { MapPin, Activity, Shield } from 'lucide-react'
import './LiveMap.css'

// Fix Leaflet's default icon path issues in Vite
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl:       'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl:     'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
})

// Custom map markers by incident type
const createCustomIcon = (color, emoji) => new L.DivIcon({
  className: 'custom-leaflet-icon',
  html: `<div style="background:${color};width:28px;height:28px;border-radius:50%;border:3px solid white;box-shadow:0 0 10px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;font-size:13px;">${emoji}</div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
})

const ICONS = {
  medical:  createCustomIcon('#3b82f6', '🏥'),
  crime:    createCustomIcon('#ef4444', '🚔'),
  fire:     createCustomIcon('#f59e0b', '🔥'),
  accident: createCustomIcon('#8b5cf6', '🚗'),
  other:    createCustomIcon('#10b981', '⚠️'),
}

// Haversine distance in km
function getDistanceKm(lat1, lon1, lat2, lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return Infinity
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

export default function LiveMap() {
  const { admin } = useAuth()
  const [allIncidents, setAllIncidents] = useState([])
  const [loading, setLoading] = useState(true)
  const [typeFilter, setTypeFilter] = useState('all')

  const coverage = admin?.coverageArea   // { lat, lng, radius }
  const hasZone = coverage?.lat && coverage?.lng

  useEffect(() => {
    getIncidents()
      .then(res => {
        const valid = (res.data || []).filter(i =>
          i.location?.coordinates?.length === 2 &&
          i.status !== 'resolved' &&
          i.status !== 'cancelled'
        )
        setAllIncidents(valid)
      })
      .catch(err => console.error(err))
      .finally(() => setLoading(false))
  }, [])

  // ── Zone filtering (lower admin sees only their area) ──
  const zoneIncidents = hasZone
    ? allIncidents.filter(i => {
        const [iLng, iLat] = i.location.coordinates
        return getDistanceKm(coverage.lat, coverage.lng, iLat, iLng) <= (coverage.radius || 5)
      })
    : allIncidents

  // ── Type filter ──
  const incidents = typeFilter === 'all'
    ? zoneIncidents
    : zoneIncidents.filter(i => (i.type || '').toLowerCase() === typeFilter)

  const medCount   = zoneIncidents.filter(i => i.type === 'medical').length
  const crimeCount = zoneIncidents.filter(i => i.type === 'crime').length
  const otherCount = zoneIncidents.filter(i => !['medical', 'crime'].includes(i.type)).length

  // Default map center: admin's zone centre → first incident → Lahore
  const center = hasZone
    ? [coverage.lat, coverage.lng]
    : zoneIncidents.length > 0
      ? [zoneIncidents[0].location.coordinates[1], zoneIncidents[0].location.coordinates[0]]
      : [31.5204, 74.3587]

  const defaultZoom = hasZone ? 13 : 12

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="live-map-page"
    >
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <MapPin size={28} /> Live Incident Map
          </h1>
          <p className="page-subtitle">
            {hasZone
              ? `Showing incidents within your ${coverage.radius || 5}km coverage zone`
              : 'Real-time geographical tracking of active emergencies'}
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          {/* Zone badge */}
          {hasZone && (
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              background: 'rgba(79,110,247,0.12)', border: '1.5px solid rgba(79,110,247,0.3)',
              borderRadius: 999, padding: '5px 14px', fontSize: 12, fontWeight: 600, color: 'var(--accent-primary)'
            }}>
              <Shield size={13} /> {coverage.radius || 5}km Zone
            </div>
          )}
          <div className="map-stats">
            <div className="stat-badge">
              <Activity size={16} className="pulse-icon" color="#10b981" />
              {incidents.length} Active
            </div>
          </div>
        </div>
      </div>

      {/* Type filter tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {[
          { key: 'all',     label: 'All',          count: zoneIncidents.length },
          { key: 'medical', label: '🏥 Medical',    count: medCount },
          { key: 'crime',   label: '🚔 Crime',      count: crimeCount },
          { key: 'other',   label: '⚠️ Other',      count: otherCount },
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setTypeFilter(tab.key)}
            style={{
              padding: '6px 14px',
              borderRadius: 999,
              border: typeFilter === tab.key
                ? '1.5px solid var(--accent-primary)'
                : '1.5px solid rgba(255,255,255,0.1)',
              background: typeFilter === tab.key ? 'rgba(79,110,247,0.18)' : 'transparent',
              color: typeFilter === tab.key ? 'var(--accent-primary)' : 'var(--text-secondary)',
              fontWeight: 600, fontSize: 13, cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 6,
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

      <div className="map-container-wrapper">
        {loading ? (
          <div className="shimmer map-loading">Loading Map Data...</div>
        ) : (
          <MapContainer
            center={center}
            zoom={defaultZoom}
            style={{ height: '100%', width: '100%', borderRadius: '16px', zIndex: 0 }}
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
            />

            {/* Coverage zone circle (only for lower admins with a defined zone) */}
            {hasZone && (
              <Circle
                center={[coverage.lat, coverage.lng]}
                radius={(coverage.radius || 5) * 1000}
                pathOptions={{
                  color: '#4f6ef7',
                  fillColor: '#4f6ef7',
                  fillOpacity: 0.07,
                  weight: 2,
                  dashArray: '6 4',
                }}
              />
            )}

            {/* Incident markers */}
            {incidents.map(inc => (
              <Marker
                key={inc._id}
                position={[inc.location.coordinates[1], inc.location.coordinates[0]]}
                icon={ICONS[(inc.type || '').toLowerCase()] || ICONS.other}
              >
                <Popup className="dark-popup">
                  <div className="popup-content">
                    <span className={`badge badge-${inc.type === 'crime' ? 'red' : inc.type === 'medical' ? 'blue' : 'green'}`}>
                      {(inc.type || 'OTHER').toUpperCase()}
                    </span>
                    <h4 style={{ margin: '6px 0 4px', fontSize: 13 }}>
                      {inc.description?.slice(0, 60) || 'Emergency Incident'}
                    </h4>
                    <p style={{ margin: '2px 0', fontSize: 12 }}>
                      <strong>Reporter:</strong> {inc.reporter?.name || 'Unknown'}
                    </p>
                    <p style={{ margin: '2px 0', fontSize: 12 }}>
                      <strong>Status:</strong> {inc.status}
                    </p>
                    {inc.assignedResponder && (
                      <p style={{ margin: '2px 0', fontSize: 12 }}>
                        <strong>Responder:</strong> {inc.assignedResponder?.name || inc.assignedResponder}
                      </p>
                    )}
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}
      </div>

      {/* Legend */}
      <div style={{ display: 'flex', gap: 16, marginTop: 12, flexWrap: 'wrap' }}>
        {[
          { color: '#3b82f6', label: '🏥 Medical' },
          { color: '#ef4444', label: '🚔 Crime / Police' },
          { color: '#f59e0b', label: '🔥 Fire' },
          { color: '#8b5cf6', label: '🚗 Accident' },
          { color: '#10b981', label: '⚠️ Other' },
        ].map(leg => (
          <div key={leg.label} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text-secondary)' }}>
            <span style={{ width: 10, height: 10, borderRadius: '50%', background: leg.color, display: 'inline-block' }} />
            {leg.label}
          </div>
        ))}
        {hasZone && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text-secondary)' }}>
            <span style={{ width: 20, height: 2, borderTop: '2px dashed #4f6ef7', display: 'inline-block' }} />
            Your Coverage Zone
          </div>
        )}
      </div>
    </motion.div>
  )
}
