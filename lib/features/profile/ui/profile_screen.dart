import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import 'change_password_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _onSignOut(BuildContext context) async {
    await context.read<AuthCubit>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final initial = (user?.fullName.isNotEmpty ?? false)
              ? user!.fullName[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding)
                .copyWith(top: context.scale(24), bottom: context.scale(24)),
            child: Center(
              child: ConstrainedBox(
                constraints:
                BoxConstraints(maxWidth: context.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Avatar + name ──────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: context.scale(72),
                            height: context.scale(72),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.scale(28),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: context.scale(12)),
                          Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName
                                : 'User',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.scale(32)),

                    // ─── Account access ─────────────────────
                    Text('ACCOUNT ACCESS',
                        style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: context.scale(8)),
                    _InfoTile(
                      icon: Icons.mail_outline,
                      label: 'Email Address (Primary)',
                      value: user?.email ?? '-',
                    ),
                    SizedBox(height: context.scale(24)),

                    // ─── Security & preferences ──────────────
                    Text('SECURITY & PREFERENCES',
                        style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: context.scale(8)),
                    _ActionTile(
                      icon: Icons.lock_reset_outlined,
                      title: 'Change Password',
                      subtitle: 'Update your account security credentials',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // مهم عشان الـ sheet يكبر مع الكيبورد
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const ChangePasswordSheet(),
                        );
                      },
                    ),
                    SizedBox(height: context.scale(32)),

                    AppButton(
                      label: 'Sign Out',
                      icon: Icons.logout,
                      variant: AppButtonVariant.danger,
                      onPressed: () => _onSignOut(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}