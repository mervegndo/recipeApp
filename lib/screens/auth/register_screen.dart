// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  final AppStrings strings;

  const RegisterScreen({super.key, required this.strings});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final val = _passwordController.text;
    setState(() {
      _hasMinLength = val.length >= 8;
      _hasUppercase = val.contains(RegExp(r'[A-Z]'));
      _hasLowercase = val.contains(RegExp(r'[a-z]'));
      _hasDigit = val.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.strings.isEnglish
                ? 'Please accept Terms & Privacy Policy to continue.'
                : 'Devam etmek için Kullanım Koşulları ve Gizlilik Politikası\'nı kabul edin.',
          ),
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.strings.isEnglish
            ? 'Registration failed. Please check your information and try again.'
            : 'Kayıt başarısız oldu. Bilgilerinizi kontrol edip tekrar deneyin.';

        final errStr = e.toString().toLowerCase();
        if (errStr.contains('email-already-in-use')) {
          errorMsg = widget.strings.isEnglish
              ? 'This email address is already registered.'
              : 'Bu e-posta adresi zaten kayıtlı.';
        } else if (errStr.contains('weak-password')) {
          errorMsg = widget.strings.isEnglish
              ? 'Your password is too weak.'
              : 'Şifreniz çok zayıf.';
        } else if (errStr.contains('invalid-email')) {
          errorMsg = widget.strings.isEnglish
              ? 'Please enter a valid email address.'
              : 'Geçerli bir e-posta adresi girin.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLegalDialog(bool isPrivacy) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isPrivacy
            ? (widget.strings.isEnglish ? 'Privacy Policy' : 'Gizlilik Politikası')
            : (widget.strings.isEnglish ? 'Terms of Use' : 'Kullanım Koşulları')),
        content: SingleChildScrollView(
          child: Text(isPrivacy
              ? (widget.strings.isEnglish
              ? 'Gusto collects only the data necessary to provide the service. Your personal data is not shared with third parties. You can request deletion of your data at any time.'
              : 'Gusto, yalnızca hizmet sunmak için gerekli verileri toplar. Kişisel verileriniz üçüncü taraflarla paylaşılmaz. Verilerinizin silinmesini istediğiniz zaman talep edebilirsiniz.')
              : (widget.strings.isEnglish
              ? 'By using Gusto you agree to share recipes respectfully, not to post harmful or misleading content, and to comply with community guidelines.'
              : 'Gusto\'yu kullanarak tarifleri saygılı biçimde paylaşmayı, zararlı veya yanıltıcı içerik yayınlamamayı ve topluluk kurallarına uymayı kabul edersiniz.')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.isEnglish ? 'Close' : 'Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _passwordRuleRow(bool met, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? Colors.green : AppColors.textGrey,
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: met ? Colors.green : AppColors.textGrey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showStrengthHints = _passwordController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(s.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isEnglish ? 'Create Account' : 'Hesap Oluştur',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isEnglish
                      ? 'Join the community and share your recipes'
                      : 'Topluluğa katıl ve tariflerini paylaş',
                  style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                ),
                const SizedBox(height: 32),

                // İsim
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [_NameInputFormatter()],
                  decoration: InputDecoration(
                    labelText: s.isEnglish ? 'Full Name' : 'Ad Soyad',
                    prefixIcon: const Icon(Icons.person_outline),
                    helperStyle: const TextStyle(fontSize: 11),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return s.isEnglish ? 'Name cannot be empty' : 'İsim boş olamaz';
                    }
                    if (v.trim().length < 2) {
                      return s.isEnglish
                          ? 'Name must be at least 2 characters'
                          : 'İsim en az 2 karakter olmalı';
                    }
                    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(v.trim())) {
                      return s.isEnglish
                          ? 'Name can only contain letters'
                          : 'İsim yalnızca harf içerebilir';
                    }
                    if (!v.trim().contains(' ')) {
                      return s.isEnglish
                          ? 'Please enter first and last name'
                          : 'Lütfen ad ve soyadınızı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return s.isEnglish ? 'Email cannot be empty' : 'E-posta boş olamaz';
                    }
                    final emailRegex =
                    RegExp(r'^[\w.+\-]+@([a-zA-Z\d\-]+\.)+[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return s.isEnglish
                          ? 'Enter a valid email (e.g. name@mail.com)'
                          : 'Geçerli e-posta girin (ör. ad@mail.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: s.isEnglish ? 'Password' : 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return s.isEnglish ? 'Password cannot be empty' : 'Şifre boş olamaz';
                    }
                    if (v.length < 8) {
                      return s.isEnglish
                          ? 'Password must be at least 8 characters'
                          : 'Şifre en az 8 karakter olmalı';
                    }
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return s.isEnglish
                          ? 'Must contain at least one uppercase letter'
                          : 'En az bir büyük harf içermeli';
                    }
                    if (!v.contains(RegExp(r'[a-z]'))) {
                      return s.isEnglish
                          ? 'Must contain at least one lowercase letter'
                          : 'En az bir küçük harf içermeli';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return s.isEnglish
                          ? 'Must contain at least one number'
                          : 'En az bir rakam içermeli';
                    }
                    return null;
                  },
                ),

                if (showStrengthHints) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _passwordRuleRow(_hasMinLength,
                            s.isEnglish ? 'At least 8 characters' : 'En az 8 karakter'),
                        _passwordRuleRow(_hasUppercase,
                            s.isEnglish ? 'At least one uppercase letter (A-Z)' : 'En az bir büyük harf (A-Z)'),
                        _passwordRuleRow(_hasLowercase,
                            s.isEnglish ? 'At least one lowercase letter (a-z)' : 'En az bir küçük harf (a-z)'),
                        _passwordRuleRow(_hasDigit,
                            s.isEnglish ? 'At least one number (0-9)' : 'En az bir rakam (0-9)'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Şifre tekrar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: s.isEnglish ? 'Confirm Password' : 'Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return s.isEnglish
                          ? 'Passwords do not match'
                          : 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gizlilik & Kullanım Koşulları checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) =>
                          setState(() => _acceptedTerms = val ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textMedium,
                          ),
                          children: [
                            TextSpan(
                                text: s.isEnglish ? 'I agree to the ' : 'Okudum, '),
                            TextSpan(
                              text: s.isEnglish ? 'Terms of Use' : 'Kullanım Koşulları',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalDialog(false),
                            ),
                            TextSpan(text: s.isEnglish ? ' and ' : ' ve '),
                            TextSpan(
                              text: s.isEnglish ? 'Privacy Policy' : 'Gizlilik Politikası',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalDialog(true),
                            ),
                            TextSpan(
                                text: s.isEnglish ? '.' : '\'nı kabul ediyorum.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(s.register,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sadece harf ve boşluğa izin veren formatter
class _NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered =
    newValue.text.replaceAll(RegExp(r'[^a-zA-ZğüşıöçĞÜŞİÖÇ\s]'), '');
    if (filtered == newValue.text) return newValue;
    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}