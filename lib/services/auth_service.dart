import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final Logger _logger = Logger('AuthService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userRoleKey = 'user_role';

  AuthService() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      if (const bool.fromEnvironment('dart.vm.product')) {
        // Production logging using Firestore for audit logs
        try {
          _firestore.collection('logs').add({
            'level': record.level.name,
            'time': record.time,
            'message': record.message,
            'loggerName': record.loggerName,
          });
        } catch (error) {
          // Fallback to local storage or console in case Firestore fails
          _logger.warning('Failed to write log to Firestore: $error');
        }
      } else {
        // Development logging to console
        _logger.info('${record.level.name}: ${record.time}: ${record.message}');
      }
    });
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'رقم الهاتف غير صحيح';
              break;
            case 'too-many-requests':
              message = 'تم تجاوز عدد المحاولات المسموح بها';
              break;
            default:
              message = 'حدث خطأ أثناء إرسال رمز التحقق';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('حدث خطأ أثناء إرسال رمز التحقق');
    }
  }

  // Verify OTP
  Future<User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'رمز التحقق غير صحيح';
          break;
        default:
          message = 'حدث خطأ أثناء التحقق من الرمز';
      }
      throw Exception(message);
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;
        default:
          message = 'حدث خطأ أثناء تسجيل الدخول';
      }
      throw Exception(message);
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'كلمة المرور ضعيفة جداً';
          break;
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;
        default:
          message = 'حدث خطأ أثناء إنشاء الحساب';
      }
      throw Exception(message);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  // Set user role (volunteer or regular user)
  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث الملف الشخصي');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.severe('Error signing out: $e');
      rethrow;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Create admin account if it doesn't exist
  Future<void> createInitialAdminAccount() async {
    const adminEmail = 'admin@waterfinder.com';
    const adminPassword = 'Admin123!@#';
    const adminName = 'مسؤول النظام';

    try {
      // First try to get if admin account exists
      final adminUserQuery = await isEmailRegistered(adminEmail);
      
      if (!adminUserQuery) {
        // Admin account doesn't exist, create it
        try {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          
          if (credential.user != null) {
            await credential.user!.updateDisplayName(adminName);
            await setUserRole('admin');
            _logger.info('Admin account created successfully');
          }
        } catch (e) {
          _logger.severe('Error creating admin account: $e');
        }
      } else {
        _logger.info('Admin account already exists');
      }

      // Make sure we're signed out after creating/checking admin account
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    } catch (e) {
      _logger.severe('Error checking/creating admin account: $e');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'لا يوجد حساب بهذا البريد الإلكتروني';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        default:
          return 'حدث خطأ في تسجيل الدخول';
      }
    }
    return 'حدث خطأ غير متوقع';
  }

  // Check if email exists without using deprecated method
  Future<bool> checkEmailExists(String email) async {
    try {
      // Instead of using fetchSignInMethodsForEmail, we'll try to sign in with an invalid password
      // This is a workaround that respects email enumeration protection
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'invalidpassword_' + DateTime.now().toString(),
      );
      return true; // This line won't be reached if the email doesn't exist
    } catch (e) {
      if (e is FirebaseAuthException) {
        // "wrong-password" means the email exists but password was wrong
        // "user-not-found" means the email doesn't exist
        return e.code == 'wrong-password';
      }
      return false;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      // Instead of using fetchSignInMethodsForEmail, we'll try to create a credential
      // and catch the exception if the email exists
      final credential = EmailAuthProvider.credential(
        email: email,
        password: 'temporary-password-for-check',
      );
      
      try {
        await _auth.signInWithCredential(credential);
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          // Email exists but password is wrong (which is what we expect)
          return true;
        }
        return false;
      }
    } catch (e) {
      _logger.warning('Error checking email registration: $e');
      return false;
    }
  }

  Future<void> handleAuthError(dynamic error) async {
    if (error is FirebaseAuthException) {
      _logger.warning('Authentication error: ${error.message}');
      switch (error.code) {
        // ...existing code...
      }
    } else {
      _logger.severe('Unexpected authentication error: $error');
    }
  }

  // Fix string interpolation
  String getUserDisplayName(String uid) {
    return 'User: $uid';  // Using string interpolation instead of concatenation
  }

  Future<DocumentReference> createUserDocument(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': Timestamp.now(),
      });
      return docRef;
    } catch (error) {
      _logger.severe('Error creating user document: $error');
      rethrow;
    }
  }
}