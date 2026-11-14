import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String money(num value) =>
    'Rp${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

class MobileNewOrderPage extends StatefulWidget {
  const MobileNewOrderPage({super.key});
  @override
  State<MobileNewOrderPage> createState() => _MobileNewOrderPageState();
}

class _MobileNewOrderPageState extends State<MobileNewOrderPage> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> outlets = [], customers = [], services = [];
  String? outletId, customerId, serviceId;
  final quantity = TextEditingController(text: '1');
  final notes = TextEditingController();
  DateTime? completion;
  bool loading = true, busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final membership = await client
          .from('organization_memberships')
          .select('organization_id')
          .eq('status', 'active')
          .limit(1)
          .single();
      final orgId = membership['organization_id'] as String;
      final results = await Future.wait([
        client
            .from('outlets')
            .select('id, name')
            .eq('organization_id', orgId)
            .eq('status', 'active')
            .order('name'),
        client
            .from('customers')
            .select('id, name')
            .eq('organization_id', orgId)
            .eq('status', 'active')
            .order('name'),
        client
            .from('services')
            .select('id, name, unit')
            .eq('organization_id', orgId)
            .eq('status', 'active')
            .order('name'),
        client
            .from('service_prices')
            .select('service_id, outlet_id, speed_type, price')
            .eq('organization_id', orgId)
            .isFilter('effective_until', null),
      ]);
      outlets = List<Map<String, dynamic>>.from(results[0]);
      customers = List<Map<String, dynamic>>.from(results[1]);
      final priceRows = List<Map<String, dynamic>>.from(results[3]);
      services = List<Map<String, dynamic>>.from(results[2])
          .map((service) {
            final prices = priceRows
                .where((price) => price['service_id'] == service['id'])
                .toList();
            final price = prices.isEmpty ? null : prices.first;
            return {
              ...service,
              'price': price?['price'],
              'speed_type': price?['speed_type'] ?? 'regular',
            };
          })
          .where((service) => service['price'] != null)
          .toList();
      outletId = outlets.firstOrNull?['id'] as String?;
    } catch (exception) {
      error = exception.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  num get total {
    final service = services
        .where((item) => item['id'] == serviceId)
        .firstOrNull;
    return service == null
        ? 0
        : (service['price'] as num) * (num.tryParse(quantity.text) ?? 0);
  }

  Future<void> _submit() async {
    if (outletId == null ||
        serviceId == null ||
        (num.tryParse(quantity.text) ?? 0) <= 0) {
      setState(() => error = 'Pilih outlet, layanan, dan jumlah yang valid.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final service = services.firstWhere((item) => item['id'] == serviceId);
      await client.rpc(
        'create_order',
        params: {
          'target_outlet_id': outletId,
          'target_customer_id': customerId,
          'order_items': [
            {
              'service_id': serviceId,
              'quantity': num.parse(quantity.text),
              'speed_type': service['speed_type'],
            },
          ],
          'completion_at': completion?.toUtc().toIso8601String(),
          'order_notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat.')),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    quantity.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Pesanan baru',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaksi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: outletId,
                        decoration: const InputDecoration(
                          labelText: 'Outlet',
                          border: OutlineInputBorder(),
                        ),
                        items: outlets
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'] as String,
                                child: Text(item['name'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => outletId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: customerId,
                        decoration: const InputDecoration(
                          labelText: 'Pelanggan',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Pelanggan umum'),
                          ),
                          ...customers.map(
                            (item) => DropdownMenuItem(
                              value: item['id'] as String,
                              child: Text(item['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => customerId = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layanan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: serviceId,
                        decoration: const InputDecoration(
                          labelText: 'Jenis layanan',
                          border: OutlineInputBorder(),
                        ),
                        items: services
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'] as String,
                                child: Text(
                                  '${item['name']} · ${money(item['price'] as num)}/${item['unit']}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => serviceId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Berat / jumlah',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Estimasi selesai',
                          style: TextStyle(fontSize: 10),
                        ),
                        subtitle: Text(
                          completion == null
                              ? 'Belum diatur'
                              : completion.toString(),
                          style: const TextStyle(fontSize: 9),
                        ),
                        trailing: const Icon(Icons.event),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(
                                () => completion = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan pesanan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (services.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Belum ada layanan dengan harga. Tambahkan melalui dashboard web.',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
            ],
          ),
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total sementara', style: TextStyle(fontSize: 8)),
                  Text(
                    money(total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: busy || services.isEmpty ? null : _submit,
              child: Text(busy ? 'Menyimpan...' : 'Buat pesanan'),
            ),
          ],
        ),
      ),
    ),
  );
}

class MobileOrderDetailPage extends StatefulWidget {
  final String orderId;
  const MobileOrderDetailPage(this.orderId, {super.key});
  @override
  State<MobileOrderDetailPage> createState() => _MobileOrderDetailPageState();
}

class _MobileOrderDetailPageState extends State<MobileOrderDetailPage> {
  final client = Supabase.instance.client;
  Map<String, dynamic>? order;
  List<Map<String, dynamic>> items = [];
  num paid = 0;
  bool loading = true;
  String? error;
  static const labels = {
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
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      order = await client
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();
      items = List<Map<String, dynamic>>.from(
        await client
            .from('order_items')
            .select()
            .eq('order_id', widget.orderId),
      );
      final allocations = List<Map<String, dynamic>>.from(
        await client
            .from('payment_allocations')
            .select('amount')
            .eq('order_id', widget.orderId),
      );
      paid = allocations.fold<num>(
        0,
        (sum, item) => sum + (item['amount'] as num),
      );
    } catch (exception) {
      error = exception.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _status(String value) async {
    try {
      await client.rpc(
        'update_order_status',
        params: {'target_order_id': widget.orderId, 'next_status': value},
      );
      await _load();
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    }
  }

  Future<void> _pay() async {
    final remaining = (order!['grand_total'] as num) - paid;
    final controller = TextEditingController(
      text: remaining.toStringAsFixed(0),
    );
    String method = 'cash';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima pembayaran'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'card', child: Text('Kartu')),
                ],
                onChanged: (value) => setDialogState(() => method = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (submitted == true) {
      try {
        await client.rpc(
          'record_order_payment',
          params: {
            'target_order_id': widget.orderId,
            'payment_amount': num.parse(controller.text),
            'payment_method': method,
            'payment_key': 'mobile-${DateTime.now().microsecondsSinceEpoch}',
          },
        );
        await _load();
      } catch (exception) {
        if (mounted) setState(() => error = exception.toString());
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(error ?? 'Pesanan tidak ditemukan')),
      );
    }
    final remaining = (order!['grand_total'] as num) - paid;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          order!['order_number'] as String,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          DropdownButtonFormField<String>(
            initialValue: order!['production_status'] as String,
            decoration: const InputDecoration(
              labelText: 'Tahap produksi',
              border: OutlineInputBorder(),
            ),
            items: labels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _status(value);
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: items
                  .map(
                    (item) => ListTile(
                      title: Text(item['service_name_snapshot'] as String),
                      subtitle: Text(
                        '${item['quantity']} ${item['unit']} × ${money(item['unit_price'] as num)}',
                      ),
                      trailing: Text(money(item['line_total'] as num)),
                    ),
                  )
                  .toList(),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _Summary('Total', money(order!['grand_total'] as num)),
                  _Summary('Dibayar', money(paid)),
                  _Summary(
                    'Sisa tagihan',
                    money(remaining),
                    danger: remaining > 0,
                  ),
                  if (remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: _pay,
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Terima pembayaran'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Color(0xFFB91C1C))),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label, value;
  final bool danger;
  const _Summary(this.label, this.value, {this.danger = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: danger ? const Color(0xFFB91C1C) : null,
          ),
        ),
      ],
    ),
  );
}
