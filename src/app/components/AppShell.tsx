import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { BarChart3, Bell, Boxes, CalendarDays, ChevronDown, CircleDollarSign, ClipboardCheck, Command, Contact, HelpCircle, LayoutDashboard, Menu, Package, Search, Settings, ShoppingBag, Users, WalletCards, X } from 'lucide-react'
import { useOrganization } from '../organization'
import { supabase } from '../../lib/supabase'

const nav = [
  ['Ringkasan', [['Dashboard', '/', LayoutDashboard], ['Pusat Aktivitas', '/activity', ClipboardCheck]]],
  ['Operasional', [['Pesanan', '/orders', ShoppingBag], ['Layanan & Harga', '/services', Package], ['Produksi', '/production', Boxes], ['Quality Control', '/quality-control', ClipboardCheck]]],
  ['Tenaga Kerja', [['Karyawan', '/employees', Users], ['Absensi & Shift', '/attendance', CalendarDays], ['Penggajian', '/payroll', WalletCards]]],
  ['Bisnis', [['Keuangan', '/finance', CircleDollarSign], ['Inventaris', '/inventory', Package], ['Pelanggan', '/customers', Contact], ['Analitik', '/analytics', BarChart3]]],
] as const

export default function AppShell() {
  const [open, setOpen] = useState(false)
  const { organization, outlets, activeOutletId, setActiveOutletId } = useOrganization()
  const initials = organization?.name.split(' ').map(part => part[0]).join('').slice(0, 2).toUpperCase() || 'LO'
  return <div className="app">
    {open && <button className="nav-scrim" aria-label="Tutup menu" onClick={()=>setOpen(false)} />}
    <aside className={open ? 'sidebar is-open' : 'sidebar'}>
      <div className="brand"><span><Command size={18}/></span>Laundry OS<button onClick={()=>setOpen(false)}><X size={18}/></button></div>
      <nav>{nav.map(([group,items])=><section key={group}><p>{group}</p>{items.map(([label,path,Icon])=><NavLink key={path} to={path} end={path === '/'} onClick={()=>setOpen(false)}><Icon size={17}/>{label}</NavLink>)}</section>)}</nav>
      <div className="sidebar-footer"><NavLink to="/settings"><Settings size={17}/>Pengaturan</NavLink><a href="#help"><HelpCircle size={17}/>Bantuan</a><button className="account account-button" onClick={() => supabase.auth.signOut()} title="Keluar dari akun"><span>{initials}</span><div><strong>{organization?.name ?? 'Laundry OS'}</strong><small>{organization?.role ?? 'Memuat...'}</small></div></button></div>
    </aside>
    <div className="workspace">
      <header className="topbar"><button className="menu-button" onClick={()=>setOpen(true)}><Menu size={20}/></button><button className="organization"><span>{initials}</span><div><small>Organisasi</small><strong>{organization?.name ?? 'Memuat...'}</strong></div></button><label className="outlet outlet-select">Outlet<select value={activeOutletId ?? ''} onChange={event => setActiveOutletId(event.target.value || null)}><option value="">Semua outlet</option>{outlets.map(outlet => <option key={outlet.id} value={outlet.id}>{outlet.name}</option>)}</select><ChevronDown size={15}/></label><label className="search"><Search size={17}/><input placeholder="Cari pesanan, pelanggan, karyawan..."/><kbd>⌘ K</kbd></label><button className="icon-button"><Bell size={19}/><i/></button><span className="top-avatar">{initials}</span></header>
      <Outlet/>
    </div>
  </div>
}
