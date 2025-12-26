import '../models/user_model.dart';

/// Permission levels for app features
class Permissions {
  /// Check if user can add children (Admin only)
  static bool canAddChildren(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can delete children (Admin only)
  static bool canDeleteChildren(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can add trainers (Admin only)
  static bool canManageUsers(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can assign children to trainers (Admin only)
  static bool canAssignChildren(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can add categories (Admin & Trainer)
  static bool canAddCategories(UserModel? user) {
    return user?.isAdmin ?? false || user?.isTrainer ?? false;
  }

  /// Check if user can delete categories (Admin only)
  static bool canDeleteCategories(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can add words (Admin & Trainer)
  static bool canAddWords(UserModel? user) {
    return user?.isAdmin ?? false || user?.isTrainer ?? false;
  }

  /// Check if user can delete words (Admin & Trainer)
  static bool canDeleteWords(UserModel? user) {
    return user?.isAdmin ?? false || user?.isTrainer ?? false;
  }

  /// Check if user can generate reports (Admin & Trainer)
  static bool canGenerateReports(UserModel? user) {
    return user?.isAdmin ?? false || user?.isTrainer ?? false;
  }

  /// Check if user can view all children (Admin only)
  static bool canViewAllChildren(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user can view assigned children (Trainer)
  static bool canViewAssignedChildren(UserModel? user) {
    return user?.isTrainer ?? false;
  }

  /// Check if user is Parent (can only view own children)
  static bool isParentOnly(UserModel? user) {
    return user?.isParent ?? false;
  }

  /// Get role display name in Arabic
  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'مسؤول';
      case 'trainer':
        return 'مدرب';
      case 'parent':
        return 'ولي أمر';
      default:
        return role;
    }
  }

  /// Get role color
  static int getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return 0xFFE91E63; // Pink
      case 'trainer':
        return 0xFF2196F3; // Blue
      case 'parent':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
