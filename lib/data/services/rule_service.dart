import '../models/photo_model.dart';
import '../models/rule_model.dart';
import '../../core/constants/app_constants.dart';
import '../services/interfaces/i_firestore_service.dart';
import '../../core/di/service_locator.dart';

class RuleService {
  IFirestoreService? _firestoreService;
  
  // Inject dependency or use ServiceLocator
  IFirestoreService get firestoreService => _firestoreService ?? ServiceLocator.firestoreService;

  // --- Classification Logic ---

  /// Main entry point: Classify a photo based on its OCR text, metadata, and available rules.
  /// Returns the ID of the best matching category (Album ID), or null if no rule matches.
  Future<String?> classify(PhotoModel photo, List<RuleModel> rules) async {
    if (rules.isEmpty) return null;

    // Sort rules by weight (descending)
    final sortedRules = List<RuleModel>.from(rules)..sort((a, b) => b.weight.compareTo(a.weight));

    for (final rule in sortedRules) {
      if (_isMatch(photo, rule)) {
        return rule.categoryId;
      }
    }
    
    return null;
  }

  /// Check if a single rule matches the photo.
  bool _isMatch(PhotoModel photo, RuleModel rule) {
    if (rule.pattern.isEmpty) return false;

    final ocrText = photo.ocrText?.toLowerCase() ?? '';
    final pattern = rule.pattern.toLowerCase();

    switch (rule.type) {
      case RuleType.keyword:
        return ocrText.contains(pattern);
      
      case RuleType.regex:
        try {
          final regExp = RegExp(rule.pattern, caseSensitive: false);
          return regExp.hasMatch(ocrText);
        } catch (e) {
          // Fallback if regex is invalid
          return false;
        }

      case RuleType.domain:
        // Assuming metadata might contain URL or app package name
        // This is a placeholder for wherever 'source' url is stored
        final sourceInfo = photo.metadata['source_url']?.toString().toLowerCase() ?? '';
        return sourceInfo.contains(pattern);

      case RuleType.sender:
        // Assuming metadata might contain sender info for chats
        final sender = photo.metadata['sender']?.toString().toLowerCase() ?? '';
        return sender.contains(pattern);

      case RuleType.label:
        // Check AI tags
        return photo.tags.any((tag) => tag.toLowerCase() == pattern);
        
      default:
        return false;
    }
  }

  // --- Rule Generation Logic ---

  /// Generate a new rule based on user's manual classification.
  /// e.g., if user moves a "Coupang" receipt to "Shopping", suggest a keyword rule.
  RuleModel? deriveRule({
    required PhotoModel photo,
    required String targetCategoryId,
    required String targetCategoryName,
    required String userId,
  }) {
    // 1. Keyword Extraction Strategy
    // Find most significant word? For now, we use a simplistic approach:
    // If it's a known specialized app (e.g. Coupang), use that.
    
    final ocrText = photo.ocrText?.toLowerCase() ?? '';
    
    // Simple Heuristic: Check for common identifiers in OCR
    // This part effectively needs a "keyword extractor" or just exact word matching.
    // For this MVP, we won't auto-guess complex regex. We can check for simple "contains".
    
    // Example: Map of known keywords to check against
    final commonKeywords = {
      'coupang': 'coupang',
      'kurly': 'kurly',
      'baemin': 'baemin',
      'toss': 'toss',
      'kakao': 'kakao',
      'naver': 'naver',
      'starbucks': 'starbucks',
    };

    for (var key in commonKeywords.keys) {
      if (ocrText.contains(key)) {
        return RuleModel(
          id: '', // Will be assigned by Firestore
          type: RuleType.keyword,
          pattern: key,
          categoryId: targetCategoryId,
          categoryName: targetCategoryName,
          source: RuleSource.autoDerived,
          createdAt: DateTime.now(),
          weight: 1.0,
          userId: userId,
        );
      }
    }
    
    return null; // Could not derive a safe rule
  }

  // --- CRUD Operations (Delegated to FirestoreService) ---
  
  Future<void> saveRule(RuleModel rule, String userId) async {
     // TODO: Implement createRule in IFirestoreService
     // await firestoreService.createRule(userId, rule);
     print('RuleService: Would save rule ${rule.pattern} -> ${rule.categoryName}');
  }
}
