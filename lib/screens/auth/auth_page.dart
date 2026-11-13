import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../services/shop_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = context.read<ShopRepository>();
      if (_registering) {
        await repository.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await repository.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authError(error));
    } catch (error) {
      setState(() => _error = 'Unable to continue. Please try again. ($error)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error = 'Enter your email above to receive a password reset link.',
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.midnight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.warmBeige, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Gold/Midnight decorative header bar
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.midnight, AppColors.gold],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    semanticLabel: 'BabyShop logo',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'BabyShop',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                color: AppColors.midnight,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'A World of Little Wonders.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Premium quality for every precious moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              _registering
                                  ? 'Create your account'
                                  : 'Welcome back',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_registering) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppColors.navy,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().length < 2
                                        ? 'Enter your name'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppColors.navy,
                                ),
                              ),
                              validator: (value) =>
                                  value == null ||
                                          !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                              .hasMatch(value.trim())
                                      ? 'Enter a valid email address'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.navy,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.navy,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6
                                      ? 'Use at least 6 characters'
                                      : null,
                            ),
                            if (!_registering)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resetPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.gold,
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warmBeige,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: AppColors.ivory,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _busy
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ivory,
                                      ),
                                    )
                                  : Text(
                                      _registering
                                          ? 'Create Account'
                                          : 'Sign In',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _registering = !_registering;
                                      _error = null;
                                    }),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.midnight,
                              ),
                              child: Text(
                                _registering
                                    ? 'Already have an account? Sign in'
                                    : 'New to BabyShop? Create an account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
          ),
        ),
      ),
    );
  }
}
