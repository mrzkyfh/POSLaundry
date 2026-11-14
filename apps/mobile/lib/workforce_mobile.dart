import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveAttendancePage extends StatefulWidget {
  const LiveAttendancePage({super.key});
  @override
  State<LiveAttendancePage> createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> employees = [];
  Map<String, Map<String, dynamic>> records = {};
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final membership = await client
          .from('organization_memberships')
          .select('organization_id')
          .eq('status', 'active')
          .limit(1)
          .single();
      final orgId = membership['organization_id'] as String;
      final result = await Future.wait([
        client
            .from('employees')
            .select('id,full_name,job_title')
            .eq('organization_id', orgId)
            .eq('status', 'active')
            .order('full_name'),
        client
            .from('attendance_records')
            .select('id,employee_id,clock_in,clock_out,status')
            .eq('organization_id', orgId)
            .eq(
              'attendance_date',
              DateTime.now().toIso8601String().substring(0, 10),
            ),
      ]);
      employees = List<Map<String, dynamic>>.from(result[0]);
      records = {
        for (final row in List<Map<String, dynamic>>.from(result[1]))
          row['employee_id'] as String: row,
      };
      error = null;
    } catch (exception) {
      error = exception.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> recordEvent(String id, String event) async {
    try {
      await client.rpc(
        'record_attendance',
        params: {
          'target_employee_id': id,
          'event_type': event,
          'event_time': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await load();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.toString())));
      }
    }
  }

  String clockTime(dynamic value) => value == null
      ? '—'
      : TimeOfDay.fromDateTime(
          DateTime.parse(value as String).toLocal(),
        ).format(context);
  String duration(Map<String, dynamic>? record) {
    if (record?['clock_in'] == null) return '—';
    final start = DateTime.parse(record!['clock_in'] as String);
    final end = record['clock_out'] == null
        ? DateTime.now()
        : DateTime.parse(record['clock_out'] as String);
    final minutes = end.difference(start).inMinutes;
    return '${minutes ~/ 60}j ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: Color(0xFF3F647E)),
            SizedBox(width: 10),
            Text(
              'Absensi Karyawan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      Expanded(child: _body()),
    ],
  );
  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error!, style: const TextStyle(color: Color(0xFFB91C1C))),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Count('${employees.length}', 'Aktif'),
                  _Count('${records.length}', 'Hadir'),
                  _Count('${employees.length - records.length}', 'Belum absen'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...employees.map(_employeeCard),
        ],
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> employee) {
    final attendance = records[employee['id']];
    final initials = (employee['full_name'] as String)
        .split(' ')
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
    Widget action;
    if (attendance?['clock_in'] == null) {
      action = FilledButton(
        onPressed: () => recordEvent(employee['id'] as String, 'clock_in'),
        child: const Text('Masuk'),
      );
    } else if (attendance?['clock_out'] == null) {
      action = OutlinedButton(
        onPressed: () => recordEvent(employee['id'] as String, 'clock_out'),
        child: const Text('Pulang'),
      );
    } else {
      action = const Icon(Icons.check_circle, color: Color(0xFF15803D));
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F0F7),
          child: Text(
            initials,
            style: const TextStyle(fontSize: 10, color: Color(0xFF29485F)),
          ),
        ),
        title: Text(
          employee['full_name'] as String,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${employee['job_title']} · ${clockTime(attendance?['clock_in'])}–${clockTime(attendance?['clock_out'])} · ${duration(attendance)}',
          style: const TextStyle(fontSize: 8),
        ),
        trailing: action,
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String value, label;
  const _Count(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
      ),
    ],
  );
}
