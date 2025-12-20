import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model - Represents trainers and parents
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'trainer', 'parent', 'admin'
  final String? phone;
  final String? profileImageUrl;
  final List<String> assignedChildrenIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.assignedChildrenIds = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.settings,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'trainer',
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      assignedChildrenIds: List<String>.from(data['assignedChildrenIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      settings: data['settings'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'assignedChildrenIds': assignedChildrenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'settings': settings,
    };
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? profileImageUrl,
    List<String>? assignedChildrenIds,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      assignedChildrenIds: assignedChildrenIds ?? this.assignedChildrenIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  /// Check if user is trainer
  bool get isTrainer => role == 'trainer';

  /// Check if user is parent
  bool get isParent => role == 'parent';

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }
}
