import { createContext, useContext, useState } from 'react'
import axios from 'axios'

const BASE_URL = 'http://localhost:5000'

const superApi = axios.create({ baseURL: BASE_URL })

superApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('st_superadmin_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

const SuperAdminAuthContext = createContext(null)

export function SuperAdminAuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('st_superadmin_token'))
  const [admin, setAdmin] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('st_superadmin_user')) || null
    } catch { return null }
  })
  const [loading, setLoading] = useState(false)

  const login = async (email, password) => {
    setLoading(true)
    try {
      const res = await superApi.post('/api/auth/login', { email, password, role: 'superadmin' })
      const { user } = res.data
      const tok = user.token
      setToken(tok)
      setAdmin(user)
      localStorage.setItem('st_superadmin_token', tok)
      localStorage.setItem('st_superadmin_user', JSON.stringify(user))
      return { success: true }
    } catch (err) {
      return {
        success: false,
        message: err.response?.data?.message || 'Login failed',
        isSuspended: err.response?.data?.isSuspended || false,
        suspendedByName: err.response?.data?.suspendedByName || null
      }
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    setToken(null)
    setAdmin(null)
    localStorage.removeItem('st_superadmin_token')
    localStorage.removeItem('st_superadmin_user')
  }

  const updateAdmin = (updatedUser) => {
    setAdmin(updatedUser)
    localStorage.setItem('st_superadmin_user', JSON.stringify(updatedUser))
  }

  return (
    <SuperAdminAuthContext.Provider value={{ token, admin, login, logout, loading, updateAdmin, superApi }}>
      {children}
    </SuperAdminAuthContext.Provider>
  )
}

export function useSuperAdminAuth() {
  return useContext(SuperAdminAuthContext)
}

export { superApi }
