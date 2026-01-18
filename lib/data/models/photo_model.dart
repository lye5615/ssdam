import 'package:equatable/equatable.dart';

enum PhotoSource {
  galleryAsset,
  appFile,
}

class PhotoModel extends Equatable {
  final String id;
  final String localPath;
  final String fileName;
  final String? thumbnailPath;
  final DateTime captureDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String albumId;
  final String category;
  final bool isFavorite;
  final bool hasReminder;
  final String? ocrText;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  final String? assetEntityId; // AssetEntity ID for gallery change detection
  
  // Smart Classification Fields
  final PhotoSource source;
  final List<String>? textHints; // Keywords found via OCR relevant for rules
  final String? classificationReason; // "Matched Rule: 'coupang' (Keyword)"

  const PhotoModel({
    required this.id,
    required this.localPath,
    required this.fileName,
    this.thumbnailPath,
    required this.captureDate,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.albumId,
    required this.category,
    this.isFavorite = false,
    this.hasReminder = false,
    this.ocrText,
    this.metadata = const {},
    this.tags = const [],
    this.assetEntityId,
    this.source = PhotoSource.galleryAsset, // Default for backward compatibility
    this.textHints,
    this.classificationReason,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      fileName: json['fileName'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      captureDate: DateTime.parse(json['captureDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String,
      albumId: json['albumId'] as String,
      category: json['category'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      hasReminder: json['hasReminder'] as bool? ?? false,
      ocrText: json['ocrText'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),

      assetEntityId: json['assetEntityId'] as String?,
      source: json['source'] != null 
          ? PhotoSource.values.byName(json['source'] as String)
          : PhotoSource.galleryAsset,
      textHints: (json['textHints'] as List<dynamic>?)?.map((e) => e as String).toList(),
      classificationReason: json['classificationReason'] as String?,
    );
  }

  factory PhotoModel.empty() {
    final now = DateTime.now();
    return PhotoModel(
      id: '',
      localPath: '',
      fileName: '',
      captureDate: now,
      createdAt: now,
      updatedAt: now,
      userId: '',
      albumId: '',
      category: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'fileName': fileName,
      'thumbnailPath': thumbnailPath,
      'captureDate': captureDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'albumId': albumId,
      'category': category,
      'isFavorite': isFavorite,
      'hasReminder': hasReminder,
      'ocrText': ocrText,
      'metadata': metadata,
      'tags': tags,
      'assetEntityId': assetEntityId,
      'source': source.name,
      'textHints': textHints,
      'classificationReason': classificationReason,
    };
  }

  PhotoModel copyWith({
    String? id,
    String? localPath,
    String? fileName,
    String? thumbnailPath,
    DateTime? captureDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? albumId,
    String? category,
    bool? isFavorite,
    bool? hasReminder,
    String? ocrText,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    String? assetEntityId,
    PhotoSource? source,
    List<String>? textHints,
    String? classificationReason,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      captureDate: captureDate ?? this.captureDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      albumId: albumId ?? this.albumId,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      hasReminder: hasReminder ?? this.hasReminder,
      ocrText: ocrText ?? this.ocrText,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      assetEntityId: assetEntityId ?? this.assetEntityId,
      source: source ?? this.source,
      textHints: textHints ?? this.textHints,
      classificationReason: classificationReason ?? this.classificationReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        localPath,
        fileName,
        thumbnailPath,
        captureDate,
        createdAt,
        updatedAt,
        userId,
        albumId,
        category,
        isFavorite,
        hasReminder,
        ocrText,
        metadata,
        tags,
        assetEntityId,
        source,
        textHints,
        classificationReason,
      ];
}
