import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fpufamgncxusgvxiiucg.supabase.co',
    anonKey: 'sb_publishable_hIFcvyNW57aF4aUapGBBWA_YC8YTIGJ',
  );

  runApp(const ZajilFinancialApp());
}

final supabase = Supabase.instance.client;

class ZajilFinancialApp extends StatelessWidget {
  const ZajilFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'زاجل Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ?? supabase.auth.currentSession;
          if (session != null) {
            return const DashboardScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

// شاشة تسجيل الدخول
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _auth(bool isSignUp) async {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ادخل البريد وكلمة المرور')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (isSignUp) {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الالكتروني', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  _loading 
                      ? const CircularProgressIndicator() 
                      : Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(45)),
                              onPressed: () => _auth(false),
                              child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () => _auth(true),
                              child: const Text('انشاء حساب جديد'),
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

// شاشة السجلات المالية
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _branch = TextEditingController();
  final _pos = TextEditingController();
  final _required = TextEditingController();
  final _actual = TextEditingController();
  final _total = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _branch.dispose();
    _pos.dispose();
    _required.dispose();
    _actual.dispose();
    _total.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = supabase.auth.currentUser;
      await supabase.from('financial_records').insert({
        'user_id': user!.id,
        'branch': _branch.text.trim(),
        'pos_sales': double.tryParse(_pos.text) ?? 0,
        'required_deposit': double.tryParse(_required.text) ?? 0,
        'actual_deposit': double.tryParse(_actual.text) ?? 0,
        'total_amount': double.tryParse(_total.text) ?? 0,
        'notes': _notes.text.trim(),
        'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _branch.clear();
        _pos.clear();
        _required.clear();
        _actual.clear();
        _total.clear();
        _notes.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('زاجل Express - السجلات المالية', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async => await supabase.auth.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إضافة سجل جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _branch,
                        decoration: const InputDecoration(labelText: 'اسم الفرع', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pos,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'مبيعات POS', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _required,
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
                              controller: _actual,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الإيداع الفعلي', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _total,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'المبلغ الإجمالي', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      _saving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: _save,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('حفظ السجل', style: TextStyle(color: Colors.white, fontSize: 16)),
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
