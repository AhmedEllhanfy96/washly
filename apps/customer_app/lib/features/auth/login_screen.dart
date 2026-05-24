import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/language_toggle_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  static const _colorTop = Color(0xFF0D47A1);
  static const _colorMid = Color(0xFF1565C0);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_colorTop, _colorMid, Color(0xFF00ACC1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: const LanguageToggleButton(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.signInToBook,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 36),
                      // Form card
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 16,
                        shadowColor: Colors.black38,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? l10n.enterValidEmail
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon:
                                        const Icon(Icons.lock_outlined),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                      onPressed: () => setState(
                                          () => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.length < 6)
                                          ? l10n.passwordMinLength
                                          : null,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _colorTop,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : Text(l10n.signIn,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () => context.go('/register'),
                                    child: Text(l10n.noAccountSignUp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
