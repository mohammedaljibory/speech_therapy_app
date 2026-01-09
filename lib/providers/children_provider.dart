import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_model.dart';
import '../config/constants.dart';

/// Children Provider - Manages children data
class ChildrenProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ChildModel> get children => _children;
  ChildModel? get selectedChild => _selectedChild;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load children for a trainer
  Future<void> loadChildren(String trainerId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.childrenCollection)
          .where('trainerId', isEqualTo: trainerId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _children = snapshot.docs
          .map((doc) => ChildModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل قائمة الأطفال');
      _setLoading(false);
      debugPrint('Error loading children: $e');
    }
  }

  /// Load children for a parent
  Future<void> loadChildrenForParent(String parentId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.childrenCollection)
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _children = snapshot.docs
          .map((doc) => ChildModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل قائمة الأطفال');
      _setLoading(false);
      debugPrint('Error loading children: $e');
    }
  }

  /// Get a single child by ID
  Future<ChildModel?> getChild(String childId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.childrenCollection)
          .doc(childId)
          .get();

      if (doc.exists) {
        return ChildModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting child: $e');
      return null;
    }
  }

  /// Set selected child
  void selectChild(ChildModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  /// Clear selected child
  void clearSelection() {
    _selectedChild = null;
    notifyListeners();
  }

  /// Add a new child
  Future<ChildModel?> addChild({
    required String name,
    required int age,
    required String gender,
    required String level,
    required String trainerId,
    String? parentId,
    String? profileImageUrl,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef = _firestore.collection(AppConstants.childrenCollection).doc();

      final child = ChildModel(
        id: docRef.id,
        name: name.trim(),
        age: age,
        gender: gender,
        level: level,
        trainerId: trainerId,
        parentId: parentId,
        profileImageUrl: profileImageUrl,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      await docRef.set(child.toFirestore());

      _children.add(child);
      _children.sort((a, b) => a.name.compareTo(b.name));

      _setLoading(false);
      notifyListeners();
      return child;
    } catch (e) {
      _setError('فشل في إضافة الطفل');
      _setLoading(false);
      debugPrint('Error adding child: $e');
      return null;
    }
  }

  /// Update child
  Future<bool> updateChild({
    required String childId,
    String? name,
    int? age,
    String? gender,
    String? level,
    String? parentId,
    String? profileImageUrl,
    String? notes,
    String? medicalHistory,
    String? familyHistory,
    String? behaviorNotes,
    String? preferences,
    double? height,
    double? weight,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updates['name'] = name.trim();
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (level != null) updates['level'] = level;
      if (parentId != null) updates['parentId'] = parentId;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (notes != null) updates['notes'] = notes.trim();
      if (medicalHistory != null) updates['medicalHistory'] = medicalHistory.trim();
      if (familyHistory != null) updates['familyHistory'] = familyHistory.trim();
      if (behaviorNotes != null) updates['behaviorNotes'] = behaviorNotes.trim();
      if (preferences != null) updates['preferences'] = preferences.trim();
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;

      await _firestore
          .collection(AppConstants.childrenCollection)
          .doc(childId)
          .update(updates);

      // Update local list
      final index = _children.indexWhere((c) => c.id == childId);
      if (index != -1) {
        _children[index] = _children[index].copyWith(
          name: name ?? _children[index].name,
          age: age ?? _children[index].age,
          gender: gender ?? _children[index].gender,
          level: level ?? _children[index].level,
          parentId: parentId ?? _children[index].parentId,
          profileImageUrl: profileImageUrl ?? _children[index].profileImageUrl,
          notes: notes ?? _children[index].notes,
          medicalHistory: medicalHistory ?? _children[index].medicalHistory,
          familyHistory: familyHistory ?? _children[index].familyHistory,
          behaviorNotes: behaviorNotes ?? _children[index].behaviorNotes,
          preferences: preferences ?? _children[index].preferences,
          height: height ?? _children[index].height,
          weight: weight ?? _children[index].weight,
          updatedAt: DateTime.now(),
        );
      }

      // Update selected child if it's the same
      if (_selectedChild?.id == childId) {
        _selectedChild = _children[index];
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في تحديث بيانات الطفل');
      _setLoading(false);
      debugPrint('Error updating child: $e');
      return false;
    }
  }

  /// Soft delete child (set isActive to false)
  Future<bool> deleteChild(String childId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore
          .collection(AppConstants.childrenCollection)
          .doc(childId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      _children.removeWhere((c) => c.id == childId);

      if (_selectedChild?.id == childId) {
        _selectedChild = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في حذف الطفل');
      _setLoading(false);
      debugPrint('Error deleting child: $e');
      return false;
    }
  }

  /// Search children by name
  List<ChildModel> searchChildren(String query) {
    if (query.isEmpty) return _children;

    final lowerQuery = query.toLowerCase();
    return _children
        .where((child) => child.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filter children by level
  List<ChildModel> filterByLevel(String level) {
    return _children.where((child) => child.level == level).toList();
  }

  /// Get children count
  int get childrenCount => _children.length;

  /// Get children by level counts
  Map<String, int> get childrenByLevel {
    final counts = <String, int>{};
    for (final level in AppConstants.childLevels) {
      counts[level] = _children.where((c) => c.level == level).length;
    }
    return counts;
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

  /// Clear all data
  void clear() {
    _children = [];
    _selectedChild = null;
    _error = null;
    notifyListeners();
  }
}
