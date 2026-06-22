import { useState, useRef, useEffect, useCallback } from 'react'
import { createPortal } from 'react-dom'
import { SlidersHorizontal, X, ChevronDown } from 'lucide-react'

const DEFAULT_TYPE = [
  { label: 'All', value: 'all' },
  { label: 'Crime', value: 'crime' },
  { label: 'Medical', value: 'medical' },
]
const DEFAULT_DAYS = [7, 30, 60, 90]

export const CHART_TYPE_OPTIONS = [
  { label: 'Both', value: 'both' },
  { label: 'Crime', value: 'crime' },
  { label: 'Medical', value: 'medical' },
]

/**
 * compact={true}  → icon-only 26px button, active dot, tags inside panel   (stat cards)
 * compact={false} → "Query ▼" labeled button, tags shown left of button    (charts/graphs)
 */
export default function QueryBox({
  typeOptions = DEFAULT_TYPE,
  dayOptions = DEFAULT_DAYS,
  showType = true,
  showDays = true,
  initialType = null,
  initialDays = null,
  compact = false,
  onApply,
}) {
  const defType = initialType ?? typeOptions[0].value
  const defDays = initialDays ?? dayOptions[0]

  const [isOpen, setIsOpen] = useState(false)
  const [pendingType, setPendingType] = useState(defType)
  const [pendingDays, setPendingDays] = useState(defDays)
  const [tags, setTags] = useState([])
  const [panelPos, setPanelPos] = useState({ top: 0, right: 0 })
  const btnRef = useRef(null)
  const panelRef = useRef(null)

  const updatePos = useCallback(() => {
    if (btnRef.current) {
      const rect = btnRef.current.getBoundingClientRect()
      let right = window.innerWidth - rect.right
      if (right < 8) right = 8
      setPanelPos({ top: rect.bottom + 6, right })
    }
  }, [])

  const openPanel = () => {
    if (!isOpen) updatePos()
    setIsOpen(v => !v)
  }

  useEffect(() => {
    if (!isOpen) return
    window.addEventListener('scroll', updatePos, true)
    window.addEventListener('resize', updatePos)
    return () => {
      window.removeEventListener('scroll', updatePos, true)
      window.removeEventListener('resize', updatePos)
    }
  }, [isOpen, updatePos])

  useEffect(() => {
    const out = (e) => {
      if (
        btnRef.current && !btnRef.current.contains(e.target) &&
        panelRef.current && !panelRef.current.contains(e.target)
      ) setIsOpen(false)
    }
    document.addEventListener('mousedown', out)
    return () => document.removeEventListener('mousedown', out)
  }, [])

  function apply() {
    const next = []
    if (pendingType !== typeOptions[0].value) next.push({ key: 'type', label: typeOptions.find(o => o.value === pendingType)?.label || pendingType })
    if (pendingDays !== dayOptions[0]) next.push({ key: 'days', label: `${pendingDays}d` })
    setTags(next)
    onApply?.({ type: pendingType, days: pendingDays })
    setIsOpen(false)
  }

  function reset() {
    setPendingType(typeOptions[0].value)
    setPendingDays(dayOptions[0])
    setTags([])
    onApply?.({ type: typeOptions[0].value, days: dayOptions[0] })
    setIsOpen(false)
  }

  function removeTag(key) {
    const nt = key === 'type' ? typeOptions[0].value : pendingType
    const nd = key === 'days' ? dayOptions[0] : pendingDays
    if (key === 'type') setPendingType(typeOptions[0].value)
    if (key === 'days') setPendingDays(dayOptions[0])
    setTags(prev => prev.filter(t => t.key !== key))
    onApply?.({ type: nt, days: nd })
  }

  const hasFilters = tags.length > 0

  const panel = isOpen ? createPortal(
    <div ref={panelRef} className="qb-panel" style={{ top: panelPos.top, right: panelPos.right }}>
      {/* Tags inside panel — only for compact mode */}
      {compact && tags.length > 0 && (
        <div className="qb-tags-row">
          {tags.map(tag => (
            <span key={tag.key} className="query-tag">
              {tag.label}
              <button type="button" className="query-tag-remove" onClick={() => removeTag(tag.key)}>
                <X size={9} />
              </button>
            </span>
          ))}
        </div>
      )}

      {showType && (
        <div className="qb-section">
          <div className="qb-label">Type</div>
          <div className="qb-pills">
            {typeOptions.map(opt => (
              <button key={opt.value} type="button"
                className={`qb-pill${pendingType === opt.value ? ' active' : ''}`}
                onClick={() => setPendingType(opt.value)}>
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      )}

      {showDays && (
        <div className="qb-section">
          <div className="qb-label">Period</div>
          <div className="qb-pills">
            {dayOptions.map(d => (
              <button key={d} type="button"
                className={`qb-pill${pendingDays === d ? ' active' : ''}`}
                onClick={() => setPendingDays(d)}>
                {d}d
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="qb-actions">
        <button type="button" className="qb-apply" onClick={apply}>Apply</button>
        <button type="button" className="qb-reset" onClick={reset}>Reset</button>
      </div>
    </div>,
    document.body
  ) : null

  /* ── COMPACT mode (stat cards) — icon only ── */
  if (compact) {
    return (
      <div style={{ position: 'relative', display: 'inline-flex' }}>
        <button
          ref={btnRef}
          type="button"
          className={`qb-btn${isOpen ? ' qb-open' : ''}${hasFilters ? ' qb-has-filters' : ''}`}
          onClick={openPanel}
          title="Query"
        >
          <SlidersHorizontal size={13} />
          {hasFilters && <span className="qb-dot" />}
        </button>
        {panel}
      </div>
    )
  }

  /* ── FULL mode (graphs) — labeled button with tags to the left ── */
  return (
    <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: '6px', flexShrink: 0 }}>
      {/* Active tags to the LEFT of button — Google Console style */}
      {tags.map(tag => (
        <span key={tag.key} className="query-tag">
          {tag.label}
          <button type="button" className="query-tag-remove" onClick={() => removeTag(tag.key)}>
            <X size={9} />
          </button>
        </span>
      ))}

      <button
        ref={btnRef}
        type="button"
        className={`qb-full-btn${isOpen ? ' active' : ''}`}
        onClick={openPanel}
      >
        <SlidersHorizontal size={11} />
        Query
        <ChevronDown size={11} style={{ transform: isOpen ? 'rotate(180deg)' : 'rotate(0)', transition: 'transform 0.2s' }} />
      </button>
      {panel}
    </div>
  )
}
