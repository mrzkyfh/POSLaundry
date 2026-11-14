import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileAuthGate extends StatefulWidget {
  final Widget child;

  const MobileAuthGate({super.key, required this.child});

  @override
  State<MobileAuthGate> createState() => _MobileAuthGateState();
}

class _MobileAuthGateState extends State<MobileAuthGate> {
  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  _GateState _state = _GateState.loading;

  @override
  void initState() {
    super.initState();
    _resolve(_supabase.auth.currentSession);
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (event) => _resolve(event.session),
    );
  }

  Future<void> _resolve(Session? session) async {
    if (!mounted) return;
    if (session == null) {
      setState(() => _state = _GateState.login);
      return;
    }
    setState(() => _state = _GateState.loading);
    try {
      final memberships = await _supabase
          .from('organization_memberships')
          .select('id')
          .limit(1);
      if (!mounted) return;
      setState(
        () => _state = memberships.isEmpty
            ? _GateState.bootstrap
            : _GateState.ready,
      );
    } catch (_) {
      if (mounted) setState(() => _state = _GateState.bootstrap);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_state) {
    _GateState.loading => const _LoadingPage(),
    _GateState.login => const _LoginPage(),
    _GateState.bootstrap => _BootstrapPage(
      onComplete: () => setState(() => _state = _GateState.ready),
    ),
    _GateState.ready => widget.child,
  };
}

enum _GateState { loading, login, bootstrap, ready }

class _LoginPage extends StatefulWidget {
  const _LoginPage();

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (response.session == null && mounted) {
          setState(
            () => _message =
                'Periksa email untuk mengonfirmasi akun, lalu masuk kembali.',
          );
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Tidak dapat terhubung ke server.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 28),
          Text(
            _register ? 'Buat akun pemilik' : 'Selamat datang kembali',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _register
                ? 'Akun pertama akan menyiapkan organisasi dan outlet utama.'
                : 'Masuk untuk mengelola operasional laundry.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Masukkan email yang valid'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Kata sandi',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.length < 8 ? 'Minimal 8 karakter' : null,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _Notice(_message!),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                _busy
                    ? 'Memproses...'
                    : _register
                    ? 'Buat akun'
                    : 'Masuk',
              ),
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _register = !_register;
                    _message = null;
                  }),
            child: Text(
              _register
                  ? 'Sudah memiliki akun? Masuk'
                  : 'Belum memiliki akun? Daftar sebagai pemilik',
            ),
          ),
        ],
      ),
    ),
  );
}

class _BootstrapPage extends StatefulWidget {
  final VoidCallback onComplete;

  const _BootstrapPage({required this.onComplete});

  @override
  State<_BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<_BootstrapPage> {
  final _formKey = GlobalKey<FormState>();
  final _organization = TextEditingController();
  final _outlet = TextEditingController(text: 'Outlet Utama');
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.rpc(
        'bootstrap_owner',
        params: {
          'organization_name': _organization.text.trim(),
          'outlet_name': _outlet.text.trim(),
        },
      );
      widget.onComplete();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _organization.dispose();
    _outlet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.storefront, size: 44, color: Color(0xFFA6C8E2)),
          const SizedBox(height: 18),
          Text(
            'Siapkan bisnis Anda',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat organisasi dan outlet pertama. Anda otomatis menjadi pemilik.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _organization,
            decoration: const InputDecoration(
              labelText: 'Nama usaha',
              border: OutlineInputBorder(),
            ),
            validator: _requiredName,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _outlet,
            decoration: const InputDecoration(
              labelText: 'Nama outlet utama',
              border: OutlineInputBorder(),
            ),
            validator: _requiredName,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _Notice(_message!),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(_busy ? 'Menyiapkan...' : 'Mulai menggunakan'),
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => Supabase.instance.client.auth.signOut(),
            child: const Text('Keluar dari akun'),
          ),
        ],
      ),
    ),
  );

  static String? _requiredName(String? value) =>
      value == null || value.trim().length < 2 ? 'Minimal 2 karakter' : null;
}

class _AuthScaffold extends StatelessWidget {
  final Widget child;

  const _AuthScaffold({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        backgroundColor: Color(0xFFA6C8E2),
        child: Text(
          'BL',
          style: TextStyle(color: Color(0xFF173247), fontSize: 12),
        ),
      ),
      SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laundry Business OS',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Pusat kendali bisnis',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  final String message;

  const _Notice(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF92400E))),
  );
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Menyiapkan Laundry OS...'),
        ],
      ),
    ),
  );
}

class MissingConfigurationPage extends StatelessWidget {
  const MissingConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Konfigurasi Supabase belum diberikan. Jalankan aplikasi dengan '
          'SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY melalui --dart-define.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
