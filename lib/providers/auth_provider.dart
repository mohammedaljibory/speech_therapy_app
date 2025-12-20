import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../config/constants.dart';

/// Authentication Provider - Manages user authentication state
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  String? get userId => _auth.currentUser?.uid;

  AuthProvider() {
    _init();
  }

  /// Initialize auth state listener
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        
        // Update last login
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'lastLoginAt': Timestamp.now()});
      }
    } catch (e) {
      _error = 'فشل في تحميل بيانات المستخدم';
      debugPrint('Error loading user data: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _setLoading(false);
        return true;
      }
      
      _setError('فشل في تسجيل الدخول');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final user = UserModel(
          id: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
          phone: phone?.trim(),
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        _currentUser = user;
        _setLoading(false);
        return true;
      }

      _setError('فشل في إنشاء الحساب');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      _setError('فشل في تسجيل الخروج');
    }
    _setLoading(false);
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{};
      
      if (name != null) updates['name'] = name.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.id)
          .update(updates);

      // Update local user
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في تحديث الملف الشخصي');
      _setLoading(false);
      return false;
    }
  }

  /// Add child to trainer's assigned children
  Future<bool> assignChild(String childId) async {
    if (_currentUser == null) return false;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.id)
          .update({
        'assignedChildrenIds': FieldValue.arrayUnion([childId]),
      });

      _currentUser = _currentUser!.copyWith(
        assignedChildrenIds: [..._currentUser!.assignedChildrenIds, childId],
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error assigning child: $e');
      return false;
    }
  }

  /// Remove child from trainer's assigned children
  Future<bool> unassignChild(String childId) async {
    if (_currentUser == null) return false;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.id)
          .update({
        'assignedChildrenIds': FieldValue.arrayRemove([childId]),
      });

      _currentUser = _currentUser!.copyWith(
        assignedChildrenIds: _currentUser!.assignedChildrenIds
            .where((id) => id != childId)
            .toList(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unassigning child: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }
}
