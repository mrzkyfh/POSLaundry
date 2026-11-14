import { useEffect, useMemo, useState } from 'react'
import { Download, Filter, Plus, Search } from 'lucide-react'
import { Link } from 'react-router-dom'
import PageHeader from '../components/PageHeader'
import { rupiah } from '../data'
import { supabase } from '../../lib/supabase'
import { useOrganization } from '../organization'
import OrderDialog from '../components/OrderDialog'

type OrderRow = { id: string; outlet_id: string; customer_id: string | null; order_number: string; grand_total: number; production_status: string; payment_status: string; estimated_completion_at: string | null; created_at: string }
type Lookup = Record<string, string>
const productionLabels: Lookup = { received: 'Baru', sorting: 'Penyortiran', washing: 'Dicuci', drying: 'Dikeringkan', ironing: 'Disetrika', quality_control: 'Quality control', ready: 'Siap diambil', completed: 'Selesai', cancelled: 'Dibatalkan' }
const paymentLabels: Lookup = { unpaid: 'Belum dibayar', partially_paid: 'Dibayar sebagian', paid: 'Lunas', refunded: 'Dikembalikan' }
const dateTime = (value: string | null) => value ? new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : '—'

export default function OrdersPage() {
  const { organization, outlets: outletOptions, activeOutletId } = useOrganization()
  const [orders, setOrders] = useState<OrderRow[]>([])
  const [customers, setCustomers] = useState<Lookup>({})
  const [outlets, setOutlets] = useState<Lookup>({})
  const [search, setSearch] = useState('')
  const [productionFilter, setProductionFilter] = useState('')
  const [paymentFilter, setPaymentFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [reloadVersion, setReloadVersion] = useState(0)

  useEffect(() => {
    if (!organization) return
    let active = true
    async function load() {
      setLoading(true)
      let orderQuery = supabase.from('orders').select('id, outlet_id, customer_id, order_number, grand_total, production_status, payment_status, estimated_completion_at, created_at').eq('organization_id', organization!.id).order('created_at', { ascending: false })
      if (activeOutletId) orderQuery = orderQuery.eq('outlet_id', activeOutletId)
      const [orderResult, customerResult, outletResult] = await Promise.all([
        orderQuery,
        supabase.from('customers').select('id, name').eq('organization_id', organization!.id),
        supabase.from('outlets').select('id, name').eq('organization_id', organization!.id),
      ])
      if (!active) return
      setOrders(orderResult.data ?? [])
      setCustomers(Object.fromEntries((customerResult.data ?? []).map(item => [item.id, item.name])))
      setOutlets(Object.fromEntries((outletResult.data ?? []).map(item => [item.id, item.name])))
      setError(orderResult.error?.message ?? '')
      setLoading(false)
    }
    load()
    return () => { active = false }
  }, [organization?.id, activeOutletId, reloadVersion])

  const filtered = useMemo(() => orders.filter(order => {
    const term = search.trim().toLowerCase()
    const matchesSearch = !term || `${order.order_number} ${order.customer_id ? customers[order.customer_id] ?? '' : ''}`.toLowerCase().includes(term)
    return matchesSearch && (!productionFilter || order.production_status === productionFilter) && (!paymentFilter || order.payment_status === paymentFilter)
  }), [orders, customers, search, productionFilter, paymentFilter])
  const today = new Date().toDateString()
  const todayCount = orders.filter(order => new Date(order.created_at).toDateString() === today).length
  const activeCount = orders.filter(order => !['completed', 'cancelled'].includes(order.production_status)).length
  const readyCount = orders.filter(order => order.production_status === 'ready').length
  const unpaidTotal = orders.filter(order => order.payment_status !== 'paid').reduce((total, order) => total + Number(order.grand_total), 0)

  return <main>
    <PageHeader eyebrow="Operasional / Pesanan" title="Manajemen Pesanan" description="Data pesanan langsung dari Supabase untuk organisasi dan outlet aktif." actions={<button className="button primary" onClick={() => setDialogOpen(true)}><Plus size={16}/>Pesanan baru</button>}/>
    <section className="summary-strip"><div><span>Pesanan hari ini</span><strong>{todayCount}</strong></div><div><span>Dalam proses</span><strong>{activeCount}</strong></div><div><span>Siap diambil</span><strong>{readyCount}</strong></div><div><span>Total pesanan</span><strong>{orders.length}</strong></div><div><span>Belum lunas</span><strong>{rupiah(unpaidTotal)}</strong></div></section>
    <section className="panel"><div className="toolbar"><label><Search size={16}/><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Cari nomor pesanan atau pelanggan"/></label><select value={productionFilter} onChange={event => setProductionFilter(event.target.value)} aria-label="Status produksi"><option value="">Semua status produksi</option>{Object.entries(productionLabels).map(([value,label]) => <option key={value} value={value}>{label}</option>)}</select><select value={paymentFilter} onChange={event => setPaymentFilter(event.target.value)} aria-label="Status pembayaran"><option value="">Semua pembayaran</option>{Object.entries(paymentLabels).map(([value,label]) => <option key={value} value={value}>{label}</option>)}</select><button className="button secondary"><Filter size={15}/>Filter</button><button className="icon-button"><Download size={17}/></button></div>
      {error && <div className="data-state error-state">Gagal memuat pesanan: {error}</div>}
      {!error && loading && <div className="data-state">Memuat data pesanan...</div>}
      {!error && !loading && <div className="table-wrap"><table><thead><tr><th>No. pesanan</th><th>Pelanggan</th><th>Outlet</th><th>Diterima</th><th className="right">Total</th><th>Status produksi</th><th>Status pembayaran</th><th>Estimasi selesai</th></tr></thead><tbody>{filtered.map(order => <tr key={order.id}><td><Link to={`/orders/${order.id}`}>{order.order_number}</Link></td><td><strong>{order.customer_id ? customers[order.customer_id] ?? 'Pelanggan' : 'Pelanggan umum'}</strong></td><td>{outlets[order.outlet_id] ?? '—'}</td><td>{dateTime(order.created_at)}</td><td className="right">{rupiah(Number(order.grand_total))}</td><td><span className="status status-blue"><i/>{productionLabels[order.production_status] ?? order.production_status}</span></td><td><span className={`status ${order.payment_status === 'paid' ? 'status-green' : 'status-amber'}`}><i/>{paymentLabels[order.payment_status] ?? order.payment_status}</span></td><td>{dateTime(order.estimated_completion_at)}</td></tr>)}</tbody></table>{filtered.length === 0 && <div className="data-state">Belum ada pesanan yang sesuai filter.</div>}</div>}
      <div className="pagination"><span>Menampilkan {filtered.length} dari {orders.length} pesanan</span></div>
    </section>
    {dialogOpen && organization && <OrderDialog organizationId={organization.id} outlets={outletOptions} initialOutletId={activeOutletId} onClose={() => setDialogOpen(false)} onCreated={() => { setDialogOpen(false); setReloadVersion(value => value + 1) }}/>} 
  </main>
}
