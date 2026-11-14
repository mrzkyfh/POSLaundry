import { Construction } from 'lucide-react'
import { useLocation } from 'react-router-dom'
import PageHeader from '../components/PageHeader'

export default function PlaceholderPage(){const path=useLocation().pathname;const name=path.split('/').pop()?.replaceAll('-',' ')||'Modul';return <main><PageHeader eyebrow="Laundry Business OS" title={name.replace(/\b\w/g,c=>c.toUpperCase())} description="Modul ini akan dibangun pada tahap UI/UX berikutnya."/><div className="placeholder"><Construction size={28}/><h2>Modul sedang disiapkan</h2><p>Struktur navigasi sudah tersedia agar alur antarfitur tetap konsisten.</p></div></main>}
