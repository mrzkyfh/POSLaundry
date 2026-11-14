export type WorkStatus = 'Aktif' | 'Cuti' | 'Tidak aktif'
export type AttendanceStatus = 'Hadir' | 'Terlambat' | 'Izin' | 'Sakit' | 'Belum absen'

export interface Employee { id:string; name:string; role:string; outlet:string; employment:string; joined:string; status:WorkStatus; phone:string; email:string }
export interface Attendance { employeeId:string; shift:string; clockIn:string; clockOut:string; duration:string; late:string; status:AttendanceStatus }

export const employees: Employee[] = [
  {id:'EMP-001',name:'Andini Putri',role:'Kasir',outlet:'Outlet Kemang',employment:'Karyawan tetap',joined:'12 Januari 2024',status:'Aktif',phone:'0812 4401 9920',email:'andini@bersihlaundry.id'},
  {id:'EMP-002',name:'Wahyu Hidayat',role:'Petugas Produksi',outlet:'Outlet Kemang',employment:'Karyawan tetap',joined:'3 Maret 2024',status:'Aktif',phone:'0813 8802 1175',email:'wahyu@bersihlaundry.id'},
  {id:'EMP-003',name:'Rina Marlina',role:'Petugas Produksi',outlet:'Outlet Kemang',employment:'Karyawan kontrak',joined:'18 Mei 2025',status:'Aktif',phone:'0857 1120 3369',email:'rina@bersihlaundry.id'},
  {id:'EMP-004',name:'Dinda Larasati',role:'Quality Control',outlet:'Outlet Kemang',employment:'Karyawan tetap',joined:'7 Agustus 2024',status:'Aktif',phone:'0821 7750 2011',email:'dinda@bersihlaundry.id'},
  {id:'EMP-005',name:'Bambang Irawan',role:'Petugas Produksi',outlet:'Outlet Tebet',employment:'Karyawan tetap',joined:'22 Februari 2024',status:'Aktif',phone:'0819 3551 8842',email:'bambang@bersihlaundry.id'},
  {id:'EMP-006',name:'Sri Wahyuni',role:'Petugas Produksi',outlet:'Outlet Tebet',employment:'Karyawan kontrak',joined:'14 September 2025',status:'Cuti',phone:'0812 9901 4432',email:'sri@bersihlaundry.id'},
  {id:'EMP-007',name:'Fikri Maulana',role:'Kurir',outlet:'Outlet Tebet',employment:'Karyawan kontrak',joined:'5 Oktober 2025',status:'Aktif',phone:'0856 2217 3400',email:'fikri@bersihlaundry.id'},
]

export const attendances: Attendance[] = [
  {employeeId:'EMP-001',shift:'Pagi · 08.00–16.00',clockIn:'07.53',clockOut:'—',duration:'6j 37m',late:'—',status:'Hadir'},
  {employeeId:'EMP-002',shift:'Pagi · 08.00–16.00',clockIn:'08.17',clockOut:'—',duration:'6j 13m',late:'17 menit',status:'Terlambat'},
  {employeeId:'EMP-003',shift:'Pagi · 08.00–16.00',clockIn:'07.58',clockOut:'—',duration:'6j 32m',late:'—',status:'Hadir'},
  {employeeId:'EMP-004',shift:'Siang · 10.00–18.00',clockIn:'09.56',clockOut:'—',duration:'4j 34m',late:'—',status:'Hadir'},
  {employeeId:'EMP-005',shift:'Pagi · 08.00–16.00',clockIn:'08.09',clockOut:'—',duration:'6j 21m',late:'9 menit',status:'Terlambat'},
  {employeeId:'EMP-006',shift:'Pagi · 08.00–16.00',clockIn:'—',clockOut:'—',duration:'—',late:'—',status:'Izin'},
  {employeeId:'EMP-007',shift:'Siang · 10.00–18.00',clockIn:'—',clockOut:'—',duration:'—',late:'—',status:'Belum absen'},
]
