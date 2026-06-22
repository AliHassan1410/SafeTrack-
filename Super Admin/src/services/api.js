import axios from 'axios'

const BASE_URL = 'http://localhost:5000'

export const api = axios.create({ baseURL: BASE_URL })

// Inject auth token on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('st_superadmin_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// ─── Authentication ──────────────────────────────────────────
export const login = (email, password) => 
  api.post('/api/auth/login', { email, password, role: 'superadmin' })

// ─── Incidents ───────────────────────────────────────────────
export const getIncidents = () => api.get('/api/incidents')
export const updateIncidentStatus = (id, status) =>
  api.patch(`/api/incidents/${id}/status`, { status })
export const assignIncidentResponder = (id, responderId) =>
  api.patch(`/api/incidents/${id}/assign`, { responderId })

// ─── Responders ──────────────────────────────────────────────
export const getResponders = () =>
  api.get('/api/auth/users?role=responder')

// ─── Super Admin Manage Admins ────────────────────────────────
export const getAdmins = () => api.get('/api/superadmin/admins')
export const createAdmin = (data) => api.post('/api/superadmin/admins', data)
export const updateAdmin = (id, data) => api.put(`/api/superadmin/admins/${id}`, data)
export const deleteAdmin = (id) => api.delete(`/api/superadmin/admins/${id}`)
export const getSuperAdminStats = () => api.get('/api/superadmin/stats')

// ─── Profile Update ──────────────────────────────────────────
export const updateProfile = (data) => api.put('/api/auth/profile', data)

// ─── Suspend / Unsuspend (Super Admin → Admins + Responders) ───
export const suspendUser = (id) => api.put(`/api/superadmin/suspend/${id}`)
export const unsuspendUser = (id) => api.put(`/api/superadmin/unsuspend/${id}`)
