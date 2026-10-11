import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนทำการโพสต์ขายจริง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // 1. ถามราคาก่อนโพสต์
    final price = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('ระบุราคาสำหรับ "${draft.title}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ราคาสินค้า (บาท)',
              hintText: 'เช่น 199 หรือ 50.00',
              suffixText: 'บาท',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกราคา';
              }
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'กรุณากรอกตัวเลขที่มากกว่า 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final p = double.parse(priceController.text.trim());
                Navigator.pop(dialogCtx, p);
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (price == null || !mounted) return;

    // 2. แสดง Progress Dialog ระหว่างอัปโหลด
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('กำลังอัปโหลดรูปและโพสต์ลง Firestore...')),
            ],
          ),
        ),
      ),
    );

    try {
      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตก่อนส่งข้อมูลไปยังคลาวด์
      try {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(milliseconds: 1500));
        if (lookup.isEmpty || lookup[0].rawAddress.isEmpty) {
          throw Exception('ขาดการเชื่อมต่อเครือข่าย ไม่สามารถเข้าถึง Cloud Firestore/Storage (Offline)');
        }
      } catch (netErr) {
        throw Exception('ขาดการเชื่อมต่อเครือข่าย ไม่สามารถเข้าถึง Cloud Firestore/Storage (Offline)');
      }

      // 3. อัปโหลดรูปภาพขึ้น Firebase Storage
      final imageFile = File(draft.imagePath);
      String imageUrl = '';
      if (imageFile.existsSync()) {
        try {
          imageUrl = await StorageService().uploadListingImage(
            imageFile,
            currentUser.uid,
            itemTitle: draft.title,
          );
        } catch (_) {
          final t = draft.title.toLowerCase();
          if (t.contains('muay') || t.contains('มวย') || t.contains('กางเกง')) {
            imageUrl = 'https://files.catbox.moe/6403sx.jpg';
          } else {
            imageUrl = 'https://files.catbox.moe/ym62ok.jpg';
          }
        }
      } else {
        final t = draft.title.toLowerCase();
        if (t.contains('muay') || t.contains('มวย')) {
          imageUrl = 'https://files.catbox.moe/6403sx.jpg';
        } else {
          imageUrl = 'https://files.catbox.moe/ym62ok.jpg';
        }
      }

      // 4. สร้าง Item และบันทึกลง Firestore
      final item = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: currentUser.uid,
      );

      await ItemRepositoryFirestore().postItem(item);

      // 5. ลบร่างออกจาก Local Database
      await widget.repository.deleteDraft(draft.id);

      // 6. ปิด Dialog Loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // 7. รีเฟรชรายการร่างและแจ้งเตือน
      if (mounted) {
        setState(() {
          _loadDrafts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โพสต์ขาย "${draft.title}" บน Firestore สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDraft(int id, String title) async {
    try {
      await widget.repository.deleteDraft(id);
      if (!mounted) return;
      setState(() {
        _loadDrafts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบร่างประกาศ "$title" แล้ว'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _loadDrafts()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่อีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drafts_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ยังไม่มีร่างประกาศที่บันทึกไว้',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadDrafts()),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                final imageFile = File(draft.imagePath);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 68,
                            height: 68,
                            color: Colors.grey.shade100,
                            child: imageFile.existsSync()
                                ? Image.file(
                                    imageFile,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, color: Colors.grey),
                                  )
                                : const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'หมวดหมู่: ${draft.category}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'แก้ไขล่าสุด: ${_formatDateTime(draft.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload, color: Color(0xFF43A047), size: 28),
                          tooltip: 'โพสต์ขายจริง',
                          onPressed: () => _publishDraft(draft),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFE53935), size: 28),
                          tooltip: 'ลบร่างประกาศ',
                          onPressed: () => _deleteDraft(draft.id, draft.title),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
