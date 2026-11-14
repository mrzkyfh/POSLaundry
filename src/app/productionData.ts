export type Stage = 'Diterima' | 'Sortir' | 'Dicuci' | 'Dikeringkan' | 'Disetrika' | 'Quality Control' | 'Siap Diambil'
export type Priority = 'Normal' | 'Prioritas' | 'Terlambat'

export interface ProductionTask {
  id: string
  orderId: string
  customer: string
  service: string
  quantity: string
  stage: Stage
  assignee: string
  due: string
  priority: Priority
  outlet: string
}

export const stages: Stage[] = ['Diterima','Sortir','Dicuci','Dikeringkan','Disetrika','Quality Control','Siap Diambil']

export const productionTasks: ProductionTask[] = [
  {id:'PRD-1047',orderId:'LDY-261114-0194',customer:'Yuni Kartika',service:'Cuci Setrika Reguler',quantity:'7,2 kg',stage:'Diterima',assignee:'Belum ditugaskan',due:'18.30 WIB',priority:'Normal',outlet:'Outlet Kemang'},
  {id:'PRD-1046',orderId:'LDY-261114-0193',customer:'Fajar Ramadhan',service:'Cuci Kering Ekspres',quantity:'4,5 kg',stage:'Sortir',assignee:'Rina Marlina',due:'16.45 WIB',priority:'Prioritas',outlet:'Outlet Kemang'},
  {id:'PRD-1045',orderId:'LDY-261114-0187',customer:'Dewi Anggraini',service:'Cuci Setrika Reguler',quantity:'6,4 kg',stage:'Dicuci',assignee:'Wahyu Hidayat',due:'17.00 WIB',priority:'Normal',outlet:'Outlet Kemang'},
  {id:'PRD-1044',orderId:'LDY-261114-0189',customer:'Rafi Akbar',service:'Cuci Setrika Ekspres',quantity:'3,8 kg',stage:'Dicuci',assignee:'Bambang Irawan',due:'15.15 WIB',priority:'Terlambat',outlet:'Outlet Tebet'},
  {id:'PRD-1043',orderId:'LDY-261114-0188',customer:'Maya Sari',service:'Cuci Kering Reguler',quantity:'5,1 kg',stage:'Dikeringkan',assignee:'Wahyu Hidayat',due:'17.30 WIB',priority:'Normal',outlet:'Outlet Kemang'},
  {id:'PRD-1042',orderId:'LDY-261114-0184',customer:'Dian Permata',service:'Cuci Setrika Reguler',quantity:'8,3 kg',stage:'Disetrika',assignee:'Sri Wahyuni',due:'16.00 WIB',priority:'Prioritas',outlet:'Outlet Tebet'},
  {id:'PRD-1041',orderId:'LDY-261114-0186',customer:'Rizky Pratama',service:'Dry Clean',quantity:'3 pcs',stage:'Quality Control',assignee:'Dinda Larasati',due:'15.30 WIB',priority:'Normal',outlet:'Outlet Kemang'},
  {id:'PRD-1040',orderId:'LDY-261114-0183',customer:'Lina Kusuma',service:'Cuci Setrika Reguler',quantity:'9,0 kg',stage:'Quality Control',assignee:'Dinda Larasati',due:'14.45 WIB',priority:'Terlambat',outlet:'Outlet Tebet'},
  {id:'PRD-1039',orderId:'LDY-261114-0185',customer:'Siti Rahmawati',service:'Cuci Kering Reguler',quantity:'4,8 kg',stage:'Siap Diambil',assignee:'Andini Putri',due:'14.00 WIB',priority:'Normal',outlet:'Outlet Tebet'},
]
