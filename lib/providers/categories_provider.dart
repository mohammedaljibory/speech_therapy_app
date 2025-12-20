import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/word_model.dart';
import '../config/constants.dart';

/// Categories Provider - Manages categories and words
class CategoriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  List<WordModel> _words = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<WordModel> get words => _words;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all categories
  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      // If no categories exist, create defaults
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل الأقسام');
      _setLoading(false);
      debugPrint('Error loading categories: $e');
    }
  }

  /// Create default categories
  Future<void> _createDefaultCategories() async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < AppConstants.defaultCategories.length; i++) {
        final catData = AppConstants.defaultCategories[i];
        final docRef = _firestore.collection(AppConstants.categoriesCollection).doc(catData['id']);

        final category = CategoryModel(
          id: catData['id'],
          name: catData['name'],
          nameEn: catData['nameEn'],
          icon: catData['icon'],
          colorValue: catData['color'],
          order: i,
          createdAt: DateTime.now(),
        );

        batch.set(docRef, category.toFirestore());
        _categories.add(category);
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating default categories: $e');
    }
  }

  /// Add new category
  Future<CategoryModel?> addCategory({
    required String name,
    required String nameEn,
    required String icon,
    required int colorValue,
    String? description,
    String? createdBy,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef = _firestore.collection(AppConstants.categoriesCollection).doc();

      final category = CategoryModel(
        id: docRef.id,
        name: name.trim(),
        nameEn: nameEn.trim(),
        icon: icon,
        colorValue: colorValue,
        description: description?.trim(),
        order: _categories.length,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await docRef.set(category.toFirestore());

      _categories.add(category);
      _setLoading(false);
      notifyListeners();
      return category;
    } catch (e) {
      _setError('فشل في إضافة القسم');
      _setLoading(false);
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  /// Update category
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? nameEn,
    String? icon,
    int? colorValue,
    String? description,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name.trim();
      if (nameEn != null) updates['nameEn'] = nameEn.trim();
      if (icon != null) updates['icon'] = icon;
      if (colorValue != null) updates['colorValue'] = colorValue;
      if (description != null) updates['description'] = description.trim();

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update(updates);

      // Update local list
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(
          name: name ?? _categories[index].name,
          nameEn: nameEn ?? _categories[index].nameEn,
          icon: icon ?? _categories[index].icon,
          colorValue: colorValue ?? _categories[index].colorValue,
          description: description ?? _categories[index].description,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في تحديث القسم');
      _setLoading(false);
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if category has words
      final wordsSnapshot = await _firestore
          .collection(AppConstants.wordsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      if (wordsSnapshot.docs.isNotEmpty) {
        _setError('لا يمكن حذف قسم يحتوي على كلمات');
        _setLoading(false);
        return false;
      }

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update({'isActive': false});

      _categories.removeWhere((c) => c.id == categoryId);

      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في حذف القسم');
      _setLoading(false);
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  /// Select category
  void selectCategory(CategoryModel category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Clear category selection
  void clearCategorySelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  // ============ WORDS MANAGEMENT ============

  /// Load words for a category
  Future<void> loadWords(String categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.wordsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('text')
          .get();

      _words = snapshot.docs
          .map((doc) => WordModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل الكلمات');
      _setLoading(false);
      debugPrint('Error loading words: $e');
    }
  }

  /// Load all words
  Future<void> loadAllWords() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.wordsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      _words = snapshot.docs
          .map((doc) => WordModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل الكلمات');
      _setLoading(false);
      debugPrint('Error loading all words: $e');
    }
  }

  /// Get word by ID
  Future<WordModel?> getWord(String wordId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.wordsCollection)
          .doc(wordId)
          .get();

      if (doc.exists) {
        return WordModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting word: $e');
      return null;
    }
  }

  /// Add new word
  Future<WordModel?> addWord({
    required String text,
    String? textEn,
    required String categoryId,
    required String imageUrl,
    required String correctPronunciationUrl,
    String? description,
    String? phonetic,
    int difficulty = 1,
    required String createdBy,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef = _firestore.collection(AppConstants.wordsCollection).doc();

      final word = WordModel(
        id: docRef.id,
        text: text.trim(),
        textEn: textEn?.trim(),
        categoryId: categoryId,
        imageUrl: imageUrl,
        correctPronunciationUrl: correctPronunciationUrl,
        description: description?.trim(),
        phonetic: phonetic?.trim(),
        difficulty: difficulty,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await docRef.set(word.toFirestore());

      // Update category word count
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update({'wordCount': FieldValue.increment(1)});

      // Update local category
      final catIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        _categories[catIndex] = _categories[catIndex].copyWith(
          wordCount: _categories[catIndex].wordCount + 1,
        );
      }

      _words.add(word);
      _words.sort((a, b) => a.text.compareTo(b.text));

      _setLoading(false);
      notifyListeners();
      return word;
    } catch (e) {
      _setError('فشل في إضافة الكلمة');
      _setLoading(false);
      debugPrint('Error adding word: $e');
      return null;
    }
  }

  /// Update word
  Future<bool> updateWord({
    required String wordId,
    String? text,
    String? textEn,
    String? categoryId,
    String? imageUrl,
    String? correctPronunciationUrl,
    String? description,
    String? phonetic,
    int? difficulty,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{};

      if (text != null) updates['text'] = text.trim();
      if (textEn != null) updates['textEn'] = textEn.trim();
      if (categoryId != null) updates['categoryId'] = categoryId;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (correctPronunciationUrl != null) {
        updates['correctPronunciationUrl'] = correctPronunciationUrl;
      }
      if (description != null) updates['description'] = description.trim();
      if (phonetic != null) updates['phonetic'] = phonetic.trim();
      if (difficulty != null) updates['difficulty'] = difficulty;

      await _firestore
          .collection(AppConstants.wordsCollection)
          .doc(wordId)
          .update(updates);

      // Update local list
      final index = _words.indexWhere((w) => w.id == wordId);
      if (index != -1) {
        _words[index] = _words[index].copyWith(
          text: text ?? _words[index].text,
          textEn: textEn ?? _words[index].textEn,
          categoryId: categoryId ?? _words[index].categoryId,
          imageUrl: imageUrl ?? _words[index].imageUrl,
          correctPronunciationUrl:
              correctPronunciationUrl ?? _words[index].correctPronunciationUrl,
          description: description ?? _words[index].description,
          phonetic: phonetic ?? _words[index].phonetic,
          difficulty: difficulty ?? _words[index].difficulty,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في تحديث الكلمة');
      _setLoading(false);
      debugPrint('Error updating word: $e');
      return false;
    }
  }

  /// Delete word
  Future<bool> deleteWord(String wordId) async {
    _setLoading(true);
    _clearError();

    try {
      final word = _words.firstWhere((w) => w.id == wordId);

      await _firestore
          .collection(AppConstants.wordsCollection)
          .doc(wordId)
          .update({'isActive': false});

      // Update category word count
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(word.categoryId)
          .update({'wordCount': FieldValue.increment(-1)});

      // Update local category
      final catIndex = _categories.indexWhere((c) => c.id == word.categoryId);
      if (catIndex != -1) {
        _categories[catIndex] = _categories[catIndex].copyWith(
          wordCount: _categories[catIndex].wordCount - 1,
        );
      }

      _words.removeWhere((w) => w.id == wordId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في حذف الكلمة');
      _setLoading(false);
      debugPrint('Error deleting word: $e');
      return false;
    }
  }

  /// Increment word practice count
  Future<void> incrementPracticeCount(String wordId) async {
    try {
      await _firestore
          .collection(AppConstants.wordsCollection)
          .doc(wordId)
          .update({'practiceCount': FieldValue.increment(1)});

      final index = _words.indexWhere((w) => w.id == wordId);
      if (index != -1) {
        _words[index] = _words[index].copyWith(
          practiceCount: _words[index].practiceCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing practice count: $e');
    }
  }

  /// Search words
  List<WordModel> searchWords(String query) {
    if (query.isEmpty) return _words;

    final lowerQuery = query.toLowerCase();
    return _words.where((word) {
      return word.text.toLowerCase().contains(lowerQuery) ||
          (word.textEn?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get words by category
  List<WordModel> getWordsByCategory(String categoryId) {
    return _words.where((w) => w.categoryId == categoryId).toList();
  }

  /// Get total words count
  int get totalWordsCount => _words.length;

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
    _categories = [];
    _words = [];
    _selectedCategory = null;
    _error = null;
    notifyListeners();
  }
}
