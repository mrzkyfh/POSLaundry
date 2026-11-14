import type { PaymentStatus, OrderStatus } from '../types'

const tones: Record<OrderStatus | PaymentStatus, string> = {
  'Baru':'blue', 'Dalam proses':'amber', 'Quality control':'violet', 'Siap diambil':'green', 'Selesai':'slate', 'Terlambat':'red',
  'Belum dibayar':'red', 'Dibayar sebagian':'amber', 'Lunas':'green',
}

export default function StatusBadge({ value }: { value: OrderStatus | PaymentStatus }) {
  return <span className={`status status-${tones[value]}`}><i />{value}</span>
}
