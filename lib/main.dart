import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'core/services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables dari .env
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Hive dan buka semua box
  await HiveService.init();

  // 3. Koneksi ke MongoDB Atlas
  await MongoDBService.instance.init();

  runApp(
    // ProviderScope dibutuhkan oleh Riverpod
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
}

class BanksosApp extends StatelessWidget {
  const BanksosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SessionService.instance.isLoggedIn;

    return MaterialApp(
      title: 'BANKSOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F5C99),
        ),
        useMaterial3: true,
      ),
      // Jika sudah login → langsung ke home, jika belum → ke login
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const Scaffold(
              body: Center(child: Text('Halaman Login — Sprint 1')),
            ),
        '/home': (context) => const Scaffold(
              body: Center(child: Text('Halaman Home — Sprint 1')),
            ),
      },
    );
  }
}
