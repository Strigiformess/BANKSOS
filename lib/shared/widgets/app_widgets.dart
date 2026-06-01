// lib/shared/widgets/app_widgets.dart
// PIC: Seruni Libertina Islami
// Sprint 1-4: Widget Reusable Dashboard

// // ══════════════════════════════════════════════════════════════════════════════
// // 1. BADGE — KESULITAN & STATUS
// // ══════════════════════════════════════════════════════════════════════════════

// /// Badge berwarna untuk tingkat kesulitan dan status soal.
// ///
// /// Contoh:
// ///   AppBadge.difficulty('easy')    → badge hijau "Mudah"
// ///   AppBadge.difficulty('medium')  → badge kuning "Sedang"
// ///   AppBadge.difficulty('hard')    → badge merah "Sulit"
// ///   AppBadge.status('pending')     → badge kuning "Pending"
// ///   AppBadge.status('published')   → badge hijau "Diterima"

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    const labels = {'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit'};
    return AppBadge(
      label: labels[level.toLowerCase()] ?? level,
      bg: s.bg,
      textColor: s.text,
    );
  }

  factory AppBadge.status(String status) {
    final s = AppBadgeStyle.questionStatus(status);
    const labels = {
      'pending':    'Pending',
      'published':  'Diterima',
      'rejected':   'Ditolak',
      'archived':   'Diarsip',
      'inactive':   'Nonaktif',
      'revision_required': 'Revisi',
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

enum DifficultyFilter { all, easy, medium, hard }

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
          _FilterChip(
            label: 'Semua',
            isSelected: selected == DifficultyFilter.all,
            activeColor: AppColors.primaryBlue,
            onTap: () => onChanged(DifficultyFilter.all),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Mudah',
            isSelected: selected == DifficultyFilter.easy,
            activeColor: AppColors.easyGreen,
            onTap: () => onChanged(DifficultyFilter.easy),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Sedang',
            isSelected: selected == DifficultyFilter.medium,
            activeColor: AppColors.mediumAmber,
            onTap: () => onChanged(DifficultyFilter.medium),
          ),
          const SizedBox(width: 6),
          _FilterChip(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
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
          color: isSelected ? activeColor.withValues(alpha: 0.1) : AppColors.bgWhite,
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

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warningYellow.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 16, color: AppColors.warningYellow),
          const SizedBox(width: 8),
          Text(
            'Mode Offline — Menampilkan data tersimpan',
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

enum BannerType { info, success, warning, error }

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
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      );
    }

    return Icon(
      isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
      size: 20,
      color: isSynced ? AppColors.successGreen : AppColors.warningYellow,
    );
  }
}

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
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
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

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }
}

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
            Icon(icon, size: 56, color: AppColors.textGrey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
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
                width: 44, height: 44,
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
              if (badge != null) ...[
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
              ],
              const Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AppStatCard extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String value;

  const AppStatCard({
    super.key,
    this.emoji,
    this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  }) : assert(emoji != null || icon != null, 'Berikan emoji atau icon');

  @override
  Widget build(BuildContext context) {
    final Color bgColor = iconColor?.withValues(alpha: 0.15) ?? AppColors.warningYellow.withValues(alpha: 0.15);

    return Container(
      padding: AppSpacings.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 16))
                    : Icon(icon!, color: iconColor ?? AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: AppSpacings.sm),
              Text(
                label,
                style: AppTextStyles.smallSemibold.copyWith(color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: AppSpacings.sm),
          Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.textDark)),
        ],
      ),
    );
  }
}