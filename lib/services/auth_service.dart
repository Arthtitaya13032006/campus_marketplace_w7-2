import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  // Stream สำหรับติดตามสถานะการล็อกอินของผู้ใช้
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ดึงข้อมูลผู้ใช้ปัจจุบันที่ล็อกอินอยู่
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    // initialize() ต้องเรียกครั้งเดียวก่อนใช้งานเมธอดอื่นของ GoogleSignIn เสมอ
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  /// เข้าสู่ระบบด้วย Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      // authenticate() เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google (แทนที่ signIn() ในเวอร์ชันเก่า)
      final googleUser = await _googleSignIn.authenticate();

      // idToken ได้แบบ synchronous จาก authentication ของบัญชีที่ล็อกอินแล้ว
      final idToken = googleUser.authentication.idToken;

      // accessToken ต้องขอเพิ่มผ่าน authorizationClient แยกต่างหาก
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  /// สมัครสมาชิกด้วย Email และ Password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ: $e');
    }
  }

  /// เข้าสู่ระบบด้วย Email และ Password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ: $e');
    }
  }

  /// ออกจากระบบ
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการออกจากระบบ: $e');
    }
  }

  /// แปลงรหัส Error code จาก FirebaseAuthException เป็นข้อความภาษาไทย
  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'ข้อมูลยืนยันตัวตนจาก Google ไม่ถูกต้องหรือหมดอายุ กรุณาลองเข้าสู่ระบบใหม่';
      case 'user-disabled':
        return 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
      case 'operation-not-allowed':
        return 'วิธีการเข้าสู่ระบบนี้ยังไม่เปิดใช้งานในระบบ';
      case 'too-many-requests':
        return 'มีการส่งคำขอบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่อีกครั้ง';
      case 'network-request-failed':
        return 'การเชื่อมต่อเครือข่ายล้มเหลว กรุณาตรวจสอบอินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}
