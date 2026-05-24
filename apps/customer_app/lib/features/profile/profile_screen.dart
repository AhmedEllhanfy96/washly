import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          SnackBar(content: Text(l10n.profileUpdated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        SnackBar(content: Text(l10n.passwordsDoNotMatch), backgroundColor: Colors.red),
      );
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMinLength), backgroundColor: Colors.red),
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
          SnackBar(content: Text(l10n.profileUpdated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + email
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(user?.email ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Personal info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.person_outline,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.personalInfo,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ]),
                  const Divider(height: 20),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _infoLoading ? null : _saveInfo,
                      child: _infoLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l10n.saveChanges),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Change password card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline,
                      color: theme.colorScheme.primary),
                  title: Text(l10n.changePassword,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(_showChangePassword
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () =>
                      setState(() => _showChangePassword = !_showChangePassword),
                ),
                if (_showChangePassword)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _PassField(
                          controller: _currentPassCtrl,
                          label: l10n.currentPassword,
                          icon: Icons.lock_outline,
                          obscure: _obscureCurrent,
                          onToggle: () =>
                              setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        const SizedBox(height: 14),
                        _PassField(
                          controller: _newPassCtrl,
                          label: l10n.newPassword,
                          icon: Icons.lock_open_outlined,
                          obscure: _obscureNew,
                          onToggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        const SizedBox(height: 14),
                        _PassField(
                          controller: _confirmPassCtrl,
                          label: l10n.confirmNewPassword,
                          icon: Icons.lock_open_outlined,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _passLoading ? null : _changePassword,
                            child: _passLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(l10n.changePassword),
                          ),
                        ),
                      ],
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

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback onToggle;

  const _PassField({
    required this.controller,
    required this.label,
    required this.icon,
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
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
