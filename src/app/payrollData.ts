export type PayrollStatus = 'Draft' | 'Review' | 'Disetujui' | 'Dibayar sebagian' | 'Dibayar'
export interface Payroll { id:string; employeeId:string; name:string; role:string; base:number; allowance:number; overtime:number; incentive:number; deduction:number; paid:number; status:PayrollStatus }
export const payrolls: Payroll[] = [
  {id:'PAY-1126-001',employeeId:'EMP-001',name:'Andini Putri',role:'Kasir',base:4200000,allowance:450000,overtime:275000,incentive:180000,deduction:150000,paid:0,status:'Review'},
  {id:'PAY-1126-002',employeeId:'EMP-002',name:'Wahyu Hidayat',role:'Petugas Produksi',base:3900000,allowance:400000,overtime:360000,incentive:575000,deduction:300000,paid:4935000,status:'Dibayar'},
  {id:'PAY-1126-003',employeeId:'EMP-003',name:'Rina Marlina',role:'Petugas Produksi',base:3600000,allowance:400000,overtime:180000,incentive:460000,deduction:250000,paid:2195000,status:'Dibayar sebagian'},
  {id:'PAY-1126-004',employeeId:'EMP-004',name:'Dinda Larasati',role:'Quality Control',base:4100000,allowance:450000,overtime:220000,incentive:325000,deduction:0,paid:0,status:'Disetujui'},
  {id:'PAY-1126-005',employeeId:'EMP-005',name:'Bambang Irawan',role:'Petugas Produksi',base:3900000,allowance:400000,overtime:315000,incentive:510000,deduction:500000,paid:0,status:'Review'},
  {id:'PAY-1126-006',employeeId:'EMP-006',name:'Sri Wahyuni',role:'Petugas Produksi',base:3500000,allowance:300000,overtime:0,incentive:270000,deduction:200000,paid:0,status:'Draft'},
]
export const netPay=(p:Payroll)=>p.base+p.allowance+p.overtime+p.incentive-p.deduction
