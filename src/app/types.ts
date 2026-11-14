export type OrderStatus = 'Baru' | 'Dalam proses' | 'Quality control' | 'Siap diambil' | 'Selesai' | 'Terlambat'
export type PaymentStatus = 'Belum dibayar' | 'Dibayar sebagian' | 'Lunas'

export interface Order {
  id: string
  customer: string
  phone: string
  service: string
  quantity: string
  total: number
  paid: number
  productionStatus: OrderStatus
  paymentStatus: PaymentStatus
  outlet: string
  receivedAt: string
  dueAt: string
  notes?: string
}
