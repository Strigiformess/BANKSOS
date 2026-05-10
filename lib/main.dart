// lib/main.dart
// Updated Sprint 1 — ganti placeholder dengan screen asli

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive/hive_service.dart';
import 'data/remote/mongodb/mongodb_service.dart';
import 'routes/app_routes.dart';

// Auth
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';

// Dashboard
import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';

// Bank Soal (Sprint 2 — uncomment setelah Sprint 2 selesai)
// import 'features/questions/screens/bank_soal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env
  await dotenv.load(fileName: '.env');

  // 2. Init Hive
  await HiveService.init();

  // 3. Init MongoDB (non-blocking — app tetap jalan jika offline)
  await MongoDBService.instance.init();

  runApp(
    // Riverpod ProviderScope wajib ada di paling atas
    const ProviderScope(
      child: BanksosApp(),
    ),
  );
}

class BanksosApp extends StatelessWidget {
  const BanksosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BANKSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // ikuti preferensi sistem Android
      home: const SplashRouter(),
      routes: {
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.dashboardMahasiswa: (_) => const DashboardMahasiswaScreen(),
        // Sprint 2 ↓ uncomment saat bank soal selesai
        // AppRoutes.bankSoal:           (_) => const BankSoalScreen(),
        // Placeholder untuk route lain (Sprint 3+)
        AppRoutes.dashboardReviewer:  (_) => const _PlaceholderScreen(title: 'Dashboard Reviewer'),
        AppRoutes.dashboardAdmin:     (_) => const _PlaceholderScreen(title: 'Dashboard Admin'),
        AppRoutes.bookmarks:          (_) => const _PlaceholderScreen(title: 'Bookmark'),
        AppRoutes.riwayat:            (_) => const _PlaceholderScreen(title: 'Riwayat'),
        AppRoutes.kontribusi:         (_) => const _PlaceholderScreen(title: 'Kontribusi'),
        AppRoutes.reviewQueue:        (_) => const _PlaceholderScreen(title: 'Review Queue'),
      },
    );
  }
}

// ─── Splash Router ─────────────────────────────────────────────────────────────
/// Cek sesi Hive → redirect ke halaman yang sesuai tanpa loading screen panjang.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    if (!mounted) return;
    final session = SessionService.instance;

    if (!session.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    switch (session.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardAdmin);
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardReviewer);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardMahasiswa);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen sementara redirect diproses
    return const Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BANKSOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bank Soal Kolaboratif POLBAN',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder untuk route Sprint 3+ ────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
        ),
      ),
    );
  }
}

// // lib/main.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// import 'core/services/session_service.dart';
// import 'data/local/hive/hive_service.dart';

// // TODO: ganti import di bawah ini sesuai nama package kamu di pubspec.yaml
// // login diganti dengan LoginScreen() setelah uni selesai, sama juga dengan dashboard
// //
// // import 'features/auth/screens/login_screen.dart';
// // import 'features/dashboard/screens/dashboard_mahasiswa_screen.dart';
// // import 'features/dashboard/screens/dashboard_reviewer_screen.dart';
// // import 'features/admin/screens/dashboard_admin_screen.dart';

// Future<void> main() async {
//   // Wajib dipanggil sebelum semua inisialisasi async
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Load .env (MONGO_URI, MONGO_DB_NAME, dll)
//   await dotenv.load(fileName: '.env');

//   // 2. Init Hive — buka semua box sekaligus
//   await HiveService.init();

//   runApp(const BanksosApp());
// }

// class BanksosApp extends StatelessWidget {
//   const BanksosApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'BANKSOS',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF1F5C99),
//         ),
//         useMaterial3: true,
//       ),
//       // Cek sesi login untuk menentukan halaman awal
//       home: const SplashRouter(),
//     );
//   }
// }

// /// Widget yang mengecek sesi Hive lalu redirect ke halaman yang tepat.
// /// Tidak ada loading spinner yang terlihat — redirect terjadi di frame pertama.
// class SplashRouter extends StatefulWidget {
//   const SplashRouter({super.key});

//   @override
//   State<SplashRouter> createState() => _SplashRouterState();
// }

// class _SplashRouterState extends State<SplashRouter> {
//   @override
//   void initState() {
//     super.initState();
//     _redirect();
//   }

//   void _redirect() {
//     final session = SessionService.instance;

//     // Tunggu frame pertama selesai render sebelum navigasi
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       if (!session.isLoggedIn) {
//         // Belum login → ke halaman Login
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             // TODO: ganti dengan LoginScreen() setelah Seruni selesai
//             builder: (_) => const _PlaceholderLoginScreen(),
//           ),
//         );
//         return;
//       }

//       // Sudah login → cek role, arahkan ke dashboard yang sesuai
//       if (session.isMahasiswa) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             // TODO: ganti dengan DashboardMahasiswaScreen()
//             builder: (_) => const _PlaceholderDashboard(role: 'Mahasiswa'),
//           ),
//         );
//       } else if (session.isReviewer) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             // TODO: ganti dengan DashboardReviewerScreen()
//             builder: (_) => const _PlaceholderDashboard(role: 'Reviewer'),
//           ),
//         );
//       } else if (session.isAdmin) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             // TODO: ganti dengan DashboardAdminScreen()
//             builder: (_) => const _PlaceholderDashboard(role: 'Admin'),
//           ),
//         );
//       } else {
//         // Role tidak dikenal — paksa logout dan kembali ke Login
//         session.clearSession();
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const _PlaceholderLoginScreen(),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Tampilkan splash sementara redirect diproses
//     return const Scaffold(
//       backgroundColor: Color(0xFF1F5C99),
//       body: Center(
//         child: Text(
//           'BANKSOS',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 4,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Placeholder screens ──────────────────────────────────────────────────────
// // Hapus semua class _Placeholder* pas Seruni & Revaldi selesai membuat
// // screen masing-masing, terus ganti dengan import yang benar di atas.

// class _PlaceholderLoginScreen extends StatelessWidget {
//   const _PlaceholderLoginScreen();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: const Center(
//         child: Text(
//           'Login Screen\n(dikerjakan Seruni)',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 18, color: Colors.grey),
//         ),
//       ),
//     );
//   }
// }

// class _PlaceholderDashboard extends StatelessWidget {
//   const _PlaceholderDashboard({required this.role});
//   final String role;

//   @override
//   Widget build(BuildContext context) {
//     final session = SessionService.instance;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Dashboard $role'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//             onPressed: () async {
//               await session.clearSession();
//               if (context.mounted) {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const _PlaceholderLoginScreen(),
//                   ),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Halo, ${session.nama ?? '-'}!',
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Role: $role  |  Email: ${session.email ?? '-'}',
//               style: const TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }