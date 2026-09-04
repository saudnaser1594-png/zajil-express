import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fpufamgncxusgvxiiucg.supabase.co',
    anonKey:
        'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwdWZhbWduY3h1c2d2eGlpdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxOTQ0NTEsImV4cCI6MjEwMzc3MDQ1MX0.l9vS4MWlom8jqBhoc2T9gGc0MALtzkKxevBqjjPll5I',
  );

  runApp(const ZajilFinancialApp());
}

final supabase = Supabase.instance.client;

class ZajilFinancialApp extends StatelessWidget {
  const ZajilFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'زاجل - السجلات المالية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'Arial',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
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

        if (session == null) {
          return const LoginScreen();
        }

        return const FinancialRecordScreen();
      },
    );
  }
}

// ============================================================
// LOGIN SCREEN
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
  bool hidePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      showMessage('أدخل البريد الإلكتروني');
      return;
    }

    if (password.isEmpty) {
      showMessage('أدخل كلمة المرور');
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
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 75,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Zajil Express Trading',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'نظام السجلات المالية',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          child: loading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
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
// FINANCIAL RECORD SCREEN
// ============================================================

class FinancialRecordScreen extends StatefulWidget {
  const FinancialRecordScreen({super.key});

  @override
  State<FinancialRecordScreen> createState() =>
      _FinancialRecordScreenState();
}

class _FinancialRecordScreenState
    extends State<FinancialRecordScreen> {
  final formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final branchController = TextEditingController();

  final posSalesController =
      TextEditingController(text: '0');

  final requiredDepositController =
      TextEditingController(text: '0');

  final totalController =
      TextEditingController(text: '0.00');

  final actualDepositController =
      TextEditingController(text: '0');

  final notesController = TextEditingController();

  PlatformFile? imageFile;
  PlatformFile? documentFile;

  bool saving = false;
  bool loadingRecords = true;

  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();

    dateController.text = todayString();

    posSalesController.addListener(calculateTotal);
    requiredDepositController.addListener(calculateTotal);

    loadRecords();
  }

  String todayString() {
    final now = DateTime.now();

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  void calculateTotal() {
    final posSales =
        double.tryParse(
              posSalesController.text,
            ) ??
            0;

    final requiredDeposit =
        double.tryParse(
              requiredDepositController.text,
            ) ??
            0;

    final total = posSales + requiredDeposit;

    totalController.text = total.toStringAsFixed(2);
  }

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        imageFile = result.files.first;
      });
    } catch (e) {
      showMessage('تعذر اختيار الصورة');
    }
  }

  Future<void> pickDocument() async {
    try {
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

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        documentFile = result.files.first;
      });
    } catch (e) {
      showMessage('تعذر اختيار المستند');
    }
  }

  Future<String> uploadFile({
    required PlatformFile file,
    required String bucket,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    if (file.bytes == null) {
      throw Exception('تعذر قراءة الملف');
    }

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final safeName =
        file.name.replaceAll(' ', '_');

    final path =
        '${user.id}/${timestamp}_$safeName';

    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          file.bytes!,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return path;
  }

  Future<void> saveRecord() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() {
      saving = true;
    });

    String? imagePath;
    String? documentPath;

    try {
      final posSales =
          double.tryParse(
                posSalesController.text,
              ) ??
              0;

      final requiredDeposit =
          double.tryParse(
                requiredDepositController.text,
              ) ??
              0;

      final actualDeposit =
          double.tryParse(
                actualDepositController.text,
              ) ??
              0;

      final totalAmount =
          posSales + requiredDeposit;

      if (imageFile != null) {
        imagePath = await uploadFile(
          file: imageFile!,
          bucket: 'mada-images',
        );
      }

      if (documentFile != null) {
        documentPath = await uploadFile(
          file: documentFile!,
          bucket: 'documents',
        );
      }

      await supabase.from('financial_records').insert({
        'user_id': user.id,
        'transaction_date': dateController.text,
        'branch': branchController.text.trim(),
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

      showMessage('تم حفظ السجل بنجاح');

      clearForm();

      await loadRecords();
    } catch (e) {
      showMessage('حدث خطأ أثناء الحفظ: $e');

      try {
        if (imagePath != null) {
          await supabase.storage
              .from('mada-images')
              .remove([imagePath]);
        }

        if (documentPath != null) {
          await supabase.storage
              .from('documents')
              .remove([documentPath]);
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> loadRecords() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loadingRecords = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        loadingRecords = true;
      });
    }

    try {
      final result = await supabase
          .from('financial_records')
          .select()
          .eq('user_id', user.id)
          .order(
            'transaction_date',
            ascending: false,
          );

      if (mounted) {
        setState(() {
          records =
              List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      showMessage(
        'تعذر تحميل السجلات: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingRecords = false;
        });
      }
    }
  }

  Future<void> openFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final url = await supabase.storage
          .from(bucket)
          .createSignedUrl(
            path,
            300,
          );

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        showMessage('تعذر فتح الملف');
      }
    } catch (e) {
      showMessage('تعذر فتح الملف: $e');
    }
  }

  Future<void> deleteRecord(
    Map<String, dynamic> record,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف السجل'),
          content: const Text(
            'هل أنت متأكد من حذف السجل والمرفقات المرتبطة به؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final imagePath =
          record['pos_receipt_image'];

      final documentPath =
          record['bank_deposit_receipt'];

      if (imagePath != null &&
          imagePath.toString().isNotEmpty) {
        await supabase.storage
            .from('mada-images')
            .remove([
          imagePath.toString(),
        ]);
      }

      if (documentPath != null &&
          documentPath.toString().isNotEmpty) {
        await supabase.storage
            .from('documents')
            .remove([
          documentPath.toString(),
        ]);
      }

      await supabase
          .from('financial_records')
          .delete()
          .eq(
            'id',
            record['id'],
          );

      showMessage('تم حذف السجل');

      await loadRecords();
    } catch (e) {
      showMessage(
        'تعذر حذف السجل: $e',
      );
    }
  }

  void clearForm() {
    dateController.text = todayString();
    branchController.clear();
    posSalesController.text = '0';
    requiredDepositController.text = '0';
    totalController.text = '0.00';
    actualDepositController.text = '0';
    notesController.clear();

    setState(() {
      imageFile = null;
      documentFile = null;
    });
  }

  String money(dynamic value) {
    final number =
        double.tryParse(
              value.toString(),
            ) ??
            0;

    return '${number.toStringAsFixed(2)} ريال';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نظام السجلات المالية',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: loadRecords,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadRecords,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 900,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'إضافة سجل مالي جديد',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller:
                          dateController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'تاريخ العملية',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          branchController,
                      decoration:
                          const InputDecoration(
                        labelText: 'الفرع',
                        hintText:
                            'اكتب اسم الفرع',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.business,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'اكتب اسم الفرع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          posSalesController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'مبيعات POS',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.point_of_sale,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          requiredDepositController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'المبلغ المطلوب تحويله للبنك',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.account_balance,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          totalController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'الإجمالي',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.calculate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          actualDepositController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'مبلغ الإيداع الفعلي',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.payments,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller:
                          notesController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'ملاحظات',
                        hintText:
                            'اكتب أي ملاحظات إضافية',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.note,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                pickImage,
                            icon:
                                const Icon(
                              Icons.image,
                            ),
                            label:
                                const Text(
                              'إرفاق صورة POS',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                pickDocument,
                            icon:
                                const Icon(
                              Icons.description,
                            ),
                            label:
                                const Text(
                              'PDF / Excel / Word',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imageFile != null)
                      Card(
                        child: ListTile(
                          leading:
                              const Icon(
                            Icons.image,
                            color:
                                Colors.green,
                          ),
                          title: Text(
                            imageFile!.name,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          subtitle:
                              const Text(
                            'سيتم الحفظ في mada-images',
                          ),
                          trailing:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                imageFile =
                                    null;
                              });
                            },
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.red,
                            ),
                          ),
                        ),
                      ),
                    if (documentFile != null)
                      Card(
                        child: ListTile(
                          leading:
                              const Icon(
                            Icons.description,
                            color:
                                Colors.green,
                          ),
                          title: Text(
                            documentFile!.name,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          subtitle:
                              const Text(
                            'سيتم الحفظ في documents',
                          ),
                          trailing:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                documentFile =
                                    null;
                              });
                            },
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.red,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child:
                          ElevatedButton(
                        onPressed:
                            saving
                                ? null
                                : saveRecord,
                        child: saving
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(),
                              )
                            : const Text(
                                'حفظ السجل',
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text(
                      'السجلات السابقة',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (loadingRecords)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    if (!loadingRecords &&
                        records.isEmpty)
                      const Card(
                        child: Padding(
                          padding:
                              EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'لا توجد سجلات حتى الآن',
                            ),
                          ),
                        ),
                      ),
                    ...records.map(
                      buildRecordCard,
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

  Widget buildRecordCard(
    Map<String, dynamic> record,
  ) {
    final pos =
        double.tryParse(
              record['pos_sales']
                  .toString(),
            ) ??
            0;

    final required =
        double.tryParse(
              record['required_deposit']
                  .toString(),
            ) ??
            0;

    final total =
        double.tryParse(
              record['total_amount']
                  .toString(),
            ) ??
            (pos + required);

    final actual =
        double.tryParse(
              record['actual_deposit']
                  .toString(),
            ) ??
            0;

    final difference =
        actual - total;

    final imagePath =
        record['pos_receipt_image'];

    final documentPath =
        record['bank_deposit_receipt'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              record['branch']
                      ?.toString() ??
                  '',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${record['transaction_date'] ?? ''}',
            ),
            const Divider(),
            Text(
              'مبيعات POS: ${money(pos)}',
            ),
            Text(
              'المبلغ المطلوب للبنك: ${money(required)}',
            ),
            Text(
              'الإجمالي: ${money(total)}',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              'الإيداع الفعلي: ${money(actual)}',
            ),
            const SizedBox(height: 8),
            Text(
              'الفرق: ${money(difference)}',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    difference == 0
                        ? Colors.green
                        : difference > 0
                            ? Colors.blue
                            : Colors.red,
              ),
            ),
            if (record['notes'] != null &&
                record['notes']
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'الملاحظات: ${record['notes']}',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (imagePath != null &&
                    imagePath
                        .toString()
                        .isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      openFile(
                        bucket:
                            'mada-images',
                        path:
                            imagePath.toString(),
                      );
                    },
                    icon:
                        const Icon(
                      Icons.image,
                    ),
                    label:
                        const Text(
                      'فتح صورة POS',
                    ),
                  ),
                if (documentPath != null &&
                    documentPath
                        .toString()
                        .isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      openFile(
                        bucket:
                            'documents',
                        path:
                            documentPath
                                .toString(),
                      );
                    },
                    icon:
                        const Icon(
                      Icons.description,
                    ),
                    label:
                        const Text(
                      'فتح المستند',
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    deleteRecord(record);
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                  ),
                  icon:
                      const Icon(
                    Icons.delete,
                  ),
                  label:
                      const Text(
                    'حذف',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
