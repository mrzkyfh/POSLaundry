export type StockStatus='Aman'|'Stok rendah'|'Habis'
export interface InventoryItem{id:string;sku:string;name:string;stock:number;unit:string;minimum:number;outlet:string;status:StockStatus;value:number}
export const inventoryItems:InventoryItem[]=[
  {id:'INV-001',sku:'DET-LIQ-5L',name:'Deterjen Cair',stock:18.5,unit:'liter',minimum:20,outlet:'Semua Outlet',status:'Stok rendah',value:555000},
  {id:'INV-002',sku:'FRG-SAK-5L',name:'Pewangi Laundry Sakura',stock:26,unit:'liter',minimum:15,outlet:'Semua Outlet',status:'Aman',value:1040000},
  {id:'INV-003',sku:'SFT-5L',name:'Pelembut Pakaian',stock:14,unit:'liter',minimum:10,outlet:'Semua Outlet',status:'Aman',value:420000},
  {id:'INV-004',sku:'PKG-60',name:'Plastik Packing 60 cm',stock:42,unit:'lembar',minimum:50,outlet:'Outlet Kemang',status:'Stok rendah',value:126000},
  {id:'INV-005',sku:'HGR-BLK',name:'Hanger Plastik Hitam',stock:185,unit:'pcs',minimum:100,outlet:'Semua Outlet',status:'Aman',value:370000},
  {id:'INV-006',sku:'TAG-WHT',name:'Label Tag Putih',stock:0,unit:'roll',minimum:3,outlet:'Outlet Tebet',status:'Habis',value:0},
]
export const movements=[
  ['14 Nov 2026, 13.48','Pembelian','PO-2611-0018','+25,0 liter','30,0 liter','Andini Putri'],
  ['14 Nov 2026, 11.32','Konsumsi produksi','LDY-261114-0187','−0,3 liter','5,0 liter','Wahyu Hidayat'],
  ['14 Nov 2026, 10.15','Konsumsi produksi','LDY-261114-0188','−0,2 liter','5,3 liter','Rina Marlina'],
  ['13 Nov 2026, 17.40','Penyesuaian stok','ADJ-261113-0004','−0,5 liter','5,5 liter','Ratna Wulandari'],
]
