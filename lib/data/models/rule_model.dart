import 'package:equatable/equatable.dart';

enum RuleType {
  keyword,
  domain,
  sender,
  layout, // e.g. "receipt-like"
  label,  // AI label
  regex,
  manualMapping // Direct user mapping history
}

enum RuleSource {
  userConfirmed, // Explicitly created by user
  autoDerived    // Infered from user actions
}

class RuleModel extends Equatable {
  final String id;
  final RuleType type;
  final String pattern; // "coupang", "kakao", specific sender ID
  final String categoryId; // The target album ID (or name for now, linking to Category)
  final String categoryName; // Denormalized name for easier display
  final double weight; // Priority (1.0 = standard, 2.0 = high, 0.5 = weak hint)
  final RuleSource source;
  final DateTime createdAt;
  final String userId;

  const RuleModel({
    required this.id,
    required this.type,
    required this.pattern,
    required this.categoryId,
    required this.categoryName,
    this.weight = 1.0,
    required this.source,
    required this.createdAt,
    required this.userId,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: json['id'] as String,
      type: RuleType.values.byName(json['type'] as String),
      pattern: json['pattern'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      source: RuleSource.values.byName(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'pattern': pattern,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'weight': weight,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  @override
  List<Object?> get props => [id, type, pattern, categoryId, weight, source, userId];
}
