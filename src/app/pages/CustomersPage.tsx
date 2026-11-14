import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { Download, MoreHorizontal, Plus, Search, X } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import { supabase } from '../../lib/supabase'
import { useOrganization } from '../organization'

type CustomerRow = { id: string; name: string; phone: string | null; email: string | null; status: string; created_at: string }
const formatDate = (value: string) => new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' }).format(new Date(value))

export default function CustomersPage() {
  const { organization } = useOrganization()
  const [customers, setCustomers] = useState<CustomerRow[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [open, setOpen] = useState(false)
  const [error, setError] = useState('')

  async function loadCustomers() {
    if (!organization) return
    setLoading(true)
    const { data, error: queryError } = await supabase.from('customers').select('id, name, phone, email, status, created_at').eq('organization_id', organization.id).order('created_at', { ascending: false })
    setCustomers(data ?? [])
    setError(queryError?.message ?? '')
    setLoading(false)
  }

  useEffect(() => { loadCustomers() }, [organization?.id])
  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase()
    return term ? customers.filter(customer => `${customer.name} ${customer.phone ?? ''} ${customer.email ?? ''}`.toLowerCase().includes(term)) : customers
  }, [customers, search])

  return <main>
    <PageHeader eyebrow="Bisnis / Pelanggan" title="Pelanggan" description="Kelola profil dan hubungan pelanggan dari data Supabase." actions={<button className="button primary" onClick={() => setOpen(true)}><Plus size={16}/>Tambah pelanggan</button>}/>
    <section className="customer-summary"><div><span>Total pelanggan</span><strong>{customers.length}</strong><small>Organisasi aktif</small></div><div><span>Pelanggan aktif</span><strong>{customers.filter(customer => customer.status === 'active').length}</strong><small>Dapat menerima pesanan</small></div><div><span>Pelanggan baru</span><strong>{customers.filter(customer => Date.now() - new Date(customer.created_at).getTime() < 30 * 86400000).length}</strong><small>30 hari terakhir</small></div><div><span>Tidak aktif</span><strong>{customers.filter(customer => customer.status === 'inactive').length}</strong><small>Arsip pelanggan</small></div><div><span>Kontak lengkap</span><strong>{customers.filter(customer => customer.phone || customer.email).length}</strong><small>Telepon atau email tersedia</small></div></section>
    <section className="panel"><div className="toolbar"><label><Search size={16}/><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Cari nama, telepon, atau email"/></label><button className="icon-button" title="Ekspor data"><Download size={17}/></button></div>
      {error && <div className="data-state error-state">Gagal memuat pelanggan: {error}</div>}
      {!error && loading && <div className="data-state">Memuat data pelanggan...</div>}
      {!error && !loading && <div className="table-wrap"><table><thead><tr><th>Pelanggan</th><th>Nomor telepon</th><th>Email</th><th>Terdaftar</th><th>Status</th><th/></tr></thead><tbody>{filtered.map(customer => <tr key={customer.id}><td><div className="customer-cell"><span>{customer.name.split(' ').map(part => part[0]).join('').slice(0,2).toUpperCase()}</span><div><strong>{customer.name}</strong><small>{customer.id.slice(0,8)}</small></div></div></td><td>{customer.phone || '—'}</td><td>{customer.email || '—'}</td><td>{formatDate(customer.created_at)}</td><td><span className={`customer-status ${customer.status === 'active' ? 'aktif' : 'tidak-aktif'}`}><i/>{customer.status === 'active' ? 'Aktif' : 'Tidak aktif'}</span></td><td><button className="table-action"><MoreHorizontal size={17}/></button></td></tr>)}</tbody></table>{filtered.length === 0 && <div className="data-state">{search ? 'Pelanggan tidak ditemukan.' : 'Belum ada pelanggan. Tambahkan pelanggan pertama Anda.'}</div>}</div>}
      <div className="pagination"><span>Menampilkan {filtered.length} dari {customers.length} pelanggan</span></div>
    </section>
    {open && <CustomerDialog organizationId={organization?.id ?? ''} onClose={() => setOpen(false)} onCreated={() => { setOpen(false); loadCustomers() }}/>} 
  </main>
}

function CustomerDialog({ organizationId, onClose, onCreated }: { organizationId: string; onClose: () => void; onCreated: () => void }) {
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [notes, setNotes] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  async function submit(event: FormEvent) {
    event.preventDefault(); setBusy(true); setError('')
    const { error: insertError } = await supabase.from('customers').insert({ organization_id: organizationId, name: name.trim(), phone: phone.trim() || null, email: email.trim() || null, notes: notes.trim() || null })
    setBusy(false)
    if (insertError) setError(insertError.message); else onCreated()
  }
  return <><button className="modal-scrim" aria-label="Tutup dialog" onClick={onClose}/><section className="data-modal"><header><div><h2>Tambah pelanggan</h2><p>Simpan identitas pelanggan untuk digunakan pada pesanan.</p></div><button onClick={onClose}><X size={18}/></button></header><form onSubmit={submit}><label>Nama lengkap<input value={name} onChange={event => setName(event.target.value)} minLength={2} required autoFocus/></label><div className="form-row"><label>Nomor telepon<input value={phone} onChange={event => setPhone(event.target.value)} placeholder="08..."/></label><label>Email<input type="email" value={email} onChange={event => setEmail(event.target.value)} placeholder="nama@email.com"/></label></div><label>Catatan<textarea value={notes} onChange={event => setNotes(event.target.value)} rows={3}/></label>{error && <span className="form-error">{error}</span>}<footer><button type="button" className="button" onClick={onClose}>Batal</button><button className="button primary" disabled={busy || !organizationId}>{busy ? 'Menyimpan...' : 'Simpan pelanggan'}</button></footer></form></section></>
}
