import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

// تعريف الألوان الجديدة كثوابت
const Color primaryBlue = Color(0xFF1E3A8A); // أزرق غامق ملكي
const Color accentGold = Color(0xFFFBBF24);  // أصفر ذهبي ساطع

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // الاستماع لتغير حالة التسجيل والتوجيه تلقائياً
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  // دالة مشتركة للتعامل مع العمليات
  Future<void> _handleAuth(Future<AuthResponse> Function() authMethod, String successMessage) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('يرجى ملء كافة الحقول');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authMethod();
      _showSuccessSnackBar(successMessage);
    } catch (e) {
      _showErrorSnackBar('فشلت العملية: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryBlue));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // الخلفية الأساسية باللون الأزرق
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentGold, width: 2), // إطار ذهبي
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الأيقونة باللون الأزرق
                      const Icon(Icons.account_balance_wallet, size: 80, color: primaryBlue),
                      const SizedBox(height: 20),
                      // العنوان باللون الأزرق
                      const Text(
                        'نظام زاجل المالي',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlue),
                      ),
                      const SizedBox(height: 40),
                      // حقول الإدخال بتنسيق ذهبي
                      TextField(
                        controller: _emailController,
                        decoration: _buildInputDecoration('البريد الإلكتروني', Icons.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration('كلمة المرور', Icons.lock),
                        obscureText: true,
                      ),
                      const SizedBox(height: 40),
                      // أزرار العمليات
                      if (_isLoading)
                        const CircularProgressIndicator(color: accentGold)
                      else ...[
                        // زر تسجيل الدخول (أزرق بخط ذهبي)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: accentGold,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleAuth(
                              () => Supabase.instance.client.auth.signInWithPassword(email: _emailController.text, password: _passwordController.text),
                              'تم تسجيل الدخول!'
                            ),
                            child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // زر إنشاء حساب (ذهبي بخط أزرق)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBlue,
                              backgroundColor: accentGold,
                              side: const BorderSide(color: accentGold, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleAuth(
                              () => Supabase.instance.client.auth.signUp(email: _emailController.text, password: _passwordController.text),
                              'تم إنشاء الحساب بنجاح!'
                            ),
                            child: const Text('إنشاء حساب جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // تنسيق حقول الإدخال
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: primaryBlue),
      prefixIcon: Icon(icon, color: primaryBlue),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryBlue), borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accentGold, width: 2), borderRadius: BorderRadius.circular(10)),
    );
  }
}
