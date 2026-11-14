import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { supabase } from '../lib/supabase'

type Organization = { id: string; name: string; role: string }
type Outlet = { id: string; name: string; code: string }
type OrganizationContextValue = { organization: Organization | null; outlets: Outlet[]; activeOutletId: string | null; setActiveOutletId: (id: string | null) => void; loading: boolean }
const OrganizationContext = createContext<OrganizationContextValue | null>(null)

export function OrganizationProvider({ children }: { children: ReactNode }) {
  const [organization, setOrganization] = useState<Organization | null>(null)
  const [outlets, setOutlets] = useState<Outlet[]>([])
  const [activeOutletId, setActiveOutletId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    let active = true
    async function load() {
      const { data: membership } = await supabase.from('organization_memberships').select('organization_id, role').eq('status', 'active').limit(1).maybeSingle()
      if (!membership || !active) { if (active) setLoading(false); return }
      const [{ data: organizationData }, { data: outletData }] = await Promise.all([
        supabase.from('organizations').select('id, name').eq('id', membership.organization_id).single(),
        supabase.from('outlets').select('id, name, code').eq('organization_id', membership.organization_id).eq('status', 'active').order('name'),
      ])
      if (!active) return
      if (organizationData) setOrganization({ ...organizationData, role: membership.role })
      setOutlets(outletData ?? [])
      setLoading(false)
    }
    load()
    return () => { active = false }
  }, [])
  const value = useMemo(() => ({ organization, outlets, activeOutletId, setActiveOutletId, loading }), [organization, outlets, activeOutletId, loading])
  return <OrganizationContext.Provider value={value}>{children}</OrganizationContext.Provider>
}

export function useOrganization() {
  const value = useContext(OrganizationContext)
  if (!value) throw new Error('useOrganization harus digunakan di dalam OrganizationProvider')
  return value
}
