// lib/shared/widgets/sync_status_banner.dart
// Sprint 5/6 — Widget untuk menampilkan status antrian sync di UI
//
// Cara pakai di dashboard:
//   const SyncStatusBanner()
//
// Widget ini otomatis tersembunyi jika tidak ada item pending.

import 'package:flutter/material.dart';

import '../../core/services/sync_manager.dart';
import '../../core/theme/app_theme.dart';

/// Banner kuning kecil yang muncul jika ada data offline yang belum tersinkronisasi.
/// Menampilkan jumlah item pending dan tombol "Sync Sekarang".
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  bool _isSyncing = false;

  Future<void> _onSyncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final count = await SyncManager.instance.syncAll();

    if (!mounted) return;
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '$count data berhasil disinkronisasi.'
              : 'Tidak ada koneksi atau data sudah tersinkronisasi.',
        ),
        backgroundColor:
            count > 0 ? AppColors.successGreen : AppColors.textGrey,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = SyncManager.instance.pendingCount;

    // Sembunyikan jika tidak ada yang perlu disync
    if (pending == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacings.lg, vertical: AppSpacings.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningYellow.withOpacity(0.12),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
            color: AppColors.warningYellow.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined,
              size: 16, color: AppColors.warningYellow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pending data belum tersinkronisasi',
              style: AppTextStyles.small.copyWith(
                color: AppColors.warningYellow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warningYellow,
              ),
            )
          else
            GestureDetector(
              onTap: _onSyncNow,
              child: Text(
                'Sync Sekarang',
                style: AppTextStyles.smallSemibold.copyWith(
                  color: AppColors.warningYellow,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}