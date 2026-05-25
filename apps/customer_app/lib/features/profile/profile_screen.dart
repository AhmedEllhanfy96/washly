import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _infoLoading = false;
  bool _passLoading = false;
  bool _showChangePassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    final l10n = context.l10n;
    setState(() => _infoLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.profileUpdated),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _infoLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.passwordsDoNotMatch),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.passwordMinLength),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _passLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            currentPassword: _currentPassCtrl.text,
            newPassword: _newPassCtrl.text,
          );
      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _showChangePassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.profileUpdated),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final l10n = context.l10n;
    final initials = (user?.name.isNotEmpty == true
            ? user!.name.trim().split(' ').map((w) => w[0]).take(2).join()
            : '?')
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Text(l10n.profile,
                style: const TextStyle(color: Colors.white)),
          ),

          // ── Body ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal info
                  _SectionCard(
                    icon: Icons.person_outline,
                    title: l10n.personalInfo,
                    child: Column(
                      children: [
                        _InputField(
                          controller: _nameCtrl,
                          label: l10n.fullName,
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 14),
                        _InputField(
                          controller: _phoneCtrl,
                          label: l10n.phoneNumber,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _infoLoading ? null : _saveInfo,
                            child: _infoLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(l10n.saveChanges),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security
                  _SectionCard(
                    icon: Icons.lock_outline,
                    title: l10n.changePassword,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(
                              () => _showChangePassword = !_showChangePassword),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(
                                _showChangePassword
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showChangePassword
                                    ? 'Hide'
                                    : l10n.changePassword,
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: _showChangePassword
                              ? Column(
                                  children: [
                                    const SizedBox(height: 14),
                                    _PasswordField(
                                      controller: _currentPassCtrl,
                                      label: l10n.currentPassword,
                                      obscure: _obscureCurrent,
                                      onToggle: () => setState(
                                          () => _obscureCurrent = !_obscureCurrent),
                                    ),
                                    const SizedBox(height: 12),
                                    _PasswordField(
                                      controller: _newPassCtrl,
                                      label: l10n.newPassword,
                                      obscure: _obscureNew,
                                      onToggle: () => setState(
                                          () => _obscureNew = !_obscureNew),
                                    ),
                                    const SizedBox(height: 12),
                                    _PasswordField(
                                      controller: _confirmPassCtrl,
                                      label: l10n.confirmNewPassword,
                                      obscure: _obscureConfirm,
                                      onToggle: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: FilledButton(
                                        onPressed:
                                            _passLoading ? null : _changePassword,
                                        child: _passLoading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white))
                                            : Text(l10n.changePassword),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account actions
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.logout,
                            color: AppColors.error, size: 20),
                      ),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(Icons.chevron_right, color: AppColors.error),
                      onTap: () => ref.read(authProvider.notifier).signOut(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
