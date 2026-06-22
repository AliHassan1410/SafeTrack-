import { useState, useEffect } from 'react'
import { saGetAdmins, saCreateAdmin, saUpdateAdmin, saDeleteAdmin, saSuspendUser, saUnsuspendUser } from '../services/superAdminApi'
import { motion } from 'framer-motion'
import { Shield, Plus, Edit, Trash2, AlertCircle, Compass, Ban, Check } from 'lucide-react'
import { MapContainer, TileLayer, Marker, Circle, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import toast from 'react-hot-toast'
import '../pages/AdminProfile.css'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
})

const adminCenterIcon = new L.DivIcon({
  className: '',
  html: `<div style="background:#4f6ef7;width:30px;height:30px;border-radius:50%;border:3px solid white;box-shadow:0 0 15px rgba(79,110,247,0.6);display:flex;align-items:center;justify-content:center;color:white;"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>`,
  iconSize: [30, 30], iconAnchor: [15, 15],
})

function MapEvents({ onMapClick }) {
  useMapEvents({ click(e) { onMapClick(e.latlng.lat, e.latlng.lng) } })
  return null
}

export default function SAAdmins() {
  const [admins, setAdmins] = useState([])
  const [loading, setLoading] = useState(true)
  const [editingId, setEditingId] = useState(null)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [city, setCity] = useState('')
  const [lat, setLat] = useState(31.5204)
  const [lng, setLng] = useState(74.3587)
  const [radius, setRadius] = useState(5)

  const fetchAdminsList = async () => {
    try {
      const res = await saGetAdmins()
      setAdmins(res.data.admins || [])
    } catch { toast.error('Failed to load admins') }
    finally { setLoading(false) }
  }

  useEffect(() => { fetchAdminsList() }, [])

  const resetForm = () => {
    setEditingId(null); setName(''); setEmail(''); setPhone('')
    setPassword(''); setCity(''); setLat(31.5204); setLng(74.3587); setRadius(5)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name || !email || (!editingId && !password) || !city) { toast.error('Fill all required fields'); return }
    const payload = { name, email, phone, city, lat, lng, radius: parseFloat(radius) }
    if (password) payload.password = password
    try {
      if (editingId) {
        await saUpdateAdmin(editingId, payload)
        toast.success('Admin updated successfully! 🎉')
      } else {
        await saCreateAdmin(payload)
        toast.success('Admin registered! 🎉')
      }
      resetForm(); fetchAdminsList()
    } catch (err) { toast.error(err.response?.data?.message || 'Operation failed') }
  }

  const handleEditClick = (admin) => {
    setEditingId(admin._id); setName(admin.name); setEmail(admin.email)
    setPhone(admin.phone || ''); setPassword(''); setCity(admin.city)
    setLat(admin.coverageArea?.lat || 31.5204); setLng(admin.coverageArea?.lng || 74.3587)
    setRadius(admin.coverageArea?.radius || 5)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDelete = async (id, adminName) => {
    if (!window.confirm(`Delete admin "${adminName}"? This cannot be undone.`)) return
    try { await saDeleteAdmin(id); toast.success('Admin deleted'); fetchAdminsList() }
    catch { toast.error('Failed to delete') }
  }

  const handleSuspend = async (id, adminName) => {
    if (!window.confirm(`Suspend "${adminName}"? They will not be able to log in.`)) return
    try {
      await saSuspendUser(id)
      toast.success(`"${adminName}" suspended`)
      setAdmins(prev => prev.map(a => a._id === id ? { ...a, isSuspended: true, suspendedByName: 'Super Admin' } : a))
    } catch (err) { toast.error(err.response?.data?.message || 'Failed to suspend') }
  }

  const handleUnsuspend = async (id, adminName) => {
    try {
      await saUnsuspendUser(id)
      toast.success(`"${adminName}" reinstated`)
      setAdmins(prev => prev.map(a => a._id === id ? { ...a, isSuspended: false, suspendedByName: null } : a))
    } catch (err) { toast.error(err.response?.data?.message || 'Failed to unsuspend') }
  }

  return (
    <motion.div initial={{ opacity:0, y:15 }} animate={{ opacity:1, y:0 }} transition={{ duration:0.4 }} style={{ padding:'4px' }}>
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{ display:'flex', alignItems:'center', gap:10 }}>
            <Shield size={26}/> Manage Admins
          </h1>
          <p className="page-subtitle">Configure and deploy low-level admins covering 5 km emergency zones</p>
        </div>
      </div>

      <div style={{ display:'grid', gridTemplateColumns:'1.1fr 0.9fr', gap:24, alignItems:'start' }}>
        {/* Form Card */}
        <div style={{ background:'var(--bg-card)', border:'1.5px solid rgba(79,110,247,0.2)', borderRadius:'var(--radius-lg)', padding:24 }}>
          <h2 style={{ fontSize:17, fontWeight:700, color:'var(--text-primary)', display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
            {editingId ? <Edit size={17}/> : <Plus size={17}/>}
            {editingId ? 'Edit Admin & Zone' : 'Register New Admin'}
          </h2>
          <p style={{ fontSize:13, color:'var(--text-secondary)', marginBottom:20 }}>Fill in details and click the map to set coverage center.</p>

          <form onSubmit={handleSubmit} style={{ display:'flex', flexDirection:'column', gap:14 }}>
            {[
              { label:'Admin Name*', val:name, set:setName, ph:'Full Name', type:'text', req:true },
              { label:'Email*', val:email, set:setEmail, ph:'admin@safetrack.pk', type:'email', req:true },
              { label:'Phone', val:phone, set:setPhone, ph:'+923001234567', type:'text' },
            ].map(f => (
              <div key={f.label} style={{ display:'flex', flexDirection:'column', gap:5 }}>
                <label style={{ fontSize:12, fontWeight:600, color:'var(--text-secondary)' }}>{f.label}</label>
                <input type={f.type} value={f.val} onChange={e => f.set(e.target.value)} placeholder={f.ph} required={f.req}
                  style={{ background:'var(--bg-secondary)', border:'1px solid rgba(255,255,255,0.1)', color:'var(--text-primary)', padding:'10px 14px', borderRadius:'var(--radius-md)', fontSize:14, fontFamily:'var(--font)' }} />
              </div>
            ))}

            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:14 }}>
              <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
                <label style={{ fontSize:12, fontWeight:600, color:'var(--text-secondary)' }}>
                  Password {editingId && <span style={{ fontSize:10, color:'var(--text-muted)' }}>(blank = keep)</span>}
                </label>
                <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" required={!editingId}
                  style={{ background:'var(--bg-secondary)', border:'1px solid rgba(255,255,255,0.1)', color:'var(--text-primary)', padding:'10px 14px', borderRadius:'var(--radius-md)', fontSize:14, fontFamily:'var(--font)' }} />
              </div>
              <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
                <label style={{ fontSize:12, fontWeight:600, color:'var(--text-secondary)' }}>City*</label>
                <input type="text" value={city} onChange={e => setCity(e.target.value)} placeholder="e.g. Lahore" required
                  style={{ background:'var(--bg-secondary)', border:'1px solid rgba(255,255,255,0.1)', color:'var(--text-primary)', padding:'10px 14px', borderRadius:'var(--radius-md)', fontSize:14, fontFamily:'var(--font)' }} />
              </div>
            </div>

            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:14 }}>
              <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
                <label style={{ fontSize:12, fontWeight:600, color:'var(--text-secondary)' }}>Coverage Radius (km)*</label>
                <input type="number" min="0.5" max="50" step="0.5" value={radius} onChange={e => setRadius(e.target.value)} required
                  style={{ background:'var(--bg-secondary)', border:'1px solid rgba(255,255,255,0.1)', color:'var(--text-primary)', padding:'10px 14px', borderRadius:'var(--radius-md)', fontSize:14, fontFamily:'var(--font)' }} />
              </div>
              <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
                <label style={{ fontSize:12, fontWeight:600, color:'var(--text-secondary)' }}>Coordinates</label>
                <input type="text" value={`${lat.toFixed(4)}, ${lng.toFixed(4)}`} readOnly
                  style={{ background:'rgba(255,255,255,0.02)', border:'1px solid rgba(255,255,255,0.08)', color:'var(--text-muted)', padding:'10px 14px', borderRadius:'var(--radius-md)', fontSize:13, fontFamily:'monospace', cursor:'not-allowed' }} />
              </div>
            </div>

            {/* Map picker */}
            <div style={{ border:'1.5px solid rgba(79,110,247,0.2)', borderRadius:'var(--radius-md)', overflow:'hidden' }}>
              <div style={{ padding:'8px 12px', background:'rgba(79,110,247,0.08)', borderBottom:'1px solid rgba(79,110,247,0.15)', fontSize:12, fontWeight:600, color:'var(--accent-primary)', display:'flex', alignItems:'center', gap:6 }}>
                <Compass size={13}/> Click on map to set coverage center
              </div>
              <MapContainer center={[lat, lng]} zoom={12} style={{ height:220, width:'100%' }}>
                <TileLayer url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" attribution="&copy; OpenStreetMap &copy; CARTO"/>
                <MapEvents onMapClick={(la, ln) => { setLat(la); setLng(ln); toast.success(`${la.toFixed(4)}, ${ln.toFixed(4)}`, { id:'coord' }) }} />
                <Marker position={[lat, lng]} icon={adminCenterIcon}/>
                <Circle center={[lat, lng]} radius={radius*1000} pathOptions={{ color:'#4f6ef7', fillColor:'#4f6ef7', fillOpacity:0.13 }}/>
              </MapContainer>
            </div>

            <div style={{ display:'flex', justifyContent:'flex-end', gap:10, borderTop:'1px solid rgba(255,255,255,0.07)', paddingTop:16 }}>
              {editingId && (
                <button type="button" onClick={resetForm}
                  style={{ padding:'9px 18px', borderRadius:'var(--radius-md)', background:'transparent', border:'1px solid rgba(255,255,255,0.12)', color:'var(--text-secondary)', fontWeight:600, cursor:'pointer', fontFamily:'var(--font)' }}>
                  Cancel
                </button>
              )}
              <button type="submit"
                style={{ padding:'9px 22px', borderRadius:'var(--radius-md)', background:'var(--accent-primary)', color:'#fff', fontWeight:700, cursor:'pointer', border:'none', fontFamily:'var(--font)' }}>
                {editingId ? 'Save Changes' : 'Register Admin'}
              </button>
            </div>
          </form>
        </div>

        {/* Admins List */}
        <div style={{ background:'var(--bg-card)', border:'1.5px solid rgba(139,92,246,0.2)', borderRadius:'var(--radius-lg)', padding:24 }}>
          <h2 style={{ fontSize:17, fontWeight:700, color:'var(--text-primary)', display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
            <Shield size={17}/> Registered Admins ({admins.length})
          </h2>
          <p style={{ fontSize:13, color:'var(--text-secondary)', marginBottom:20 }}>Current low-level admin accounts and their coverage zones.</p>

          <div style={{ border:'1.5px solid rgba(255,255,255,0.09)', borderRadius:'var(--radius-md)', overflow:'hidden', background:'var(--bg-secondary)' }}>
            {loading ? (
              <div className="shimmer" style={{ padding:40, textAlign:'center', color:'var(--text-muted)' }}>Loading...</div>
            ) : admins.length === 0 ? (
              <div style={{ padding:40, textAlign:'center', color:'var(--text-muted)', display:'flex', flexDirection:'column', alignItems:'center', gap:10 }}>
                <AlertCircle size={32}/><p style={{ fontSize:13 }}>No admins yet. Create one using the form.</p>
              </div>
            ) : (
              <table style={{ width:'100%', borderCollapse:'collapse' }}>
                <thead>
                  <tr>
                    {['Name','City / Zone','Actions'].map(h => (
                      <th key={h} style={{ textAlign:'left', fontSize:10, fontWeight:700, textTransform:'uppercase', letterSpacing:'0.7px', color:'var(--text-muted)', padding:'11px 14px', borderBottom:'1.5px solid rgba(255,255,255,0.09)', background:'rgba(15,17,32,0.5)' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {admins.map(admin => (
                    <tr key={admin._id} style={{ borderLeft: admin.isSuspended ? '3px solid var(--accent-red)' : 'none' }}>
                      <td style={{ padding:'13px 14px', borderBottom:'1px solid rgba(255,255,255,0.06)' }}>
                        <div style={{ display:'flex', alignItems:'center', gap:9 }}>
                          <span style={{
                            width:30, height:30, borderRadius:'50%', display:'flex', alignItems:'center', justifyContent:'center',
                            fontWeight:700, fontSize:13,
                            color: admin.isSuspended ? 'var(--accent-red)' : 'var(--accent-primary)',
                            background: admin.isSuspended ? 'rgba(239,68,68,0.10)' : 'rgba(79,110,247,0.10)',
                            border: `1.5px solid ${admin.isSuspended ? 'rgba(239,68,68,0.3)' : 'rgba(79,110,247,0.25)'}`,
                            flexShrink:0
                          }}>{admin.name[0]}</span>
                          <div>
                            <div style={{ fontWeight:700, color:'var(--text-primary)', fontSize:13 }}>{admin.name}</div>
                            <div style={{ fontSize:11, color:'var(--text-muted)' }}>{admin.email}</div>
                            {admin.isSuspended && (
                              <span style={{ fontSize:9, fontWeight:700, color:'var(--accent-red)', background:'var(--accent-red-bg)', padding:'1px 6px', borderRadius:'4px', border:'1px solid rgba(239,68,68,0.2)' }}>
                                SUSPENDED
                              </span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td style={{ padding:'13px 14px', borderBottom:'1px solid rgba(255,255,255,0.06)', fontSize:12, color:'var(--text-secondary)' }}>
                        <div><strong style={{ color:'var(--text-primary)' }}>{admin.city}</strong></div>
                        <div style={{ fontFamily:'monospace', fontSize:11, color:'var(--text-muted)', marginTop:2 }}>
                          {admin.coverageArea?.lat?.toFixed(3)}, {admin.coverageArea?.lng?.toFixed(3)} · {admin.coverageArea?.radius||5}km
                        </div>
                      </td>
                      <td style={{ padding:'13px 14px', borderBottom:'1px solid rgba(255,255,255,0.06)' }}>
                        <div style={{ display:'flex', gap:6 }}>
                          <button onClick={() => handleEditClick(admin)} title="Edit"
                            style={{ width:28, height:28, borderRadius:6, display:'flex', alignItems:'center', justifyContent:'center', background:'var(--bg-card)', border:'1px solid rgba(255,255,255,0.10)', color:'var(--text-secondary)', cursor:'pointer', transition:'all 0.2s' }}
                            onMouseEnter={e => { e.target.style.color='var(--accent-primary)'; e.target.style.borderColor='rgba(79,110,247,0.4)' }}
                            onMouseLeave={e => { e.target.style.color='var(--text-secondary)'; e.target.style.borderColor='rgba(255,255,255,0.10)' }}>
                            <Edit size={13}/>
                          </button>
                          {admin.isSuspended ? (
                            <button onClick={() => handleUnsuspend(admin._id, admin.name)} title="Reinstate"
                              style={{ width:28, height:28, borderRadius:6, display:'flex', alignItems:'center', justifyContent:'center', background:'rgba(34,197,94,0.08)', border:'1px solid rgba(34,197,94,0.25)', color:'var(--accent-green)', cursor:'pointer' }}>
                              <Check size={13}/>
                            </button>
                          ) : (
                            <button onClick={() => handleSuspend(admin._id, admin.name)} title="Suspend"
                              style={{ width:28, height:28, borderRadius:6, display:'flex', alignItems:'center', justifyContent:'center', background:'rgba(239,68,68,0.07)', border:'1px solid rgba(239,68,68,0.2)', color:'var(--accent-red)', cursor:'pointer' }}>
                              <Ban size={13}/>
                            </button>
                          )}
                          <button onClick={() => handleDelete(admin._id, admin.name)} title="Delete"
                            style={{ width:28, height:28, borderRadius:6, display:'flex', alignItems:'center', justifyContent:'center', background:'var(--bg-card)', border:'1px solid rgba(255,255,255,0.10)', color:'var(--text-secondary)', cursor:'pointer' }}
                            onMouseEnter={e => { e.target.style.color='var(--accent-red)'; e.target.style.borderColor='rgba(239,68,68,0.35)' }}
                            onMouseLeave={e => { e.target.style.color='var(--text-secondary)'; e.target.style.borderColor='rgba(255,255,255,0.10)' }}>
                            <Trash2 size={13}/>
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
