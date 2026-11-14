import type { Order } from './types'

export const orders: Order[] = [
  { id:'LDY-261114-0187', customer:'Dewi Anggraini', phone:'0812 3456 7890', service:'Cuci Setrika Reguler', quantity:'6,4 kg', total:115200, paid:50000, productionStatus:'Dalam proses', paymentStatus:'Dibayar sebagian', outlet:'Outlet Kemang', receivedAt:'14 November 2026, 08.42 WIB', dueAt:'14 November 2026, 17.00 WIB', notes:'Pisahkan pakaian putih. Gunakan pewangi Sakura.' },
  { id:'LDY-261114-0186', customer:'Rizky Pratama', phone:'0813 8871 2210', service:'Dry Clean', quantity:'3 pcs', total:210000, paid:210000, productionStatus:'Quality control', paymentStatus:'Lunas', outlet:'Outlet Kemang', receivedAt:'14 November 2026, 08.15 WIB', dueAt:'14 November 2026, 15.30 WIB' },
  { id:'LDY-261114-0185', customer:'Siti Rahmawati', phone:'0857 1902 4431', service:'Cuci Kering Reguler', quantity:'4,8 kg', total:67200, paid:0, productionStatus:'Siap diambil', paymentStatus:'Belum dibayar', outlet:'Outlet Tebet', receivedAt:'14 November 2026, 07.48 WIB', dueAt:'14 November 2026, 14.00 WIB' },
  { id:'LDY-261113-0181', customer:'Budi Santoso', phone:'0819 2201 5502', service:'Cuci Setrika Reguler', quantity:'8,2 kg', total:147600, paid:70000, productionStatus:'Terlambat', paymentStatus:'Dibayar sebagian', outlet:'Outlet Tebet', receivedAt:'13 November 2026, 09.20 WIB', dueAt:'13 November 2026, 18.00 WIB' },
  { id:'LDY-261113-0179', customer:'Nadia Putri', phone:'0821 4478 9901', service:'Setrika Reguler', quantity:'5,0 kg', total:60000, paid:60000, productionStatus:'Selesai', paymentStatus:'Lunas', outlet:'Outlet Kemang', receivedAt:'13 November 2026, 08.55 WIB', dueAt:'13 November 2026, 16.00 WIB' },
  { id:'LDY-261113-0178', customer:'Andi Kurniawan', phone:'0812 7712 0991', service:'Cuci Setrika Ekspres', quantity:'3,6 kg', total:97200, paid:97200, productionStatus:'Selesai', paymentStatus:'Lunas', outlet:'Outlet Kemang', receivedAt:'13 November 2026, 08.32 WIB', dueAt:'13 November 2026, 14.30 WIB' },
]

export const rupiah = (value: number) => new Intl.NumberFormat('id-ID', { style:'currency', currency:'IDR', maximumFractionDigits:0 }).format(value)
