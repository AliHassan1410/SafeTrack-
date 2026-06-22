// Super Admin API — used by Super Admin pages embedded in the Admin app
// Token: st_superadmin_token (separate from regular admin token)

import { superApi } from '../context/SuperAdminAuthContext'

// ─── Authentication ──────────────────────────────────────────
export const saLogin = (email, password) =>
  superApi.post('/api/auth/login', { email, password, role: 'superadmin' })

// ─── Incidents ───────────────────────────────────────────────
export const saGetIncidents = () => superApi.get('/api/incidents')
export const saUpdateIncidentStatus = (id, status) =>
  superApi.patch(`/api/incidents/${id}/status`, { status })
export const saAssignIncidentResponder = (id, responderId) =>
  superApi.patch(`/api/incidents/${id}/assign`, { responderId })

// ─── Responders ──────────────────────────────────────────────
export const saGetResponders = () =>
  superApi.get('/api/auth/users?role=responder')
export const saCreateResponder = (data) => superApi.post('/api/auth/responders', data)

// ─── Super Admin Manage Admins ────────────────────────────────
export const saGetAdmins = () => superApi.get('/api/superadmin/admins')
export const saCreateAdmin = (data) => superApi.post('/api/superadmin/admins', data)
export const saUpdateAdmin = (id, data) => superApi.put(`/api/superadmin/admins/${id}`, data)
export const saDeleteAdmin = (id) => superApi.delete(`/api/superadmin/admins/${id}`)
export const saGetStats = () => superApi.get('/api/superadmin/stats')

// ─── Profile Update ──────────────────────────────────────────
export const saUpdateProfile = (data) => superApi.put('/api/auth/profile', data)

// ─── Suspend / Unsuspend (Super Admin → Admins + Responders) ──
export const saSuspendUser = (id) => superApi.put(`/api/superadmin/suspend/${id}`)
export const saUnsuspendUser = (id) => superApi.put(`/api/superadmin/unsuspend/${id}`)
