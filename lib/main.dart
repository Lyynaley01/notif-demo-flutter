import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel demoChannel = AndroidNotificationChannel(
  'demo_transactions_v2',
  'Notifikasi Transaksi',
  description: 'Notifikasi transaksi masuk.',
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(
    android: androidSettings,
  );

  await notifications.initialize(settings);

  final androidPlugin = notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(demoChannel);

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B55),
        ),
        useMaterial3: true,
      ),
      home: const NotificationFormPage(),
    );
  }
}

class NotificationFormPage extends StatefulWidget {
  const NotificationFormPage({super.key});

  @override
  State<NotificationFormPage> createState() =>
      _NotificationFormPageState();
}

class _NotificationFormPageState
    extends State<NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _amountController =
      TextEditingController(text: '324000');

  final _senderController =
      TextEditingController(text: 'Mishell Agista');

  String _type = 'Terima Saldo';
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
      (match) => '${match[1]}.',
    );
  }

  String _notificationTitle() {
    switch (_type) {
      case 'Top Up Saldo':
        return 'Top Up Saldo';
      case 'Pembayaran Masuk':
        return 'Pembayaran Masuk';
      default:
        return 'Terima Saldo';
    }
  }

  String _notificationBody() {
    final amount = 'Rp${_formatAmount(_amountController.text)}';

    final sender = _senderController.text.trim().isEmpty
        ? 'Pengirim'
        : _senderController.text.trim();

    switch (_type) {
      case 'Top Up Saldo':
        return '$amount ditambahkan dari $sender';
      case 'Pembayaran Masuk':
        return '$amount diterima dari $sender 💰';
      default:
        return '$amount telah diterima dari $sender 💰';
    }
  }

  Future<void> _showNotification() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted =
          await androidPlugin?.requestNotificationsPermission();

      if (granted == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi belum diberikan. '
                'Aktifkan izin di pengaturan Android.',
              ),
            ),
          );
        }
        return;
      }

      final id =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await notifications.show(
        id,
        _notificationTitle(),
        _notificationBody(),
        NotificationDetails(
          android: AndroidNotificationDetails(
            demoChannel.id,
            demoChannel.name,
            channelDescription: demoChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Notifikasi transaksi',
            styleInformation: const DefaultStyleInformation(
              true,
              true,
            ),
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi berhasil ditampilkan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menampilkan notifikasi: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Jenis notifikasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Top Up Saldo',
                      child: Text('Top Up Saldo'),
                    ),
                    DropdownMenuItem(
                      value: 'Terima Saldo',
                      child: Text('Terima Saldo'),
                    ),
                    DropdownMenuItem(
                      value: 'Pembayaran Masuk',
                      child: Text('Pembayaran Masuk'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value ?? 'Terima Saldo';
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nominal (Rupiah)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Contoh: 324000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final digits = (value ?? '')
                        .replaceAll(RegExp(r'[^0-9]'), '');

                    final amount = int.tryParse(digits) ?? 0;

                    if (amount <= 0) {
                      return 'Masukkan nominal lebih dari 0.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nama pengirim',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Nama Pengirim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pengirim wajib diisi.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed:
                        _sending ? null : _showNotification,
                    icon: const Icon(Icons.notifications_active),
                    label: Text(
                      _sending
                          ? 'Memproses...'
                          : 'Tampilkan Notifikasi',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
