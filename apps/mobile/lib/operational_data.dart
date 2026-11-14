import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_flow.dart';

class OperationalOrder {
  final String id;
  final String number;
  final String customer;
  final String status;
  final String paymentStatus;
  final num total;
  final DateTime? dueAt;

  const OperationalOrder({
    required this.id,
    required this.number,
    required this.customer,
    required this.status,
    required this.paymentStatus,
    required this.total,
    required this.dueAt,
  });
}

class OperationalSnapshot {
  final List<OperationalOrder> orders;
  const OperationalSnapshot(this.orders);
  int get today => orders.where((order) {
    final now = DateTime.now();
    final date = order.dueAt?.toLocal();
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }).length;
  int get active => orders
      .where((order) => !['completed', 'cancelled'].contains(order.status))
      .length;
  int get ready => orders.where((order) => order.status == 'ready').length;
  int get overdue => orders
      .where(
        (order) =>
            order.dueAt != null &&
            order.dueAt!.isBefore(DateTime.now()) &&
            !['ready', 'completed', 'cancelled'].contains(order.status),
      )
      .length;
}

Future<OperationalSnapshot> loadOperationalSnapshot() async {
  final client = Supabase.instance.client;
  final membership = await client
      .from('organization_memberships')
      .select('organization_id')
      .eq('status', 'active')
      .limit(1)
      .maybeSingle();
  if (membership == null) return const OperationalSnapshot([]);
  final organizationId = membership['organization_id'] as String;
  final results = await Future.wait([
    client
        .from('orders')
        .select(
          'id, customer_id, order_number, grand_total, production_status, payment_status, estimated_completion_at, created_at',
        )
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false)
        .limit(100),
    client
        .from('customers')
        .select('id, name')
        .eq('organization_id', organizationId),
  ]);
  final customers = <String, String>{
    for (final row in results[1] as List)
      row['id'] as String: row['name'] as String,
  };
  final orders = (results[0] as List)
      .map(
        (row) => OperationalOrder(
          id: row['id'] as String,
          number: row['order_number'] as String,
          customer: row['customer_id'] == null
              ? 'Pelanggan umum'
              : customers[row['customer_id']] ?? 'Pelanggan',
          status: row['production_status'] as String,
          paymentStatus: row['payment_status'] as String,
          total: row['grand_total'] as num,
          dueAt: row['estimated_completion_at'] == null
              ? null
              : DateTime.tryParse(row['estimated_completion_at'] as String),
        ),
      )
      .toList();
  return OperationalSnapshot(orders);
}

const _statusLabels = <String, String>{
  'received': 'Baru',
  'sorting': 'Penyortiran',
  'washing': 'Dicuci',
  'drying': 'Dikeringkan',
  'ironing': 'Disetrika',
  'quality_control': 'Quality control',
  'ready': 'Siap diambil',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
};
String _money(num value) =>
    'Rp${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
String _time(DateTime? value) => value == null
    ? 'Belum diatur'
    : '${value.toLocal().hour.toString().padLeft(2, '0')}.${value.toLocal().minute.toString().padLeft(2, '0')} WIB';

class LiveMetrics extends StatelessWidget {
  const LiveMetrics({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<OperationalSnapshot>(
    future: loadOperationalSnapshot(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 63,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final data = snapshot.data ?? const OperationalSnapshot([]);
      return Row(
        children: [
          Expanded(child: _Metric('${data.today}', 'Hari ini')),
          Expanded(child: _Metric('${data.active}', 'Dalam proses')),
          Expanded(child: _Metric('${data.ready}', 'Siap diambil')),
          Expanded(
            child: _Metric('${data.overdue}', 'Terlambat', danger: true),
          ),
        ],
      );
    },
  );
}

class _Metric extends StatelessWidget {
  final String value, label;
  final bool danger;
  const _Metric(this.value, this.label, {this.danger = false});
  @override
  Widget build(BuildContext context) => Container(
    height: 63,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: danger ? const Color(0xFFB91C1C) : null,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 7, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class LiveOrderList extends StatefulWidget {
  final int? limit;
  final bool production;
  const LiveOrderList({super.key, this.limit, this.production = false});
  @override
  State<LiveOrderList> createState() => _LiveOrderListState();
}

class _LiveOrderListState extends State<LiveOrderList> {
  late Future<OperationalSnapshot> future;
  @override
  void initState() {
    super.initState();
    future = loadOperationalSnapshot();
  }

  Future<void> refresh() async {
    setState(() => future = loadOperationalSnapshot());
    await future;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<OperationalSnapshot>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Gagal memuat pesanan: ${snapshot.error}',
            style: const TextStyle(fontSize: 9, color: Color(0xFFB91C1C)),
          ),
        );
      }
      var values = snapshot.data?.orders ?? [];
      if (widget.production) {
        values = values
            .where(
              (order) => !['completed', 'cancelled'].contains(order.status),
            )
            .toList();
      }
      if (widget.limit != null) values = values.take(widget.limit!).toList();
      if (values.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(26),
          child: Center(
            child: Text(
              'Belum ada pesanan.',
              style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: refresh,
        child: Column(
          children: values
              .map((order) => _OrderCard(order, production: widget.production))
              .toList(),
        ),
      );
    },
  );
}

class _OrderCard extends StatelessWidget {
  final OperationalOrder order;
  final bool production;
  const _OrderCard(this.order, {required this.production});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MobileOrderDetailPage(order.id)),
      ),
      dense: true,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFF2F7FB),
        child: Icon(Icons.receipt_long, color: Color(0xFF3F647E), size: 18),
      ),
      title: Text(
        order.number,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF3F647E),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.customer,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(_money(order.total), style: const TextStyle(fontSize: 8)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _statusLabels[order.status] ?? order.status,
            style: const TextStyle(fontSize: 8, color: Color(0xFFB45309)),
          ),
          Text(_time(order.dueAt), style: const TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );
}
