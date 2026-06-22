import { useState, useEffect } from 'react'
import { getAdmins, createAdmin, updateAdmin, deleteAdmin, suspendUser, unsuspendUser } from '../services/api'
import { motion } from 'framer-motion'
import { Shield, Plus, Edit, Trash2, MapPin, Search, AlertCircle, Compass, HelpCircle, Ban, Check } from 'lucide-react'
import { MapContainer, TileLayer, Marker, Circle, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import toast from 'react-hot-toast'
import './Admins.css'

// Fix Leaflet marker icons in Vite
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Custom marker for map selection
const adminCenterIcon = new L.DivIcon({
  className: 'selection-leaflet-marker',
  html: `<div style="background-color: #4f6ef7; width: 30px; height: 30px; border-radius: 50%; border: 3px solid white; box-shadow: 0 0 15px rgba(79,110,247,0.6); display: flex; align-items: center; justify-content: center; color: white;"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>`,
  iconSize: [30, 30],
  iconAnchor: [15, 15],
});

// Map click event listener component
function MapEvents({ onMapClick }) {
  useMapEvents({
    click(e) {
      onMapClick(e.latlng.lat, e.latlng.lng)
    }
  })
  return null
}

export default function Admins() {
  const [admins, setAdmins] = useState([])
  const [loading, setLoading] = useState(true)

  // Form State
  const [editingId, setEditingId] = useState(null)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [city, setCity] = useState('')
  const [lat, setLat] = useState(31.5204)
  const [lng, setLng] = useState(74.3587)
  const [radius, setRadius] = useState(5) // in km

  const fetchAdminsList = async () => {
    try {
      const res = await getAdmins()
      setAdmins(res.data.admins || [])
    } catch (err) {
      console.error(err)
      toast.error('Failed to load low-level admins')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAdminsList()
  }, [])

  const handleMapClick = (latitude, longitude) => {
    setLat(latitude)
    setLng(longitude)
    toast.success(`Coordinates updated: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`, { id: 'map-coord' })
  }

  const resetForm = () => {
    setEditingId(null)
    setName('')
    setEmail('')
    setPhone('')
    setPassword('')
    setCity('')
    setLat(31.5204)
    setLng(74.3587)
    setRadius(5)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!name || !email || (!editingId && !password) || !city) {
      toast.error('Please fill all required fields')
      return
    }

    const payload = {
      name,
      email,
      phone,
      city,
      lat,
      lng,
      radius: parseFloat(radius)
    }

    if (password) {
      payload.password = password
    }

    try {
      if (editingId) {
        await updateAdmin(editingId, payload)
        toast.success('Admin account updated successfully! 🎉')
      } else {
        await createAdmin(payload)
        toast.success('New Admin account registered! 🎉')
      }
      resetForm()
      fetchAdminsList()
    } catch (err) {
      console.error(err)
      toast.error(err.response?.data?.message || 'Operation failed. Please try again.')
    }
  }

  const handleEditClick = (admin) => {
    setEditingId(admin._id)
    setName(admin.name)
    setEmail(admin.email)
    setPhone(admin.phone || '')
    setPassword('') // Don't show password
    setCity(admin.city)
    setLat(admin.coverageArea?.lat || 31.5204)
    setLng(admin.coverageArea?.lng || 74.3587)
    setRadius(admin.coverageArea?.radius || 5)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDeleteClick = async (id, adminName) => {
    if (window.confirm(`Are you sure you want to delete admin "${adminName}"? This action cannot be undone.`)) {
      try {
        await deleteAdmin(id)
        toast.success('Admin deleted successfully')
        fetchAdminsList()
      } catch (err) {
        console.error(err)
        toast.error('Failed to delete admin')
      }
    }
  }

  const handleSuspendAdmin = async (id, adminName) => {
    if (!window.confirm(`Are you sure you want to suspend admin "${adminName}"? They will not be able to log in.`)) return
    try {
      await suspendUser(id)
      toast.success(`Admin "${adminName}" has been suspended`)
      setAdmins(prev => prev.map(a => a._id === id ? { ...a, isSuspended: true, suspendedByName: 'Super Admin' } : a))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to suspend admin')
    }
  }

  const handleUnsuspendAdmin = async (id, adminName) => {
    try {
      await unsuspendUser(id)
      toast.success(`Admin "${adminName}" has been reinstated`)
      setAdmins(prev => prev.map(a => a._id === id ? { ...a, isSuspended: false, suspendedByName: null } : a))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to unsuspend admin')
    }
  }

  return (
    <motion.div 
      className="admins-page"
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Shield size={28} /> Manage Admins
          </h1>
          <p className="page-subtitle">Configure, map, and deploy low-level admins covering 5 km emergency zones</p>
        </div>
      </div>

      <div className="admins-grid">
        {/* Creation/Edit Form */}
        <div className="admin-form-card">
          <h2 className="card-title">
            {editingId ? <Edit size={18} /> : <Plus size={18} />}
            {editingId ? 'Edit Admin & Zone' : 'Register New Admin'}
          </h2>
          <p className="card-desc">Fill in details and click on the map to define the zone center.</p>

          <form onSubmit={handleSubmit} className="admin-form">
            <div className="form-group">
              <label className="required">Admin Name</label>
              <input 
                type="text" 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                placeholder="Full Name" 
                required 
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="required">Email Address</label>
                <input 
                  type="email" 
                  value={email} 
                  onChange={(e) => setEmail(e.target.value)} 
                  placeholder="admin@safetrack.pk" 
                  required 
                />
              </div>
              <div className="form-group">
                <label>Phone Number</label>
                <input 
                  type="text" 
                  value={phone} 
                  onChange={(e) => setPhone(e.target.value)} 
                  placeholder="+923001234567" 
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className={editingId ? '' : 'required'}>
                  Password {editingId && <span className="label-note">(Leave blank to keep current)</span>}
                </label>
                <input 
                  type="password" 
                  value={password} 
                  onChange={(e) => setPassword(e.target.value)} 
                  placeholder="••••••••" 
                  required={!editingId}
                />
              </div>
              <div className="form-group">
                <label className="required">City</label>
                <input 
                  type="text" 
                  value={city} 
                  onChange={(e) => setCity(e.target.value)} 
                  placeholder="e.g., Lahore" 
                  required 
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="required">Coverage Radius (km)</label>
                <input 
                  type="number" 
                  min="0.5" 
                  max="50" 
                  step="0.5" 
                  value={radius} 
                  onChange={(e) => setRadius(e.target.value)} 
                  required 
                />
              </div>
              <div className="form-group">
                <label>Latitude / Longitude</label>
                <input 
                  type="text" 
                  value={`${lat.toFixed(6)}, ${lng.toFixed(6)}`} 
                  readOnly 
                  className="input-readonly"
                />
              </div>
            </div>

            {/* Selection Map */}
            <div className="form-map-section">
              <div className="map-instruction">
                <Compass size={14} /> Click on the map to set the center of coverage
              </div>
              <div className="form-map-wrapper">
                <MapContainer 
                  center={[lat, lng]} 
                  zoom={12} 
                  style={{ height: '240px', width: '100%' }}
                >
                  <TileLayer
                    url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  />
                  <MapEvents onMapClick={handleMapClick} />
                  <Marker position={[lat, lng]} icon={adminCenterIcon} />
                  <Circle 
                    center={[lat, lng]} 
                    radius={radius * 1000} 
                    pathOptions={{ color: '#4f6ef7', fillColor: '#4f6ef7', fillOpacity: 0.15 }}
                  />
                </MapContainer>
              </div>
            </div>

            <div className="form-actions">
              {editingId && (
                <button type="button" className="btn-cancel" onClick={resetForm}>
                  Cancel
                </button>
              )}
              <button type="submit" className="btn-submit">
                {editingId ? 'Save Changes' : 'Register Admin'}
              </button>
            </div>
          </form>
        </div>

        {/* Existing Admins Table */}
        <div className="admins-list-card">
          <h2 className="card-title">
            <Shield size={18} /> Registered Admins ({admins.length})
          </h2>
          <p className="card-desc">Current low-level admin accounts and their coverage zones.</p>

          <div className="admins-list-table-wrapper">
            {loading ? (
              <div className="list-loading shimmer">Loading admins data...</div>
            ) : admins.length === 0 ? (
              <div className="empty-state">
                <AlertCircle size={36} />
                <p>No admins registered yet. Create one using the form on the left.</p>
              </div>
            ) : (
              <table className="admins-list-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>City / Coverage</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {admins.map(admin => (
                    <tr key={admin._id} className={admin.isSuspended ? 'admin-row--suspended' : ''}>
                      <td>
                        <div className="admin-primary-info">
                          <span className={`admin-avatar ${admin.isSuspended ? 'admin-avatar--suspended' : ''}`}>{admin.name[0]}</span>
                          <div>
                            <div className="admin-name">{admin.name}</div>
                            <div className="admin-email">{admin.email}</div>
                            {admin.isSuspended && (
                              <div className="admin-suspended-badge">
                                Suspended {admin.suspendedByName ? `by ${admin.suspendedByName}` : ''}
                              </div>
                            )}
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="admin-zone-info">
                          <div><strong>City:</strong> {admin.city}</div>
                          <div><strong>Radius:</strong> {admin.coverageArea?.radius || 5} km</div>
                          <div className="coords-sub">
                            {admin.coverageArea?.lat?.toFixed(3)}, {admin.coverageArea?.lng?.toFixed(3)}
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="action-buttons">
                          <button 
                            className="btn-action edit" 
                            title="Edit"
                            onClick={() => handleEditClick(admin)}
                          >
                            <Edit size={14} />
                          </button>
                          {admin.isSuspended ? (
                            <button 
                              className="btn-action unsuspend" 
                              title="Reinstate / Unsuspend"
                              onClick={() => handleUnsuspendAdmin(admin._id, admin.name)}
                            >
                              <Check size={14} />
                            </button>
                          ) : (
                            <button 
                              className="btn-action suspend" 
                              title="Suspend Admin"
                              onClick={() => handleSuspendAdmin(admin._id, admin.name)}
                            >
                              <Ban size={14} />
                            </button>
                          )}
                          <button 
                            className="btn-action delete" 
                            title="Delete"
                            onClick={() => handleDeleteClick(admin._id, admin.name)}
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  )
}
