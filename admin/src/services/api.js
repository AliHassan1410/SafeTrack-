import axios from 'axios'

const BASE_URL = 'http://localhost:5000'

export const api = axios.create({ baseURL: BASE_URL })

// Inject auth token on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('st_admin_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// ─── Incidents ───────────────────────────────────────────────
export const getIncidents = () => api.get('/api/incidents')
export const updateIncidentStatus = (id, status) =>
  api.patch(`/api/incidents/${id}/status`, { status })
export const assignIncidentResponder = (id, responderId) =>
  api.patch(`/api/incidents/${id}/assign`, { responderId })

// ─── Responders ──────────────────────────────────────────────
export const getResponders = () =>
  api.get('/api/auth/users?role=responder')
export const createResponder = (data) => api.post('/api/auth/responders', data)

// ─── Dashboard Stats ─────────────────────────────────────────
export const getDashboardStats = () => api.get('/api/incidents/stats')

// ─── Profile Update ──────────────────────────────────────────
export const updateProfile = (data) => api.put('/api/auth/profile', data)

// ─── Suspend / Unsuspend (Admin → Responders only) ───────────
export const suspendUser = (id) => api.put(`/api/auth/suspend/${id}`)
export const unsuspendUser = (id) => api.put(`/api/auth/unsuspend/${id}`)
