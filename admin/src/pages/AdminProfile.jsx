import { useState, useEffect } from 'react'
import { useAuth } from '../context/AuthContext'
import { api, updateProfile } from '../services/api'
import toast from 'react-hot-toast'
import { User, Phone, Mail, Camera, Shield, Calendar } from 'lucide-react'
import './AdminProfile.css'

const PRESET_AVATARS = [
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Milo',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Jack',
]

export default function AdminProfile() {
  const { admin, updateAdmin } = useAuth()
  const [name, setName] = useState(admin?.name || '')
  const [phone, setPhone] = useState(admin?.phone || '')
  const [profilePic, setProfilePic] = useState(admin?.profilePic || '')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await api.get('/api/auth/profile')
        const user = res.data
        setName(user.name || '')
        setPhone(user.phone || '')
        setProfilePic(user.profilePic || '')
        updateAdmin(user)
      } catch (err) {
        console.error('Failed to load profile:', err)
        toast.error('Failed to load profile data')
      } finally {
        setLoading(false)
      }
    }
    fetchProfile()
  }, [])

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 2 * 1024 * 1024) {
      toast.error('Image size must be less than 2MB')
      return
    }
    const reader = new FileReader()
    reader.onloadend = () => {
      setProfilePic(reader.result)
      toast.success('Local image loaded. Click Save Changes to apply.')
    }
    reader.readAsDataURL(file)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name) { toast.error('Name is required'); return }
    setSaving(true)
    const toastId = toast.loading('Saving profile changes...')
    try {
      const res = await updateProfile({ name, phone, profilePic })
      updateAdmin(res.data.user)
      toast.success('Profile updated successfully!', { id: toastId })
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to update profile', { id: toastId })
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="loading-state">
        <div className="shimmer" style={{ width: 100, height: 100, borderRadius: '50%', marginBottom: 20 }} />
        <div className="shimmer" style={{ width: 200, height: 20, borderRadius: 8 }} />
      </div>
    )
  }

  return (
    <div className="admin-profile">
      <div className="page-header">
        <div>
          <h1 className="page-title">Admin Profile</h1>
          <p className="page-subtitle">Manage your credentials, contact info, and profile picture</p>
        </div>
      </div>

      <div className="profile-layout">
        <form onSubmit={handleSubmit} className="profile-form-grid">
          {/* Left Panel — Avatar & Meta */}
          <div className="profile-sidebar-card">
            <div className="avatar-upload-container">
              <div className="avatar-preview-wrap">
                {profilePic ? (
                  <img src={profilePic} alt="Profile" className="avatar-img" />
                ) : (
                  <div className="avatar-placeholder">
                    {name.charAt(0).toUpperCase() || 'A'}
                  </div>
                )}
                <label htmlFor="avatar-file-input" className="avatar-camera-btn" title="Upload custom photo">
                  <Camera size={16} />
                  <input
                    id="avatar-file-input"
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    style={{ display: 'none' }}
                  />
                </label>
              </div>
              <h3>{name || 'Administrator'}</h3>
              <span className="profile-badge">System Administrator</span>
            </div>

            <div className="preset-avatars-section">
              <span className="section-label">Select preset avatar:</span>
              <div className="presets-row">
                {PRESET_AVATARS.map((url, idx) => (
                  <button
                    key={idx}
                    type="button"
                    className={`preset-btn${profilePic === url ? ' active' : ''}`}
                    onClick={() => {
                      setProfilePic(url)
                      toast.success('Preset selected. Click Save to apply.')
                    }}
                  >
                    <img src={url} alt={`Preset ${idx + 1}`} />
                  </button>
                ))}
              </div>
            </div>

            <div className="profile-meta-info">
              <div className="meta-row">
                <Shield size={14} className="meta-icon" />
                <span>Auth: <strong>{admin?.authProvider === 'google' ? 'Google OAuth' : 'Local Credentials'}</strong></span>
              </div>
              <div className="meta-row">
                <Calendar size={14} className="meta-icon" />
                <span>Status: <strong style={{ color: 'var(--accent-green)' }}>{admin?.isEmailVerified ? 'Verified ✓' : 'Pending Verification'}</strong></span>
              </div>
              <div className="meta-row">
                <Mail size={14} className="meta-icon" />
                <span>Email: <strong>{admin?.email || '—'}</strong></span>
              </div>
              <div className="meta-row">
                <Calendar size={14} className="meta-icon" />
                <span>Joined: <strong>{admin?.createdAt ? new Date(admin.createdAt).toLocaleDateString() : '—'}</strong></span>
              </div>
            </div>
          </div>

          {/* Right Panel — Edit Form */}
          <div className="profile-edit-card">
            <h2 className="card-title-sub">Profile Information</h2>
            <p className="card-subtitle-sub">Update your account name and contact number stored in the database</p>

            <div className="form-fields-container">
              <div className="form-group">
                <label className="field-label">Full Name</label>
                <div className="input-with-icon-wrap">
                  <User size={16} className="input-icon" />
                  <input
                    type="text"
                    className="form-input-field"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Enter your name"
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="field-label">Email Address</label>
                <div className="input-with-icon-wrap read-only">
                  <Mail size={16} className="input-icon" />
                  <input
                    type="email"
                    className="form-input-field"
                    value={admin?.email || ''}
                    disabled
                    title="Email cannot be changed"
                  />
                </div>
                <span className="field-hint">Primary identifier — cannot be changed.</span>
              </div>

              <div className="form-group">
                <label className="field-label">Phone Number</label>
                <div className="input-with-icon-wrap">
                  <Phone size={16} className="input-icon" />
                  <input
                    type="text"
                    className="form-input-field"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="e.g. +1 555-0199"
                  />
                </div>
              </div>
            </div>

            <div className="form-actions-row">
              <button type="submit" className="save-profile-btn" disabled={saving}>
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}
