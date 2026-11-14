import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { Plus, Trash2, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { rupiah } from '../data'

type Option = { id: string; name: string }
type ServiceOption = { id: string; name: string; unit: string; price: number; speed: string }
type Line = { key: number; serviceId: string; quantity: string }

export default function OrderDialog({ organizationId, outlets, initialOutletId, onClose, onCreated }: { organizationId: string; outlets: Option[]; initialOutletId: string | null; onClose: () => void; onCreated: () => void }) {
  const [outletId, setOutletId] = useState(initialOutletId ?? outlets[0]?.id ?? '')
  const [customerId, setCustomerId] = useState('')
  const [customers, setCustomers] = useState<Option[]>([])
  const [services, setServices] = useState<ServiceOption[]>([])
  const [lines, setLines] = useState<Line[]>([{ key: 1, serviceId: '', quantity: '1' }])
  const [completion, setCompletion] = useState('')
  const [notes, setNotes] = useState('')
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function load() {
      const [customerResult, serviceResult, priceResult] = await Promise.all([
        supabase.from('customers').select('id, name').eq('organization_id', organizationId).eq('status', 'active').order('name'),
        supabase.from('services').select('id, name, unit').eq('organization_id', organizationId).eq('status', 'active').order('name'),
        supabase.from('service_prices').select('service_id, outlet_id, speed_type, price').eq('organization_id', organizationId).is('effective_until', null).lte('effective_from', new Date().toISOString()),
      ])
      const validPrices = (priceResult.data ?? []).filter(price => price.outlet_id === outletId || price.outlet_id === null)
      const priceByService = new Map<string, typeof validPrices[number]>()
      validPrices.sort((a, b) => Number(a.outlet_id !== null) - Number(b.outlet_id !== null)).forEach(price => priceByService.set(price.service_id, price))
      setCustomers(customerResult.data ?? [])
      setServices((serviceResult.data ?? []).flatMap(service => { const price = priceByService.get(service.id); return price ? [{ ...service, price: Number(price.price), speed: price.speed_type }] : [] }))
      setError(customerResult.error?.message ?? serviceResult.error?.message ?? priceResult.error?.message ?? '')
      setLoading(false)
    }
    load()
  }, [organizationId, outletId])

  const total = useMemo(() => lines.reduce((sum, line) => { const service = services.find(item => item.id === line.serviceId); return sum + (service?.price ?? 0) * (Number(line.quantity) || 0) }, 0), [lines, services])
  function updateLine(key: number, field: 'serviceId' | 'quantity', value: string) { setLines(current => current.map(line => line.key === key ? { ...line, [field]: value } : line)) }
  async function submit(event: FormEvent) {
    event.preventDefault(); setError('')
    const completeLines = lines.filter(line => line.serviceId && Number(line.quantity) > 0)
    if (!outletId || completeLines.length === 0) { setError('Pilih outlet dan minimal satu layanan.'); return }
    setBusy(true)
    const { error: rpcError } = await supabase.rpc('create_order', { target_outlet_id: outletId, target_customer_id: customerId || null, order_items: completeLines.map(line => ({ service_id: line.serviceId, quantity: Number(line.quantity), speed_type: services.find(service => service.id === line.serviceId)?.speed ?? 'regular' })), completion_at: completion ? new Date(completion).toISOString() : null, order_notes: notes || null })
    setBusy(false)
    if (rpcError) setError(rpcError.message); else onCreated()
  }

  return <><button className="modal-scrim" aria-label="Tutup dialog" onClick={onClose}/><section className="data-modal order-modal"><header><div><h2>Pesanan baru</h2><p>Harga dihitung otomatis dari katalog layanan.</p></div><button onClick={onClose}><X size={18}/></button></header>{loading ? <div className="data-state">Menyiapkan form kasir...</div> : <form onSubmit={submit}><div className="form-row"><label>Outlet<select value={outletId} onChange={event => setOutletId(event.target.value)} required><option value="">Pilih outlet</option>{outlets.map(outlet => <option key={outlet.id} value={outlet.id}>{outlet.name}</option>)}</select></label><label>Pelanggan<select value={customerId} onChange={event => setCustomerId(event.target.value)}><option value="">Pelanggan umum</option>{customers.map(customer => <option key={customer.id} value={customer.id}>{customer.name}</option>)}</select></label></div><div className="order-lines"><div className="order-lines-title"><strong>Item layanan</strong><button type="button" onClick={() => setLines(current => [...current, { key: Date.now(), serviceId: '', quantity: '1' }])}><Plus size={14}/>Tambah item</button></div>{lines.map((line, index) => <div className="order-line" key={line.key}><label>Layanan {index + 1}<select value={line.serviceId} onChange={event => updateLine(line.key, 'serviceId', event.target.value)} required><option value="">Pilih layanan</option>{services.map(service => <option key={service.id} value={service.id}>{service.name} · {rupiah(service.price)}/{service.unit}</option>)}</select></label><label>Jumlah<input type="number" min="0.001" step="0.001" value={line.quantity} onChange={event => updateLine(line.key, 'quantity', event.target.value)} required/></label><button type="button" className="remove-line" disabled={lines.length === 1} onClick={() => setLines(current => current.filter(item => item.key !== line.key))}><Trash2 size={16}/></button></div>)}</div>{services.length === 0 && <span className="form-error">Belum ada layanan dengan harga untuk outlet ini. Tambahkan melalui menu Layanan & Harga.</span>}<div className="form-row"><label>Estimasi selesai<input type="datetime-local" value={completion} onChange={event => setCompletion(event.target.value)}/></label><label>Catatan<input value={notes} onChange={event => setNotes(event.target.value)} placeholder="Instruksi pelanggan"/></label></div><div className="order-total"><span>Total pesanan</span><strong>{rupiah(total)}</strong></div>{error && <span className="form-error">{error}</span>}<footer><button type="button" className="button" onClick={onClose}>Batal</button><button className="button primary" disabled={busy || services.length === 0}>{busy ? 'Menyimpan...' : 'Simpan pesanan'}</button></footer></form>}</section></>
}
