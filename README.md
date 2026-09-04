import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const String supabaseUrl = 'https://fpufamgncxusgvxiiucg.supabase.co';

// ضع هنا anon key الخاص بمشروع Supabase
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ZajilFinancialApp());
}

final supabase = Supabase.instance.client;

class ZajilFinancialApp extends StatelessWidget {
  const ZajilFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zajil Express Trading',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorSchemeSeed: Colors.blue,
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session != null) {
          return const FinancialRecordScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('أدخل البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('حدث خطأ أثناء تسجيل الدخول');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 70,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Zajil Express Trading',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'النظام المالي',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => login(),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(fontSize: 17),
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
      ),
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class FinancialRecordScreen extends StatefulWidget {
  const FinancialRecordScreen({super.key});

  @override
  State<FinancialRecordScreen> createState() =>
      _FinancialRecordScreenState();
}

class _FinancialRecordScreenState
    extends State<FinancialRecordScreen> {
  final branchController = TextEditingController();
  final posSalesController = TextEditingController();
  final requiredDepositController = TextEditingController();
  final totalController = TextEditingController();
  final actualDepositController = TextEditingController();
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  PlatformFile? selectedImage;
  PlatformFile? selectedDocument;

  List<Map<String, dynamic>> records = [];

  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    posSalesController.addListener(calculateTotal);
    requiredDepositController.addListener(calculateTotal);

    loadRecords();
  }

  // ============================================================
  // CALCULATE TOTAL
  // ============================================================

  void calculateTotal() {
    final posSales =
        double.tryParse(posSalesController.text.trim()) ?? 0;

    final requiredDeposit =
        double.tryParse(requiredDepositController.text.trim()) ?? 0;

    final total = posSales + requiredDeposit;

    totalController.text = total.toStringAsFixed(2);
  }

  // ============================================================
  // LOAD RECORDS
  // ============================================================

  Future<void> loadRecords() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await supabase
          .from('financial_records')
          .select()
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false);

      records = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      showMessage('تعذر تحميل السجلات: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // SELECT IMAGE
  // ============================================================

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      selectedImage = result.files.first;
    });
  }

  // ============================================================
  // SELECT DOCUMENT
  // ============================================================

  Future<void> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'xls',
        'xlsx',
        'doc',
        'docx',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      selectedDocument = result.files.first;
    });
  }

  // ============================================================
  // SAFE FILE NAME
  // ============================================================

  String safeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<String?> uploadImage(String userId) async {
    if (selectedImage == null || selectedImage!.bytes == null) {
      return null;
    }

    final fileName = safeFileName(selectedImage!.name);

    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage
        .from('mada-images')
        .uploadBinary(
          path,
          selectedImage!.bytes!,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return path;
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<String?> uploadDocument(String userId) async {
    if (selectedDocument == null ||
        selectedDocument!.bytes == null) {
      return null;
    }

    final fileName = safeFileName(selectedDocument!.name);

    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage
        .from('documents')
        .uploadBinary(
          path,
          selectedDocument!.bytes!,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return path;
  }

  // ============================================================
  // SAVE RECORD
  // ============================================================

  Future<void> saveRecord() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    final branch = branchController.text.trim();

    final posSales =
        double.tryParse(posSalesController.text.trim()) ?? 0;

    final requiredDeposit =
        double.tryParse(requiredDepositController.text.trim()) ?? 0;

    final totalAmount = posSales + requiredDeposit;

    final actualDeposit =
        double.tryParse(actualDepositController.text.trim()) ?? 0;

    if (branch.isEmpty) {
      showMessage('أدخل اسم الفرع');
      return;
    }

    setState(() {
      saving = true;
    });

    String? imagePath;
    String? documentPath;

    try {
      // رفع صورة إيصال نقاط البيع
      if (selectedImage != null) {
        imagePath = await uploadImage(user.id);
      }

      // رفع مستند التحويل البنكي
      if (selectedDocument != null) {
        documentPath = await uploadDocument(user.id);
      }

      await supabase.from('financial_records').insert({
        'user_id': user.id,
        'transaction_date':
            '${selectedDate.year.toString().padLeft(4, '0')}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}',
        'branch': branch,
        'pos_sales': posSales,
        'required_deposit': requiredDeposit,
        'total_amount': totalAmount,
        'actual_deposit': actualDeposit,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'pos_receipt_image': imagePath,
        'bank_deposit_receipt': documentPath,
      });

      clearForm();

      await loadRecords();

      showMessage('تم حفظ السجل بنجاح');
    } catch (e) {
      showMessage('حدث خطأ أثناء الحفظ: $e');
    }

    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void clearForm() {
    branchController.clear();
    posSalesController.clear();
    requiredDepositController.clear();
    totalController.clear();
    actualDepositController.clear();
    notesController.clear();

    setState(() {
      selectedImage = null;
      selectedDocument = null;
      selectedDate = DateTime.now();
    });
  }

  // ============================================================
  // SIGNED URL
  // ============================================================

  Future<void> openStorageFile(
    String bucket,
    String path,
  ) async {
    try {
      final url = await supabase.storage
          .from(bucket)
          .createSignedUrl(path, 300);

      final uri = Uri.parse(url);

      await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      showMessage('تعذر فتح الملف');
    }
  }

  // ============================================================
  // DELETE RECORD
  // ============================================================

  Future<void> deleteRecord(
    Map<String, dynamic> record,
  ) async {
    final id = record['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف السجل'),
            content: const Text(
              'هل أنت متأكد من حذف هذا السجل؟',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final imagePath = record['pos_receipt_image'];
      final documentPath =
          record['bank_deposit_receipt'];

      if (imagePath != null &&
          imagePath.toString().isNotEmpty) {
        await supabase.storage
            .from('mada-images')
            .remove([imagePath.toString()]);
      }

      if (documentPath != null &&
          documentPath.toString().isNotEmpty) {
        await supabase.storage
            .from('documents')
            .remove([documentPath.toString()]);
      }

      await supabase
          .from('financial_records')
          .delete()
          .eq('id', id);

      await loadRecords();

      showMessage('تم حذف السجل');
    } catch (e) {
      showMessage('تعذر حذف السجل: $e');
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    branchController.dispose();
    posSalesController.dispose();
    requiredDepositController.dispose();
    totalController.dispose();
    actualDepositController.dispose();
    notesController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'النظام المالي',
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: loadRecords,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: loadRecords,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildForm(),

              const SizedBox(height: 25),

              const Text(
                'السجلات المالية',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (records.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Text(
                        'لا توجد سجلات حتى الآن',
                      ),
                    ),
                  ),
                )
              else
                ...records.map(buildRecordCard),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget buildForm() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إضافة سجل مالي',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            InkWell(
              onTap: selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ العملية',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}/'
                  '${selectedDate.month.toString().padLeft(2, '0')}/'
                  '${selectedDate.year}',
                ),
              ),
            ),

            const SizedBox(height: 14),

            buildTextField(
              controller: branchController,
              label: 'الفرع',
              icon: Icons.business,
            ),

            const SizedBox(height: 14),

            buildNumberField(
              controller: posSalesController,
              label: 'مبيعات نقاط البيع POS',
              icon: Icons.point_of_sale,
            ),

            const SizedBox(height: 14),

            buildNumberField(
              controller: requiredDepositController,
              label: 'المبلغ المطلوب تحويله للبنك',
              icon: Icons.account_balance,
            ),

            const SizedBox(height: 14),

            TextField(
              controller: totalController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'إجمالي المبلغ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
              ),
            ),

            const SizedBox(height: 14),

            buildNumberField(
              controller: actualDepositController,
              label: 'المبلغ المحول فعلياً',
              icon: Icons.payments,
            ),

            const SizedBox(height: 14),

            buildTextField(
              controller: notesController,
              label: 'ملاحظات',
              icon: Icons.notes,
              maxLines: 3,
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                selectedImage == null
                    ? 'إرفاق صورة إيصال POS'
                    : 'الصورة: ${selectedImage!.name}',
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: pickDocument,
              icon: const Icon(Icons.attach_file),
              label: Text(
                selectedDocument == null
                    ? 'إرفاق مستند التحويل'
                    : 'المستند: ${selectedDocument!.name}',
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveRecord,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  saving
                      ? 'جاري الحفظ...'
                      : 'حفظ السجل',
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ============================================================
  // RECORD CARD
  // ============================================================

  Widget buildRecordCard(
    Map<String, dynamic> record,
  ) {
    final posSales =
        double.tryParse(
              '${record['pos_sales'] ?? 0}',
            ) ??
            0;

    final requiredDeposit =
        double.tryParse(
              '${record['required_deposit'] ?? 0}',
            ) ??
            0;

    final total =
        double.tryParse(
              '${record['total_amount'] ?? 0}',
            ) ??
            (posSales + requiredDeposit);

    final actual =
        double.tryParse(
              '${record['actual_deposit'] ?? 0}',
            ) ??
            0;

    final difference = actual - total;

    final imagePath =
        record['pos_receipt_image']?.toString();

    final documentPath =
        record['bank_deposit_receipt']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${record['branch'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => deleteRecord(record),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),

            const Divider(),

            infoRow(
              'التاريخ',
              '${record['transaction_date'] ?? ''}',
            ),

            infoRow(
              'مبيعات POS',
              posSales.toStringAsFixed(2),
            ),

            infoRow(
              'المبلغ المطلوب تحويله',
              requiredDeposit.toStringAsFixed(2),
            ),

            infoRow(
              'الإجمالي',
              total.toStringAsFixed(2),
            ),

            infoRow(
              'المحول فعلياً',
              actual.toStringAsFixed(2),
            ),

            infoRow(
              'الفرق',
              difference.toStringAsFixed(2),
            ),

            if (record['notes'] != null &&
                record['notes'].toString().isNotEmpty)
              infoRow(
                'ملاحظات',
                record['notes'].toString(),
              ),

            const SizedBox(height: 10),

            if (imagePath != null &&
                imagePath.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () {
                  openStorageFile(
                    'mada-images',
                    imagePath,
                  );
                },
                icon: const Icon(Icons.image),
                label: const Text(
                  'فتح إيصال POS',
                ),
              ),

            if (documentPath != null &&
                documentPath.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () {
                  openStorageFile(
                    'documents',
                    documentPath,
                  );
                },
                icon: const Icon(Icons.description),
                label: const Text(
                  'فتح مستند التحويل',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
