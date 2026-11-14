export type CustomerStatus='Aktif'|'Berisiko tidak kembali'|'Tidak aktif'
export interface Customer{id:string;name:string;phone:string;orders:number;spend:number;lastOrder:string;status:CustomerStatus;points:number;memberSince:string;tags:string[]}
export const customers:Customer[]=[
  {id:'CUS-00128',name:'Dewi Anggraini',phone:'0812 3456 7890',orders:38,spend:4875000,lastOrder:'14 November 2026',status:'Aktif',points:1280,memberSince:'12 Februari 2025',tags:['VIP','Reguler mingguan']},
  {id:'CUS-00127',name:'Rizky Pratama',phone:'0813 8871 2210',orders:24,spend:3290000,lastOrder:'14 November 2026',status:'Aktif',points:840,memberSince:'8 April 2025',tags:['Dry clean']},
  {id:'CUS-00126',name:'Siti Rahmawati',phone:'0857 1902 4431',orders:17,spend:1785000,lastOrder:'14 November 2026',status:'Aktif',points:420,memberSince:'21 Juni 2025',tags:['Sering telat ambil']},
  {id:'CUS-00125',name:'Budi Santoso',phone:'0819 2201 5502',orders:12,spend:1480000,lastOrder:'13 November 2026',status:'Aktif',points:310,memberSince:'17 Juli 2025',tags:['Piutang aktif']},
  {id:'CUS-00124',name:'Nadia Putri',phone:'0821 4478 9901',orders:29,spend:3625000,lastOrder:'13 November 2026',status:'Aktif',points:970,memberSince:'3 Januari 2025',tags:['VIP']},
  {id:'CUS-00098',name:'Arif Nugroho',phone:'0812 6654 1120',orders:8,spend:875000,lastOrder:'27 Agustus 2026',status:'Berisiko tidak kembali',points:180,memberSince:'19 Maret 2025',tags:['Tidak kembali 79 hari']},
  {id:'CUS-00074',name:'Putri Amelia',phone:'0856 3310 7702',orders:4,spend:420000,lastOrder:'2 Mei 2026',status:'Tidak aktif',points:90,memberSince:'11 November 2024',tags:[]},
]
