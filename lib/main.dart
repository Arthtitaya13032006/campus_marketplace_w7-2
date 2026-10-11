// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'screens/main_scaffold.dart';
import 'repositories/item_repository.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'database/app_database.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 1. สร้าง AppDatabase() ขึ้นมา 1 ตัว เก็บไว้ในตัวแปร db
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      // 2. ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  // 3. เพิ่ม field รับค่า AppDatabase ใน MyApp
  final AppDatabase db;
  final ItemRepository? repository;

  const MyApp({super.key, required this.db, this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        itemRepositories: [
          repository ?? ItemRepositoryApi(),
          ItemRepositoryFirestore(),
        ],
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}
