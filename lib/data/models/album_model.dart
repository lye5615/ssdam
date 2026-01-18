import 'package:equatable/equatable.dart';

class AlbumModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String iconPath;
  final String colorCode;
  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isDefault;
  final String userId;
  final String? exportAlbumId; // ID of the album in the device gallery for sync

  const AlbumModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconPath,
    required this.colorCode,
    this.photoCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDefault = false,

    required this.userId,
    this.exportAlbumId,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconPath: json['iconPath'] as String,
      colorCode: json['colorCode'] as String,
      photoCount: json['photoCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      userId: json['userId'] as String,
      exportAlbumId: json['exportAlbumId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'colorCode': colorCode,
      'photoCount': photoCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isDefault': isDefault,
      'userId': userId,
      'exportAlbumId': exportAlbumId,
    };
  }

  AlbumModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    String? colorCode,
    int? photoCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDefault,
    String? userId,
    String? exportAlbumId,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      colorCode: colorCode ?? this.colorCode,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      exportAlbumId: exportAlbumId ?? this.exportAlbumId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconPath,
        colorCode,
        photoCount,
        createdAt,
        updatedAt,
        isPinned,
        isDefault,

        userId,
        exportAlbumId,
      ];
}
