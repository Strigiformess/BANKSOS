// lib/features/collection/screens/collection_management_screen.dart
// Sprint 4 — Manajemen Koleksi Soal
// Terhubung ke CollectionController untuk load data real dari database.

import 'package:flutter/material.dart';

import '../../../core/guard/rbac_guard.dart';
import '../controllers/collection_controller.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
class CollectionManagementScreen extends StatefulWidget {
  const CollectionManagementScreen({super.key});

  @override
  State<CollectionManagementScreen> createState() =>
      _CollectionManagementScreenState();
}

class _CollectionManagementScreenState
    extends State<CollectionManagementScreen> {
  late final CollectionController _controller;
  String _activeTab = 'Semua';
  final _searchController = TextEditingController();

  static const _tabs = ['Semua', 'Terbit', 'Draft', 'Arsip'];

  @override
  void initState() {
    super.initState();
    _controller = CollectionController();

    // ── Guard RBAC & Load data ────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RbacGuard.redirectIfUnauthorized(context, requiredRole: 'reviewer');
      _controller.loadCollections();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CollectionItem> get _filtered {
    var list = _controller.collections;
    if (_activeTab != 'Semua') {
      final map = {
        'Terbit': 'published',
        'Draft': 'draft',
        'Arsip': 'archived'
      };
      list = list.where((i) => i.status == map[_activeTab]).toList();
    }
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) => i.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ─── Status helpers ──────────────────────────────────────────────────
  String _statusLabel(String s) =>
      {'published': '● Terbit', 'draft': '● Draft', 'archived': '● Arsip'}[s] ??
      s;

  Color _statusColor(String s) => switch (s) {
        'published' => const Color(0xFF16A34A),
        'draft' => const Color(0xFF6B7280),
        _ => const Color(0xFF9CA3AF),
      };

  Color _statusBg(String s) => switch (s) {
        'published' => const Color(0xFFDCFCE7),
        'draft' => const Color(0xFFF3F4F6),
        _ => const Color(0xFFF9FAFB),
      };

  // ─── Difficulty helpers ──────────────────────────────────────────────
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

  // ─── Delete confirm ──────────────────────────────────────────────────────
  void _confirmDelete(CollectionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Koleksi?'),
        content: Text('Semua soal dalam "${item.title}" akan diarsipkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.deleteCollection(categoryName: item.categoryName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.title}" diarsipkan.'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2744) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);
    final textPrimary =
        isDark ? const Color(0xFFE8EDF5) : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF8A9BB0) : const Color(0xFF6B7280);
    final scaffoldBg =
        isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF9FAFB);
    final searchFill =
        isDark ? const Color(0xFF17253A) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            _buildAvatar('R'),
            const SizedBox(width: 10),
            Text(
              'Manajemen Koleksi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: textSecondary),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('3',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: borderColor),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari kategori atau soal...',
                hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                prefixIcon: Icon(Icons.search, size: 20, color: textSecondary),
                filled: true,
                fillColor: searchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Buat Baru button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-question'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Baru',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6FDF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              height: 36,
              child: Row(
                children:
                    _tabs.map((t) => Expanded(child: _buildTab(t))).toList(),
              ),
            ),
          ),

          Container(height: 0.5, color: borderColor),

          // List
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.loadState.toString().contains('error')) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Color(0xFFDC2626)),
                          const SizedBox(height: 12),
                          Text(
                            _controller.errorMessage ?? 'Gagal memuat koleksi',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _controller.loadCollections,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displayItems = _filtered;
                if (displayItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Tidak ada koleksi yang cocok.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  itemCount: displayItems.length,
                  itemBuilder: (_, i) => _CollectionCard(
                    item: displayItems[i],
                    statusLabel: _statusLabel(displayItems[i].status),
                    statusColor: _statusColor(displayItems[i].status),
                    statusBg: _statusBg(displayItems[i].status),
                    diffLabel: _diffLabel(displayItems[i].difficulty),
                    diffColor: _diffColor(displayItems[i].difficulty),
                    diffBg: _diffBg(displayItems[i].difficulty),
                    onEdit: () => Navigator.pushNamed(context, '/add-question'),
                    onDelete: () => _confirmDelete(displayItems[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final active = _activeTab == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveTextColor =
        isDark ? const Color(0xFF8A9BB0) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF1A6FDF) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF1A6FDF) : inactiveTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial) => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF1A6FDF),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

// ─── Collection Card ──────────────────────────────────────────────────────────
class _CollectionCard extends StatelessWidget {
  final CollectionItem item;
  final String statusLabel, diffLabel;
  final Color statusColor, statusBg, diffColor, diffBg;
  final VoidCallback onEdit, onDelete;

  const _CollectionCard({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.diffLabel,
    required this.diffColor,
    required this.diffBg,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2744) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);
    final textPrimary =
        isDark ? const Color(0xFFE8EDF5) : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF8A9BB0) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status + date + actions
          Row(
            children: [
              _Pill(label: statusLabel, fg: statusColor, bg: statusBg),
              const SizedBox(width: 6),
              Text(
                _formatDate(item.createdAt),
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              const Spacer(),
              _IconBtn(
                  icon: Icons.remove_red_eye_outlined,
                  color: textSecondary,
                  onTap: () {}),
              _IconBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF1A6FDF),
                  onTap: onEdit),
              _IconBtn(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFDC2626),
                  onTap: onDelete),
            ],
          ),
          const SizedBox(height: 7),
          Text(item.title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary)),
          const SizedBox(height: 4),
          Text(item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
          const SizedBox(height: 9),
          Row(children: [
            _Pill(
                label: '${item.soalCount} Soal',
                fg: const Color(0xFF1551A8),
                bg: const Color(0xFFE8F0FD)),
            const SizedBox(width: 6),
            _Pill(label: diffLabel, fg: diffColor, bg: diffBg),
          ]),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}h lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays}d lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Pill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: color),
        ),
      );
}
