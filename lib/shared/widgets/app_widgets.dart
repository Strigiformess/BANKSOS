// lib/shared/widgets/app_widgets.dart
//
// BANKSOS — Kumpulan widget reusable siap pakai
// Cara pakai: import file ini, lalu panggil langsung
//
//   AppBadge.difficulty('hard')
//   AppBadge.status('pending')
//   AppDifficultyChips(selected: ..., onChanged: ...)
//   SyncStatusIcon(isSynced: true)
//   OfflineBanner()
//   AppErrorBanner(message: '...')

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BADGE KESULITAN & STATUS
// ══════════════════════════════════════════════════════════════════════════════

/// Badge warna untuk tingkat kesulitan soal (Easy / Medium / Hard)
/// Cara pakai: AppBadge.difficulty('hard')
class AppBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const AppBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  factory AppBadge.difficulty(String level) {
    final s = AppBadgeStyle.difficulty(level);
    final labels = {'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit'};
    return AppBadge(
      label: labels[level.toLowerCase()] ?? level,
      bg: s.bg,
      textColor: s.text,
    );
  }

  factory AppBadge.status(String status) {
    final s = AppBadgeStyle.questionStatus(status);
    final labels = {
      'pending': 'Pending',
      'published': 'Diterima',
      'rejected': 'Ditolak',
      'archived': 'Diarsip',
      'inactive': 'Nonaktif',
    };
    return AppBadge(
      label: labels[status.toLowerCase()] ?? status,
      bg: s.bg,
      textColor: s.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(color: textColor),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FILTER CHIP KESULITAN
// ══════════════════════════════════════════════════════════════════════════════

enum DifficultyFilter { all, easy, medium, hard }

/// Baris chip filter kesulitan soal
/// Cara pakai:
///   AppDifficultyChips(
///     selected: _filter,
///     onChanged: (val) => setState(() => _filter = val),
///   )
class AppDifficultyChips extends StatelessWidget {
  final DifficultyFilter selected;
  final ValueChanged<DifficultyFilter> onChanged;

  const AppDifficultyChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(
            label: 'Semua',
            isSelected: selected == DifficultyFilter.all,
            activeColor: AppColors.primaryBlue,
            onTap: () => onChanged(DifficultyFilter.all),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'Mudah',
            isSelected: selected == DifficultyFilter.easy,
            activeColor: AppColors.easyGreen,
            onTap: () => onChanged(DifficultyFilter.easy),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'Sedang',
            isSelected: selected == DifficultyFilter.medium,
            activeColor: AppColors.mediumAmber,
            onTap: () => onChanged(DifficultyFilter.medium),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'Sulit',
            isSelected: selected == DifficultyFilter.hard,
            activeColor: AppColors.hardRed,
            onTap: () => onChanged(DifficultyFilter.hard),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : AppColors.bgWhite,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallSemibold.copyWith(
            color: isSelected ? activeColor : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BANNER OFFLINE
// ══════════════════════════════════════════════════════════════════════════════

/// Banner kuning di atas halaman saat mode offline
/// Cara pakai: if (isOffline) const OfflineBanner()
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warningYellow.withOpacity(0.12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 16, color: AppColors.warningYellow),
          const SizedBox(width: 8),
          Text(
            'Mode Offline — Menampilkan soal tersimpan',
            style: AppTextStyles.small.copyWith(
              color: AppColors.warningYellow,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ERROR & INFO BANNER
// ══════════════════════════════════════════════════════════════════════════════

enum BannerType { info, success, warning, error }

/// Banner pesan inline (bukan dialog)
/// Cara pakai:
///   AppMessageBanner(type: BannerType.error, message: 'Email salah')
class AppMessageBanner extends StatelessWidget {
  final BannerType type;
  final String message;

  const AppMessageBanner({
    super.key,
    required this.type,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final BoxDecoration deco;
    final Color iconColor;
    final IconData icon;

    switch (type) {
      case BannerType.info:
        deco = AppDecorations.bannerInfo;
        iconColor = AppColors.primaryBlue;
        icon = Icons.info_outline;
        break;
      case BannerType.success:
        deco = AppDecorations.bannerSuccess;
        iconColor = AppColors.successGreen;
        icon = Icons.check_circle_outline;
        break;
      case BannerType.warning:
        deco = AppDecorations.bannerWarning;
        iconColor = AppColors.warningYellow;
        icon = Icons.warning_amber_outlined;
        break;
      case BannerType.error:
        deco = AppDecorations.bannerError;
        iconColor = AppColors.errorRed;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      decoration: deco,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.small.copyWith(color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// IKON SINKRONISASI
// ══════════════════════════════════════════════════════════════════════════════

/// Ikon status sinkronisasi untuk dashboard
/// Cara pakai: SyncStatusIcon(isSynced: true)
class SyncStatusIcon extends StatelessWidget {
  final bool isSynced;
  final bool isLoading;

  const SyncStatusIcon({
    super.key,
    required this.isSynced,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryBlue,
        ),
      );
    }

    return Icon(
      isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
      size: 20,
      color: isSynced ? AppColors.successGreen : AppColors.warningYellow,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AVATAR INISIAL
// ══════════════════════════════════════════════════════════════════════════════

/// Avatar lingkaran dengan inisial nama
/// Cara pakai: UserAvatar(name: 'Sarah Wijaya', size: 36)
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? bgColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.bgColor,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.lightBlue,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.smallSemibold.copyWith(
          color: AppColors.primaryBlue,
          fontSize: size * 0.33,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ══════════════════════════════════════════════════════════════════════════════

/// Spinner loading untuk AsyncValue
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════

/// Tampilan saat data kosong
/// Cara pakai:
///   AppEmptyState(
///     icon: Icons.inbox_outlined,
///     title: 'Belum ada soal',
///     subtitle: 'Coba unduh soal terlebih dahulu',
///   )
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textGrey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.textGrey)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppTextStyles.small,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MENU CARD (shortcut di dashboard)
// ══════════════════════════════════════════════════════════════════════════════

/// Card menu shortcut di dashboard mahasiswa
/// Cara pakai:
///   AppMenuCard(
///     icon: Icons.menu_book_outlined,
///     label: 'Bank Soal',
///     subtitle: 'Jelajahi soal latihan',
///     onTap: () => ...,
///   )
class AppMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  const AppMenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: AppSpacings.listItemPadding,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodySemibold),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.small),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.captionBold.copyWith(color: Colors.white),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}