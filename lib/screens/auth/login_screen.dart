// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGuestLogin;
  final AppStrings strings;

  const LoginScreen({
    super.key,
    required this.onGuestLogin,
    required this.strings,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.forgotPassword),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: widget.strings.isEnglish
                ? 'Your email address'
                : 'E-posta adresiniz',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              try {
                await _authService
                    .resetPassword(emailController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.strings.passwordResetSent),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(widget.strings.send),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/recipeapplogo.png',
                        width: 140,
                        height: 140,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lezzet Rehberi',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      Text(
                        widget.strings.tagline,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Text(widget.strings.login,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return widget.strings.isEnglish
                          ? 'Email cannot be empty'
                          : 'E-posta boş olamaz';
                    if (!v.contains('@'))
                      return widget.strings.isEnglish
                          ? 'Enter a valid email'
                          : 'Geçerli e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText:
                    widget.strings.isEnglish ? 'Password' : 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return widget.strings.isEnglish
                          ? 'Password cannot be empty'
                          : 'Şifre boş olamaz';
                    return null;
                  },
                ),

                // Şifremi unuttum
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPassword,
                    child: Text(widget.strings.forgotPassword,
                        style:
                        const TextStyle(color: AppColors.primary)),
                  ),
                ),

                const SizedBox(height: 8),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(widget.strings.login,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Misafir
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onGuestLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.strings.continueAsGuest,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Kayıt ol
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.strings.noAccountYet,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                              strings: widget.strings),
                        ),
                      ),
                      child: Text(widget.strings.register,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}