import { useState, useRef, useEffect } from 'react'
import { ChevronDown, Filter } from 'lucide-react'

export default function QuerySelector({ options, selected, onChange, label = "Query" }) {
  const [isOpen, setIsOpen] = useState(false)
  const containerRef = useRef(null)

  useEffect(() => {
    function handleClickOutside(event) {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const selectedOption = options.find(o => o.value === selected)
  const selectedLabel = selectedOption ? selectedOption.label : selected

  return (
    <div className="query-selector-container" ref={containerRef} style={{ position: 'relative', display: 'inline-block' }}>
      <button 
        type="button"
        className="query-selector-btn" 
        onClick={() => setIsOpen(!isOpen)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          background: 'rgba(20, 22, 38, 0.7)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-sm)',
          padding: '6px 12px',
          fontSize: '11px',
          fontWeight: '600',
          color: 'var(--text-secondary)',
          cursor: 'pointer',
          transition: 'var(--transition)',
          backdropFilter: 'blur(8px)',
          userSelect: 'none',
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.borderColor = 'var(--border-active)'
          e.currentTarget.style.color = 'var(--text-primary)'
        }}
        onMouseLeave={(e) => {
          if (!isOpen) {
            e.currentTarget.style.borderColor = 'var(--border)'
            e.currentTarget.style.color = 'var(--text-secondary)'
          }
        }}
      >
        <Filter size={11} className="text-muted" style={{ opacity: 0.7 }} />
        <span>{label}: {selectedLabel}</span>
        <ChevronDown size={11} style={{ transform: isOpen ? 'rotate(180deg)' : 'rotate(0)', transition: 'transform 0.2s', opacity: 0.8 }} />
      </button>

      {isOpen && (
        <ul 
          className="query-selector-dropdown fade-in"
          style={{
            position: 'absolute',
            right: 0,
            top: '100%',
            marginTop: '6px',
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-card)',
            zIndex: 100,
            listStyle: 'none',
            padding: '5px 0',
            minWidth: '120px',
            margin: 0,
          }}
        >
          {options.map((opt) => (
            <li key={opt.value}>
              <button
                type="button"
                onClick={() => {
                  onChange(opt.value)
                  setIsOpen(false)
                }}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  background: 'none',
                  border: 'none',
                  padding: '8px 14px',
                  fontSize: '12px',
                  color: opt.value === selected ? 'var(--accent-primary)' : 'var(--text-secondary)',
                  fontWeight: opt.value === selected ? '700' : '500',
                  cursor: 'pointer',
                  transition: 'background 0.15s, color 0.15s',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = 'var(--bg-card-hover)'
                  e.currentTarget.style.color = 'var(--text-primary)'
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'none'
                  e.currentTarget.style.color = opt.value === selected ? 'var(--accent-primary)' : 'var(--text-secondary)'
                }}
              >
                {opt.label}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
