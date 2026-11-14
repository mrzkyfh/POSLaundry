export type Database = {
  public: {
    Tables: {
      organizations: {
        Row: { id: string; name: string; business_type: string; status: string; created_at: string; updated_at: string }
        Insert: { id?: string; name: string; business_type?: string; status?: string; created_at?: string; updated_at?: string }
        Update: { name?: string; business_type?: string; status?: string; updated_at?: string }
        Relationships: []
      }
      outlets: {
        Row: { id: string; organization_id: string; code: string; name: string; address: string | null; timezone: string; status: string; created_at: string }
        Insert: { id?: string; organization_id: string; code: string; name: string; address?: string | null; timezone?: string; status?: string; created_at?: string }
        Update: { code?: string; name?: string; address?: string | null; timezone?: string; status?: string }
        Relationships: []
      }
      organization_memberships: {
        Row: { id: string; organization_id: string; user_id: string; role: string; status: string; created_at: string }
        Insert: { id?: string; organization_id: string; user_id: string; role: string; status?: string; created_at?: string }
        Update: { role?: string; status?: string }
        Relationships: []
      }
      membership_outlets: {
        Row: { membership_id: string; outlet_id: string }
        Insert: { membership_id: string; outlet_id: string }
        Update: { membership_id?: string; outlet_id?: string }
        Relationships: []
      }
      customers: {
        Row: { id: string; organization_id: string; name: string; phone: string | null; email: string | null; notes: string | null; status: string; created_at: string; updated_at: string }
        Insert: { id?: string; organization_id: string; name: string; phone?: string | null; email?: string | null; notes?: string | null; status?: string; created_at?: string; updated_at?: string }
        Update: { name?: string; phone?: string | null; email?: string | null; notes?: string | null; status?: string; updated_at?: string }
        Relationships: []
      }
      orders: {
        Row: { id: string; organization_id: string; outlet_id: string; customer_id: string | null; order_number: string; subtotal: number; discount_total: number; tax_total: number; grand_total: number; production_status: string; payment_status: string; pickup_status: string; estimated_completion_at: string | null; notes: string | null; created_by: string | null; created_at: string; updated_at: string }
        Insert: { id?: string; organization_id: string; outlet_id: string; customer_id?: string | null; order_number: string; subtotal?: number; discount_total?: number; tax_total?: number; grand_total?: number; production_status?: string; payment_status?: string; pickup_status?: string; estimated_completion_at?: string | null; notes?: string | null; created_by?: string | null; created_at?: string; updated_at?: string }
        Update: { customer_id?: string | null; subtotal?: number; discount_total?: number; tax_total?: number; grand_total?: number; production_status?: string; payment_status?: string; pickup_status?: string; estimated_completion_at?: string | null; notes?: string | null; updated_at?: string }
        Relationships: []
      }
      services: {
        Row: { id: string; organization_id: string; code: string; name: string; unit: string; status: string; created_at: string }
        Insert: { id?: string; organization_id: string; code: string; name: string; unit: string; status?: string; created_at?: string }
        Update: { code?: string; name?: string; unit?: string; status?: string }
        Relationships: []
      }
      service_prices: {
        Row: { id: string; organization_id: string; service_id: string; outlet_id: string | null; speed_type: string; price: number; effective_from: string; effective_until: string | null }
        Insert: { id?: string; organization_id: string; service_id: string; outlet_id?: string | null; speed_type?: string; price: number; effective_from?: string; effective_until?: string | null }
        Update: { outlet_id?: string | null; speed_type?: string; price?: number; effective_from?: string; effective_until?: string | null }
        Relationships: []
      }
      order_items: {
        Row: { id: string; organization_id: string; order_id: string; service_id: string; service_name_snapshot: string; unit: string; quantity: number; unit_price: number; line_total: number }
        Insert: { id?: string; organization_id: string; order_id: string; service_id: string; service_name_snapshot: string; unit: string; quantity: number; unit_price: number }
        Update: { quantity?: number; unit_price?: number }
        Relationships: []
      }
      payments: {
        Row: { id: string; organization_id: string; outlet_id: string; amount: number; method: string; status: string; paid_at: string | null; idempotency_key: string; created_by: string | null; created_at: string }
        Insert: { id?: string; organization_id: string; outlet_id: string; amount: number; method: string; status?: string; paid_at?: string | null; idempotency_key: string; created_by?: string | null; created_at?: string }
        Update: { status?: string; paid_at?: string | null }
        Relationships: []
      }
      payment_allocations: {
        Row: { id: string; organization_id: string; payment_id: string; order_id: string; amount: number; created_at: string }
        Insert: { id?: string; organization_id: string; payment_id: string; order_id: string; amount: number; created_at?: string }
        Update: { amount?: number }
        Relationships: []
      }
      order_status_history: {
        Row: { id: string; organization_id: string; order_id: string; status: string; changed_by: string | null; created_at: string }
        Insert: { id?: string; organization_id: string; order_id: string; status: string; changed_by?: string | null; created_at?: string }
        Update: { status?: string }
        Relationships: []
      }
      inventory_items: {
        Row: { id:string; organization_id:string; outlet_id:string|null; sku:string; name:string; category:string|null; unit:string; current_stock:number; minimum_stock:number; unit_cost:number; status:string; created_at:string; updated_at:string }
        Insert: { id?:string; organization_id:string; outlet_id?:string|null; sku:string; name:string; category?:string|null; unit:string; current_stock?:number; minimum_stock?:number; unit_cost?:number; status?:string; created_at?:string; updated_at?:string }
        Update: { outlet_id?:string|null; sku?:string; name?:string; category?:string|null; unit?:string; current_stock?:number; minimum_stock?:number; unit_cost?:number; status?:string; updated_at?:string }
        Relationships: []
      }
      stock_movements: {
        Row: { id:string; organization_id:string; inventory_item_id:string; movement_type:string; quantity:number; balance_after:number; reference:string|null; notes:string|null; created_by:string|null; created_at:string }
        Insert: { id?:string; organization_id:string; inventory_item_id:string; movement_type:string; quantity:number; balance_after:number; reference?:string|null; notes?:string|null; created_by?:string|null; created_at?:string }
        Update: { notes?:string|null }
        Relationships: []
      }
      employees: {
        Row:{id:string;organization_id:string;outlet_id:string|null;employee_code:string;full_name:string;email:string|null;phone:string|null;job_title:string;employment_type:string;joined_on:string;status:string;created_at:string;updated_at:string}
        Insert:{id?:string;organization_id:string;outlet_id?:string|null;employee_code:string;full_name:string;email?:string|null;phone?:string|null;job_title:string;employment_type?:string;joined_on?:string;status?:string;created_at?:string;updated_at?:string}
        Update:{outlet_id?:string|null;full_name?:string;email?:string|null;phone?:string|null;job_title?:string;employment_type?:string;joined_on?:string;status?:string;updated_at?:string}
        Relationships:[]
      }
      attendance_records: {
        Row:{id:string;organization_id:string;employee_id:string;outlet_id:string|null;attendance_date:string;scheduled_start:string|null;scheduled_end:string|null;clock_in:string|null;clock_out:string|null;status:string;notes:string|null;created_by:string|null;created_at:string;updated_at:string}
        Insert:{id?:string;organization_id:string;employee_id:string;outlet_id?:string|null;attendance_date?:string;scheduled_start?:string|null;scheduled_end?:string|null;clock_in?:string|null;clock_out?:string|null;status?:string;notes?:string|null;created_by?:string|null;created_at?:string;updated_at?:string}
        Update:{clock_in?:string|null;clock_out?:string|null;status?:string;notes?:string|null;updated_at?:string}
        Relationships:[]
      }
    }
    Views: Record<string, never>
    Functions: {
      bootstrap_owner: {
        Args: { organization_name: string; outlet_name: string }
        Returns: { organization_id: string; outlet_id: string }[]
      }
      create_order: {
        Args: { target_outlet_id: string; target_customer_id: string | null; order_items: { service_id: string; quantity: number; speed_type: string }[]; completion_at?: string | null; order_notes?: string | null }
        Returns: { id: string; order_number: string; grand_total: number }
      }
      create_service_with_price: {
        Args: { service_code: string; service_name: string; service_unit: string; service_price: number; target_outlet_id?: string | null; service_speed?: string }
        Returns: { id: string }
      }
      record_order_payment: {
        Args: { target_order_id: string; payment_amount: number; payment_method: string; payment_key: string }
        Returns: { payment_id: string; paid_total: number; payment_status: string }
      }
      update_order_status: {
        Args: { target_order_id: string; next_status: string }
        Returns: { status: string }
      }
      create_inventory_item: {
        Args: { item_sku:string; item_name:string; item_unit:string; opening_stock:number; minimum_level:number; item_unit_cost:number; target_outlet_id?:string|null; item_category?:string|null }
        Returns: { id:string }
      }
      record_stock_movement: {
        Args: { target_item_id:string; movement_kind:string; movement_quantity:number; movement_reference?:string|null; movement_notes?:string|null }
        Returns: { balance:number }
      }
      create_employee:{Args:{employee_code:string;employee_name:string;employee_job_title:string;employee_email?:string|null;employee_phone?:string|null;target_outlet_id?:string|null;employee_type?:string;employee_joined_on?:string};Returns:{id:string}}
      record_attendance:{Args:{target_employee_id:string;event_type:string;event_time?:string};Returns:{id:string}}
      has_organization_role: {
        Args: { target_organization_id: string; allowed_roles: string[] }
        Returns: boolean
      }
      is_organization_member: { Args: { target_organization_id: string }; Returns: boolean }
    }
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
