import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useOrganization } from './organization'

export type LiveProductionTask = { id:string; number:string; customer:string; outlet:string; status:string; due:string|null; total:number; createdAt:string }
export const productionStages=[['received','Diterima'],['sorting','Sortir'],['washing','Dicuci'],['drying','Dikeringkan'],['ironing','Disetrika'],['quality_control','Quality Control'],['ready','Siap Diambil']] as const

export function useProductionOrders(){
  const {organization,activeOutletId}=useOrganization();const [tasks,setTasks]=useState<LiveProductionTask[]>([]);const [loading,setLoading]=useState(true);const [error,setError]=useState('')
  const load=useCallback(async()=>{if(!organization)return;setLoading(true);let query=supabase.from('orders').select('id, customer_id, outlet_id, order_number, grand_total, production_status, estimated_completion_at, created_at').eq('organization_id',organization.id).not('production_status','in','("completed","cancelled")').order('created_at');if(activeOutletId)query=query.eq('outlet_id',activeOutletId);const [orderResult,customerResult,outletResult]=await Promise.all([query,supabase.from('customers').select('id,name').eq('organization_id',organization.id),supabase.from('outlets').select('id,name').eq('organization_id',organization.id)]);const customers=Object.fromEntries((customerResult.data??[]).map(item=>[item.id,item.name]));const outlets=Object.fromEntries((outletResult.data??[]).map(item=>[item.id,item.name]));setTasks((orderResult.data??[]).map(order=>({id:order.id,number:order.order_number,customer:order.customer_id?customers[order.customer_id]??'Pelanggan':'Pelanggan umum',outlet:outlets[order.outlet_id]??'—',status:order.production_status,due:order.estimated_completion_at,total:Number(order.grand_total),createdAt:order.created_at})));setError(orderResult.error?.message??'');setLoading(false)},[organization?.id,activeOutletId])
  useEffect(()=>{load()},[load])
  async function setStatus(id:string,status:string){const {error:updateError}=await supabase.rpc('update_order_status',{target_order_id:id,next_status:status});if(updateError)setError(updateError.message);else await load()}
  return{tasks,loading,error,reload:load,setStatus}
}
