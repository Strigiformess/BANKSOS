// lib/features/review/screens/review_queue_screen.dart
//
// Sprint 4 — UI Antrian Review
// Terhubung ke ReviewController untuk approve / reject.
// Guard RBAC dijalankan di initState via RbacGuard.

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ganti ke Riverpod

import 'package:banksos/core/guard/rbac_guard.dart';
import 'package:banksos/data/models/question_model.dart';
import '../controllers/review_controller.dart'; // Mengambil reviewControllerProvider

// ─── Screen ───────────────────────────────────────────────────────────────────
class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  String _activeFilter = 'Menunggu';
  static const _filters = ['Menunggu', 'Disetujui', 'Ditandai'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RbacGuard.redirectIfUnauthorized(context, requiredRole: 'reviewer');
      
      // Menggunakan ref.read untuk memanggil fungsi di Riverpod
      ref.read(reviewControllerProvider).loadSoalPending();
    });
  }

  // ─── Approve ──────────────────────────────────────────────────────────────
  Future<void> _onApprove(QuestionModel item) async {
    final tingkat = await _showTingkatKesulitanDialog();
    if (tingkat == null || !mounted) return;

    // Menggunakan ref.read untuk mengambil instance controller
    final controller = ref.read(reviewControllerProvider);
    final result = await controller.approve(
      questionId: item.id,
      tingkatKesulitan: tingkat,
    );

    if (!mounted) return;
    
    if (result.success) {
      _showSnackBar('Soal berhasil disetujui dan dipublikasikan.', isSuccess: true);
    } else {
      _showSnackBar(result.errorMessage ?? 'Gagal menyetujui soal.', isSuccess: false);
    }
  }

  // ─── Reject ──────────────────────────────────────────────────────────────
  Future<void> _onReject(QuestionModel item) async {
    final alasan = await _showAlasanDialog();
    if (alasan == null || !mounted) return;

    // Menggunakan ref.read untuk mengambil instance controller
    final controller = ref.read(reviewControllerProvider);
    final result = await controller.reject(
      questionId: item.id,
      alasan: alasan,
    );

    if (!mounted) return;
    
    if (result.success) {
      _showSnackBar('Soal ditolak. Mahasiswa akan mendapat notifikasi.', isSuccess: false);
    } else {
      _showSnackBar(result.errorMessage ?? 'Gagal menolak soal.', isSuccess: false);
    }
  }

  // ─── Dialog: Tingkat Kesulitan ────────────────────────────────────────────
  Future<String?> _showTingkatKesulitanDialog() {
    String selected = 'easy';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Pilih Tingkat Kesulitan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reviewer wajib menentukan tingkat kesulitan soal:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 12),
              ...[
                ('easy', 'Mudah', const Color(0xFF16A34A)),
                ('medium', 'Sedang', const Color(0xFFD97706)),
                ('hard', 'Sulit', const Color(0xFFDC2626)),
              ].map((entry) {
                final (val, lbl, col) = entry;
                return RadioListTile<String>(
                  title: Text(lbl,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: col)),
                  value: val,
                  groupValue: selected,
                  activeColor: col,
                  dense: true,
                  onChanged: (v) => setSt(() => selected = v!),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Setujui & Publikasikan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialog: Alasan Penolakan ─────────────────────────────────────────────
  Future<String?> _showAlasanDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Alasan Penolakan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alasan akan ditampilkan kepada pengaju:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Tulis alasan penolakan (minimal 10 karakter)...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: Color(0xFF1A6FDF)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length < 10) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Alasan minimal 10 karakter.'),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Tolak Soal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ─── Difficulty helpers ──────────────────────────────────────────────────
  String _diffLabel(String d) =>
      {'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit'}[d] ?? d;

  Color _diffColor(String d) => switch (d) {
        'easy' => const Color(0xFF16A34A),
        'medium' => const Color(0xFFD97706),
        _ => const Color(0xFFDC2626),
      };

  Color _diffBg(String d) => switch (d) {
        'easy' => const Color(0xFFDCFCE7),
        'medium' => const Color(0xFFFEF3C7),
        _ => const Color(0xFFFEE2E2),
      };

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Mengamati perubahan state lewat Riverpod ref.watch
    final controller = ref.watch(reviewControllerProvider);
    final soalList = controller.soalPending;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Antrian Review',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF374151)),
            onPressed: () {},
          ),
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(6)),
            child: const Center(
              child: Icon(Icons.stop_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Antrean Review',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 3),
                Text(
                  'Moderasi kontribusi soal terbaru dari komunitas pendidik.',
                  style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.4),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: _filters.map((f) {
                final active = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1A6FDF)
                            : Colors.white,
                        border: Border.all(
                          color: active
                              ? const Color(0xFF1A6FDF)
                              : const Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : soalList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fact_check_outlined,
                                size: 48, color: Color(0xFFD1D5DB)),
                            SizedBox(height: 12),
                            Text('Antrian Kosong',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            SizedBox(height: 4),
                            Text('Semua soal sudah direview!',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        itemCount: soalList.length,
                        itemBuilder: (_, i) => _ReviewCard(
                          item: soalList[i],
                          diffLabel: _diffLabel(soalList[i].tingkatKesulitan.name),
                          diffColor: _diffColor(soalList[i].tingkatKesulitan.name),
                          diffBg: _diffBg(soalList[i].tingkatKesulitan.name),
                          onApprove: () => _onApprove(soalList[i]),
                          onReject: () => _onReject(soalList[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final QuestionModel item;
  final String diffLabel;
  final Color diffColor, diffBg;
  final VoidCallback onApprove, onReject;

  const _ReviewCard({
    required this.item,
    required this.diffLabel,
    required this.diffColor,
    required this.diffBg,
    required this.onApprove,
    required this.onReject,
  });

  String _getInitials(String userId) {
    if (userId.length >= 2) {
      return userId.substring(0, 2).toUpperCase();
    }
    return userId.toUpperCase();
  }

  Color _getAvatarBg(String userId) {
    final colors = [
      const Color(0xFFDBEAFE),
      const Color(0xFFFCE7F3),
      const Color(0xFFEDE9FE),
      const Color(0xFFECF0FF),
      const Color(0xFFF0FDF4),
    ];
    final hashCode = userId.hashCode;
    return colors[hashCode.abs() % colors.length];
  }

  Color _getAvatarFg(String userId) {
    final colors = [
      const Color(0xFF1D4ED8),
      const Color(0xFFBE185D),
      const Color(0xFF6D28D9),
      const Color(0xFF1E40AF),
      const Color(0xFF15803D),
    ];
    final hashCode = userId.hashCode;
    return colors[hashCode.abs() % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBg = _getAvatarBg(item.submittedBy);
    final avatarFg = _getAvatarFg(item.submittedBy);
    final initials = _getInitials(item.submittedBy);
    final timeStr = _formatTime(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: diffBg,
                    borderRadius: BorderRadius.circular(100)),
                child: Text(diffLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: diffColor)),
              ),
              const Spacer(),
              Text(timeStr,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 7),
          Text(item.pertanyaan,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(item.kategoriNama,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: avatarFg)),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengguna #${item.submittedBy.substring(0, 8)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  const Text('Kontributor',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 15),
                  label: const Text('Tolak',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side:
                        const BorderSide(color: Color(0xFFFCA5A5)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Setujui',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}