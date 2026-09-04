import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase ببيانات المشروع
  await Supabase.initialize(
    url: 'https://fpufamgncxusgvxiiucg.supabase.co',
    anonKey: 'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwdWZhbWduY3h1c2d2eGlpdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxOTQ0NTEsImV4cCI6MjEwMzc3MDQ1MX0.l9sV4MWlom8jqBhoc2T9gGc0MALtzkKxevBqjjPll5I',
  );

  runApp(const ZajilFinancialApp());
}

final supabase = Supabase.instance.client;

class ZajilFinancialApp extends StatelessWidget {
  const ZajilFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام السجلات المالية - زاجل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const FinancialRecordScreen(),
    );
  }
}

class FinancialRecordScreen extends StatefulWidget {
  const FinancialRecordScreen({super.key});

  @override
  State<FinancialRecordScreen> createState() => _FinancialRecordScreenState();
}

class _FinancialRecordScreenState extends State<FinancialRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'صيانة';
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  String _fileType = 'image'; // 'image' أو 'document'

  final List<String> _categories = ['صيانة', 'وقود', 'مصاريف تشغيلية', 'رواتب', 'أخرى'];

  // اختيار ملف من الجهاز
  Future<void> _pickFile(FileType type, String categoryType) async {
    final result = await FilePicker.platform.pickFiles(type: type);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _fileType = categoryType;
      });
    }
  }

  // رفع الملف وإدخال السجل في قاعدة البيانات
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? attachmentUrl;

      // 1. رفع المرفق إن وجد
      if (_selectedFile != null && _fileName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uploadPath = '$timestamp\_$_fileName';
        final bucketName = _fileType == 'image' ? 'mada-images' : 'documents';

        // الرفع للحاوية المناسبة
        await supabase.storage.from(bucketName).upload(uploadPath, _selectedFile!);

        // جلب الرابط العام للملف
        attachmentUrl = supabase.storage.from(bucketName).getPublicUrl(uploadPath);
      }

      // 2. إدخال السجل المالي في جدول Financial_records
      await supabase.from('Financial_records').insert({
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'notes': _notesController.text,
        'attachment_url': attachmentUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السجل المالي بنجاح!')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _resetForm() {
    _amountController.clear();
    _notesController.clear();
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة سجل مالي جديد'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // المبلغ
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ (SAR)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال المبلغ' : null,
                ),
                const SizedBox(height: 16),

                // التصنيف
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 16),

                // الملاحظات
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات / بيان الصرف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),

                // أزرار إرفاق الملفات
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickFile(FileType.image, 'image'),
                        icon: const Icon(Icons.image),
                        label: const Text('إرفاق صورة/إيصال'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickFile(FileType.any, 'document'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('إرفاق مستند (PDF/Excel)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // عرض اسم الملف المحدد
                if (_fileName != null)
                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: Icon(_fileType == 'image' ? Icons.image : Icons.insert_drive_file),
                      title: Text(_fileName!, overflow: TextOverflow.ellipsis),
                      subtitle: Text('سيتم الرفع إلى: ${_fileType == 'image' ? 'mada-images' : 'documents'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          _selectedFile = null;
                          _fileName = null;
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // زر حفظ السجل
                _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'حفظ السجل المالي',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
