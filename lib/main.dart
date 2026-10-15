import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel demoChannel = AndroidNotificationChannel(
  'demo_transactions',
  'Notifikasi Demo',
  description: 'Notifikasi simulasi transaksi, bukan transaksi sungguhan.',
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await notifications.initialize(settings);

  final androidPlugin = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(demoChannel);

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notif Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B55)),
        useMaterial3: true,
      ),
      home: const NotificationFormPage(),
    );
  }
}

class NotificationFormPage extends StatefulWidget {
  const NotificationFormPage({super.key});

  @override
  State<NotificationFormPage> createState() => _NotificationFormPageState();
}

class _NotificationFormPageState extends State<NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '50000');
  final _senderController = TextEditingController(text: 'BERRY STORE');

  String _type = 'Terima Saldo';
  String _source = 'Bank Mandiri';
  bool _sending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  String _formatAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '0';
    final number = int.tryParse(digits) ?? 0;
    final s = number.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _notificationBody() {
    final amount = 'Rp${_formatAmount(_amountController.text)}';
    final sender = _senderController.text.trim().isEmpty
        ? 'Pengirim Demo'
        : _senderController.text.trim();

    switch (_type) {
      case 'Top Up Saldo':
        return '$amount dari $sender. Ini notifikasi DEMO, bukan transaksi asli.';
      case 'Pembayaran Masuk':
        return '$amount dari $sender diterima (SIMULASI DEMO). Bukan bukti pembayaran.';
      default:
        return '$amount diterima dari $sender 💰 (SIMULASI DEMO). Bukan transaksi asli.';
    }
  }

  Future<void> _showNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final androidPlugin = notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();

      if (granted == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi belum diberikan. Aktifkan di pengaturan Android.'),
          ),
        );
        return;
      }

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await notifications.show(
        id,
        'DEMO • $_type',
        _notificationBody(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'demo_transactions',
            'Notifikasi Demo',
            channelDescription: 'Notifikasi simulasi transaksi, bukan transaksi sungguhan.',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Notifikasi simulasi DEMO',
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi DEMO dikirim ke perangkat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menampilkan notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notif Transaksi Demo'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade800),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SIMULATOR DEMO — notifikasi ini dibuat secara manual untuk pengujian. '
                    'Bukan berasal dari bank/dompet digital dan bukan bukti transaksi.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Jenis notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Top Up Saldo', child: Text('Top Up Saldo')),
                    DropdownMenuItem(value: 'Terima Saldo', child: Text('Terima Saldo')),
                    DropdownMenuItem(value: 'Pembayaran Masuk', child: Text('Pembayaran Masuk')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'Terima Saldo'),
                ),
                const SizedBox(height: 16),
                Text('Nominal (Rupiah)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Contoh: 50000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty || (int.tryParse(digits) ?? 0) <= 0) {
                      return 'Masukkan nominal lebih dari 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Nama pengirim / sumber', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: BERRY STORE',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama pengirim wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 16),
                if (_type == 'Top Up Saldo' || _type == 'Pembayaran Masuk') ...[
                  const Text('Contoh sumber (opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _source,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Bank Mandiri', child: Text('Bank Mandiri')),
                      DropdownMenuItem(value: 'OVO', child: Text('OVO')),
                      DropdownMenuItem(value: 'Bank lain', child: Text('Bank lain')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _source = v ?? 'Bank Mandiri';
                        _senderController.text = _source;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  },
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Perbarui input'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _sending ? null : _showNotification,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(_sending ? 'Memproses...' : 'Tampilkan Notifikasi DEMO'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Catatan: nama dan nominal hanya teks simulasi. Aplikasi tidak terhubung ke akun, saldo, atau sistem pembayaran mana pun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
