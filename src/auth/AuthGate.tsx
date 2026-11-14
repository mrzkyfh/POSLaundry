import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { Building2, LoaderCircle, LockKeyhole, Mail } from 'lucide-react'
import { supabase } from '../lib/supabase'
import './auth.css'

type GateState = 'loading' | 'login' | 'bootstrap' | 'ready'

export default function AuthGate({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [state, setState] = useState<GateState>('loading')

  useEffect(() => {
    const resolve = async (nextSession: Session | null) => {
      setSession(nextSession)
      if (!nextSession) return setState('login')
      const { data, error } = await supabase.from('organization_memberships').select('id').limit(1)
      if (error) return setState('bootstrap')
      setState(data.length ? 'ready' : 'bootstrap')
    }
    supabase.auth.getSession().then(({ data }) => resolve(data.session))
    const { data } = supabase.auth.onAuthStateChange((_event, next) => resolve(next))
    return () => data.subscription.unsubscribe()
  }, [])

  if (state === 'loading') return <div className="auth-loading"><LoaderCircle className="spin"/><span>Menyiapkan Laundry OS...</span></div>
  if (state === 'login') return <LoginPage />
  if (state === 'bootstrap' && session) return <BootstrapPage onComplete={() => setState('ready')} />
  return children
}

function LoginPage() {
  const [mode, setMode] = useState<'login' | 'register'>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setBusy(true); setMessage('')
    const result = mode === 'login'
      ? await supabase.auth.signInWithPassword({ email, password })
      : await supabase.auth.signUp({ email, password })
    setBusy(false)
    if (result.error) setMessage(result.error.message)
    else if (mode === 'register' && !result.data.session) setMessage('Periksa email untuk mengonfirmasi akun, lalu masuk kembali.')
  }
  return <div className="auth-page"><section className="auth-card"><div className="auth-brand"><span>BL</span><div><strong>Laundry Business OS</strong><small>Masuk ke pusat kendali bisnis Anda</small></div></div><h1>{mode === 'login' ? 'Selamat datang kembali' : 'Buat akun pemilik'}</h1><p>{mode === 'login' ? 'Masukkan akun yang terdaftar untuk melanjutkan.' : 'Akun pertama akan menyiapkan organisasi dan outlet utama.'}</p><form onSubmit={submit}><label>Email<div><Mail size={16}/><input type="email" value={email} onChange={e => setEmail(e.target.value)} required placeholder="nama@usaha.id"/></div></label><label>Kata sandi<div><LockKeyhole size={16}/><input type="password" value={password} onChange={e => setPassword(e.target.value)} required minLength={8} placeholder="Minimal 8 karakter"/></div></label>{message && <span className="auth-message">{message}</span>}<button disabled={busy}>{busy ? 'Memproses...' : mode === 'login' ? 'Masuk' : 'Buat akun'}</button></form><footer>{mode === 'login' ? 'Belum memiliki akun?' : 'Sudah memiliki akun?'} <button onClick={() => { setMode(mode === 'login' ? 'register' : 'login'); setMessage('') }}>{mode === 'login' ? 'Daftar sebagai pemilik' : 'Masuk'}</button></footer></section></div>
}

function BootstrapPage({ onComplete }: { onComplete: () => void }) {
  const [organizationName, setOrganizationName] = useState('')
  const [outletName, setOutletName] = useState('Outlet Utama')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setBusy(true); setMessage('')
    const { error } = await supabase.rpc('bootstrap_owner', { organization_name: organizationName, outlet_name: outletName })
    setBusy(false)
    if (error) setMessage(error.message); else onComplete()
  }
  return <div className="auth-page"><section className="auth-card"><div className="bootstrap-icon"><Building2/></div><h1>Siapkan bisnis Anda</h1><p>Buat organisasi dan outlet pertama. Anda otomatis menjadi pemilik.</p><form onSubmit={submit}><label>Nama usaha<div><input value={organizationName} onChange={e => setOrganizationName(e.target.value)} required minLength={2} placeholder="Contoh: Bersih Laundry"/></div></label><label>Nama outlet utama<div><input value={outletName} onChange={e => setOutletName(e.target.value)} required minLength={2}/></div></label>{message && <span className="auth-message">{message}</span>}<button disabled={busy}>{busy ? 'Menyiapkan...' : 'Mulai menggunakan Laundry OS'}</button></form><button className="signout" onClick={() => supabase.auth.signOut()}>Keluar dari akun</button></section></div>
}
