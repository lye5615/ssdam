import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? fcmToken;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.fcmToken,
    this.preferences = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      fcmToken: json['fcmToken'] as String?,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'fcmToken': fcmToken,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? fcmToken,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      fcmToken: fcmToken ?? this.fcmToken,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        createdAt,
        lastLoginAt,
        fcmToken,
        preferences,
      ];
}
