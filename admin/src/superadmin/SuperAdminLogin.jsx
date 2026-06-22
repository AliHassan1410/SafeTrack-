import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useSuperAdminAuth } from '../context/SuperAdminAuthContext'
import '../pages/Login.css'
import './SuperAdminLogin.css'

export default function SuperAdminLogin() {
  const { login, loading } = useSuperAdminAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (!email || !password) { setError('Please enter email and password'); return }
    const result = await login(email, password)
    if (result.success) {
      navigate('/SuperAdmin/dashboard')
    } else {
      setError(result.message)
      if (result.isSuspended) {
        alert(`Account Suspended!\nSuspended by: ${result.suspendedByName || 'Administrator'}`)
      }
    }
  }

  return (
    <div className="login-page sa-login-page">
      {/* Background orbs */}
      <div className="login-orb login-orb-1 sa-orb-1" />
      <div className="login-orb login-orb-2 sa-orb-2" />

      {/* Back to Admin Login */}
      <button
        className="sa-back-btn"
        onClick={() => navigate('/login')}
        title="Back to Admin Login"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="15 18 9 12 15 6"/>
        </svg>
        Admin Login
      </button>

      {/* Super Admin Card */}
      <div className="login-card login-card--super fade-in">
        {/* Logo */}
        <div className="login-logo">
          <div className="login-logo-icon login-logo-icon--super">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" stroke="none">
              <path d="M2 19l2-8 5 4 3-7 3 7 5-4 2 8H2zm0 2h20v1a1 1 0 01-1 1H3a1 1 0 01-1-1v-1z"/>
            </svg>
          </div>
          <div>
            <h1 className="login-title">SafeTrack</h1>
            <p className="login-subtitle login-subtitle--super">Super Admin Portal</p>
          </div>
        </div>

        <div className="login-divider" />

        <h2 className="login-heading">Super Admin Access</h2>
        <p className="login-desc">Monitor and manage all zone admins across Pakistan's Emergency System</p>

        <form className="login-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label" htmlFor="sa-email">Email Address</label>
            <div className="form-input-wrap">
              <span className="form-input-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
              </span>
              <input
                id="sa-email"
                type="email"
                className="form-input"
                placeholder="superadmin@safetrack.pk"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="sa-password">Password</label>
            <div className="form-input-wrap">
              <span className="form-input-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                  <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
              </span>
              <input
                id="sa-password"
                type={showPw ? 'text' : 'password'}
                className="form-input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
              />
              <button type="button" className="form-pw-toggle" onClick={() => setShowPw(!showPw)}>
                {showPw ? (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94"/>
                    <path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                ) : (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                    <circle cx="12" cy="12" r="3"/>
                  </svg>
                )}
              </button>
            </div>
          </div>

          {error && (
            <div className="login-error">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {error}
            </div>
          )}

          <button type="submit" className="login-btn login-btn--super" disabled={loading}>
            {loading ? (
              <span className="login-btn-spinner" />
            ) : (
              <>
                Enter Super Admin Dashboard
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="5" y1="12" x2="19" y2="12"/>
                  <polyline points="12 5 19 12 12 19"/>
                </svg>
              </>
            )}
          </button>
        </form>

        <div className="login-badge">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="none">
            <path d="M2 19l2-8 5 4 3-7 3 7 5-4 2 8H2zm0 2h20v1a1 1 0 01-1 1H3a1 1 0 01-1-1v-1z"/>
          </svg>
          Super Admin — Highest Level Access
        </div>
      </div>
    </div>
  )
}
