import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://fpufamgncxusgvxiiucg.supabase.co',
    anonKey: 'ضع_مفتاح_ANON_KEY_الخاص_بمشروعك_هنا',
  );

  runApp(const ZajilFinancialApp());
}

final supabase = Supabase.instance.client;

class ZajilFinancialApp extends StatelessWidget {
  const ZajilFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'زاجل Express - إدارة السجلات المالية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: supabase.auth.currentSession == null 
          ? const AuthScreen() 
          : const DashboardScreen(),
    );
  }
}

// ==========================================
// شاشة تسجيل الدخول وإنشاء الحساب
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleAuth(bool isSignUp) async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isSignUp) {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.')),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          maxWidth: 400,
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 60, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('نظام زاجل المالي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(45),
                              ),
                              onPressed: () => _handleAuth(false),
                              child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _handleAuth(true),
                              child: const Text('إنشاء حساب جديد'),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// شاشة لوحة التحكم وإدخال السجلات المالية
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _branchController = TextEditingController();
  final _posSalesController = TextEditingController();
  final _requiredDepositController = TextEditingController();
  final _actualDepositController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      await supabase.from('financial_records').insert({
        'user_id': user.id,
        'branch': _branchController.text.trim(),
        'pos_sales': double.tryParse(_posSalesController.text) ?? 0.0,
        'required_deposit': double.tryParse(_requiredDepositController.text) ?? 0.0,
        'actual_deposit': double.tryParse(_actualDepositController.text) ?? 0.0,
        'total_amount': double.tryParse(_totalAmountController.text) ?? 0.0,
        'notes': _notesController.text.trim(),
        'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السجل المالي بنجاح!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _branchController.clear();
        _posSalesController.clear();
        _requiredDepositController.clear();
        _actualDepositController.clear();
        _totalAmountController.clear();
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('زاجل Express - السجلات المالية'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            maxWidth: 600,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      const Text('إضافة سجل ماليات جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _branchController,
                        decoration: const InputDecoration(labelText: 'اسم الفرع / المنفذ', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم الفرع' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _posSalesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'مبيعات الشبكة (POS)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _requiredDepositController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الإيداع المطلوب', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _actualDepositController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الإيداع الفعلي', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _totalAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'المبلغ الإجمالي', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'ملاحظات إضافية', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: _saveRecord,
                              child: const Text('حفظ السجل المالي', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
