import type { ReactNode } from 'react'

export default function PageHeader({ eyebrow, title, description, actions }: { eyebrow:string; title:string; description:string; actions?:ReactNode }) {
  return <div className="page-header"><div><p>{eyebrow}</p><h1>{title}</h1><span>{description}</span></div>{actions && <div className="page-actions">{actions}</div>}</div>
}
