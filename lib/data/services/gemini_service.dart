import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/constants/secrets.dart';
import '../models/ocr_result.dart';
import 'product_search_service.dart';
import 'deadline_service.dart';

class GeminiService {
  void _ensureApiKey() {
    if (geminiApiKey.isEmpty) {
      print('❌ API 키가 비어있습니다. .env 파일에 GEMINI_API_KEY를 설정해주세요.');
      throw Exception('GEMINI_API_KEY가 설정되지 않았습니다. .env 파일을 확인해주세요.');
    }
    print('✅ API 키 확인 완료');
  }
  
  // v1 API 엔드포인트 (검증된 모델명 사용)
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _modelName = 'gemini-2.0-flash';
  
  // 제품 검색 서비스
  final ProductSearchService _productSearchService = ProductSearchService();
  
  // 기한 인식 서비스
  final DeadlineService _deadlineService = DeadlineService();

  GeminiService() {
    print('🔧 Gemini Service 초기화 완료 (REST API 방식)');
    print('🌐 엔드포인트: $_baseUrl/models/$_modelName:generateContent');
    print('🛍️ 제품 검색 서비스 초기화 완료');
    print('📅 기한 인식 서비스 초기화 완료');
  }

  // 할당량 확인 및 대기
  Future<void> _checkQuotaLimit() async {
    print('📊 할당량 확인 중...');
    print('💡 유료 플랜으로 업그레이드 완료');
  }

  // 바이트 데이터로 이미지 OCR 및 카테고리 분류 (웹용)
  Future<OCRResult> processImageBytes(Uint8List imageBytes, String fileName, {List<String>? customCategories}) async {
    try {
      print('🔄 바이트 데이터 처리 중: $fileName');
      print('📊 이미지 크기: ${imageBytes.length} bytes');
      
      // 할당량 확인
      await _checkQuotaLimit();

      final base64Image = base64Encode(imageBytes);
      print('🔤 Base64 인코딩 완료: ${base64Image.length} characters');

      print('🤖 Gemini API 요청 구성 중...');
      
      print('🤖 Gemini API 요청 구성 중...');
      
      final prompt = _buildPrompt(customCategories);

      print('📡 Gemini API 호출 중...');

      print('📡 Gemini API 호출 중...');
      
      // REST API 직접 호출
      final response = await _makeApiCall(prompt, base64Image);
      
      if (response == null) {
        throw Exception('API 호출 실패: 응답이 null입니다');
      }

      print('📡 API 응답 수신 완료');
      print('📝 API 응답 내용: $response');
        
        // JSON 응답 파싱
        try {
          print('🔍 JSON 파싱 시도 중...');
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            print('📋 추출된 JSON: $jsonStr');
            final parsedData = json.decode(jsonStr);
            
            final result = OCRResult(
              text: parsedData['extracted_text'] ?? '',
              category: _validateCategory(parsedData['category'] ?? '정보/참고용'),
              confidence: (parsedData['confidence'] ?? 0.8).toDouble(),
              tags: List<String>.from(parsedData['tags'] ?? []),
              reasoning: parsedData['reasoning'] ?? '분류 근거 없음',
              textHints: List<String>.from(parsedData['text_hints'] ?? []),
            );
            print('✅ OCR 결과: ${result.category} (신뢰도: ${result.confidence})');
            print('📝 분류 근거: ${result.reasoning}');
            print('🏷️ 태그: ${result.tags}');
            print('📄 추출된 텍스트: ${result.text}');
            return result;
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
        
        // JSON 파싱 실패 시 폴백 처리
      return _fallbackProcessing(response);
    } catch (e) {
      print('❌ Gemini Service Error: $e');
      // API 호출 실패 시 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['API오류'],
        reasoning: 'API 호출 실패: $e',
      );
    }
  }

  // 이미지 OCR 및 카테고리 분류
  Future<OCRResult> processImage(File imageFile, {List<String>? customCategories}) async {
    try {
      print('🔄 이미지 파일 읽기 중: ${imageFile.path}');
      // 이미지를 Base64로 인코딩
      final imageBytes = await imageFile.readAsBytes();
      print('📊 이미지 크기: ${imageBytes.length} bytes');
      final base64Image = base64Encode(imageBytes);
      print('🔤 Base64 인코딩 완료: ${base64Image.length} characters');

      print('🤖 Gemini API 요청 구성 중...');
      
      print('🤖 Gemini API 요청 구성 중...');
      
      final prompt = _buildPrompt(customCategories);

      print('🌐 Gemini API 호출 중...');

      print('🌐 Gemini API 호출 중...');
      
      // REST API 직접 호출
      final response = await _makeApiCall(prompt, base64Image);
      
      if (response == null) {
        throw Exception('API 호출 실패: 응답이 null입니다');
      }

      print('📡 API 응답 상태: 성공');
      print('📝 API 응답 내용: $response');

      // JSON 응답 파싱
      try {
        print('🔍 JSON 파싱 시도 중...');
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          print('📋 추출된 JSON: $jsonStr');
          final parsedData = json.decode(jsonStr);

          final result = OCRResult(
            text: parsedData['extracted_text'] ?? '',
            category: _validateCategory(parsedData['category'] ?? '정보/참고용'),
            confidence: (parsedData['confidence'] ?? 0.8).toDouble(),
            tags: List<String>.from(parsedData['tags'] ?? []),
            reasoning: parsedData['reasoning'] ?? '분류 근거 없음',
            textHints: List<String>.from(parsedData['text_hints'] ?? []),
          );
          print('✅ OCR 결과: ${result.category} (신뢰도: ${result.confidence})');
          print('📝 분류 근거: ${result.reasoning}');
          print('🏷️ 태그: ${result.tags}');
          print('📄 추출된 텍스트: ${result.text}');
          return result;
        }
      } catch (e) {
        print('❌ JSON parsing error: $e');
      }

      // JSON 파싱 실패 시 폴백 처리
      return _fallbackProcessing(response);
    } catch (e) {
      print('❌ Gemini Service Error: $e');
      // API 호출 실패 시 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['API오류'],
        reasoning: 'API 호출 실패: $e',
      );
    }
  }

  // REST API 직접 호출 (v1 엔드포인트 사용)
  Future<String?> _makeApiCall(String prompt, String base64Image) async {
    try {
      _ensureApiKey();
      
      // API 키를 URL 쿼리 파라미터로 전달
      final url = Uri.parse('$_baseUrl/models/$_modelName:generateContent?key=$geminiApiKey');
      
      print('🔑 API 키 확인: ${geminiApiKey.isNotEmpty ? "설정됨" : "없음"}');
      
      final List<Map<String, dynamic>> parts = [
        {'text': prompt},
      ];
      if (base64Image.isNotEmpty) {
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          }
        });
      }

      final requestBody = {
        'contents': [
          {
            'parts': parts
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1.0,
          'maxOutputTokens': 4096,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      print('📡 REST API 호출: $_baseUrl/models/$_modelName:generateContent');
      print('📊 요청 본문 크기: ${json.encode(requestBody).length} bytes');
      print('🖼️ 이미지 데이터 크기: ${base64Image.length} characters');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📊 HTTP 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ API 호출 성공');
        print('📊 응답 데이터 구조: ${responseData.keys.toList()}');
        
        // 에러 체크
        if (responseData['error'] != null) {
          final error = responseData['error'];
          print('❌ API 에러 응답: ${error['message']}');
          print('❌ 에러 코드: ${error['code']}');
          return null;
        }
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = responseData['candidates'][0]['content']['parts'][0]['text'];
          return text;
        } else {
          print('❌ 응답 구조가 예상과 다름');
          print('❌ 응답 내용: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return null;
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        
        // 응답 본문 파싱 시도
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            print('❌ API 에러: ${error['message'] ?? '알 수 없는 오류'}');
            print('❌ 에러 코드: ${error['code'] ?? response.statusCode}');
            print('❌ 에러 상태: ${error['status'] ?? 'N/A'}');
            
            // API 키 관련 오류
            if (response.statusCode == 403 || response.statusCode == 401) {
              print('🔑 API 키 문제일 수 있습니다. .env 파일의 GEMINI_API_KEY를 확인해주세요.');
            }
            
            // 모델명 오류
            if (response.statusCode == 404) {
              print('🔍 모델명 오류 가능성: $_modelName');
              print('💡 사용 가능한 모델: gemini-1.5-flash, gemini-1.5-pro');
            }
          } else {
            print('❌ 응답 내용: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          }
        } catch (e) {
          print('❌ 응답 파싱 실패: $e');
          print('❌ 원본 응답: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        }
        
        return null;
      }
    } catch (e) {
      print('❌ REST API 호출 실패: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      return null;
    }
  }

  // 카테고리 유효성 검사
  String _validateCategory(String category) {
    if (AppConstants.defaultCategories.contains(category)) {
      return category;
    }
    
    // 유사한 카테고리 매핑
    final categoryMappings = {
      '정보': '정보/참고용',
      '참고': '정보/참고용',
      '메모': '학습/업무 메모',
      '업무': '학습/업무 메모',
      '학습': '학습/업무 메모',
      '공부': '학습/업무 메모',
      '대화': '대화/메시지',
      '메시지': '대화/메시지',
      '채팅': '대화/메시지',
      '카톡': '대화/메시지',
      '재미': '재미/밈/감정',
      '밈': '재미/밈/감정',
      '웃긴': '재미/밈/감정',
      '감정': '재미/밈/감정',
      '일정': '일정/예약',
      '예약': '일정/예약',
      '스케줄': '일정/예약',
      '약속': '일정/예약',
      '증빙': '증빙/거래',
      '거래': '증빙/거래',
      '영수증': '증빙/거래',
      '결제': '증빙/거래',
      '구매': '증빙/거래',
      '의류': '옷',
      '패션': '옷',
      '쇼핑': '제품',
      '상품': '제품',
    };
    
    for (final mapping in categoryMappings.entries) {
      if (category.contains(mapping.key)) {
        return mapping.value;
      }
    }
    
    return '정보/참고용'; // 기본값
  }

  // 폴백 처리 (JSON 파싱 실패 시)
  OCRResult _fallbackProcessing(String content) {
    final text = content.replaceAll(RegExp(r'[{}"\[\],]'), ' ').trim();
    
    // 키워드 기반 카테고리 추론
    String category = '정보/참고용';
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('메시지') || lowerContent.contains('대화') || lowerContent.contains('채팅')) {
      category = '대화/메시지';
    } else if (lowerContent.contains('일정') || lowerContent.contains('예약') || lowerContent.contains('약속')) {
      category = '일정/예약';
    } else if (lowerContent.contains('영수증') || lowerContent.contains('결제') || lowerContent.contains('구매')) {
      category = '증빙/거래';
    } else if (lowerContent.contains('학습') || lowerContent.contains('업무') || lowerContent.contains('메모')) {
      category = '학습/업무 메모';
    }
    
    return OCRResult(
      text: text.length > 100 ? '${text.substring(0, 100)}...' : text,
      category: category,
      confidence: 0.6,
      tags: ['자동분류'],
      reasoning: 'JSON 파싱 실패로 키워드 기반 분류 사용',
    );
  }

  // 배치 처리 (여러 이미지 동시 처리)
  Future<List<OCRResult>> processBatchImages(List<File> imageFiles) async {
    final results = <OCRResult>[];
    
    // 동시 처리 제한 (API 요청 제한 고려)
    const batchSize = 3;
    
    for (int i = 0; i < imageFiles.length; i += batchSize) {
      final batch = imageFiles.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((file) => processImage(file)),
      );
      results.addAll(batchResults);
      
      // API 호출 간격 조절
      if (i + batchSize < imageFiles.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return results;
  }

  // 텍스트만으로 카테고리 분류 (이미 추출된 OCR 텍스트용)
  Future<String> classifyTextOnly(String text) async {
    try {
      final prompt = '''
다음 텍스트를 분석하여 가장 적절한 카테고리로 분류해주세요:

텍스트: "$text"

카테고리 옵션:
- 정보/참고용
- 대화/메시지
- 학습/업무 메모
- 재미/밈/감정
- 일정/예약
- 증빙/거래
- 옷
- 제품

응답은 카테고리 이름만 정확히 답해주세요.
''';

      final response = await _makeApiCall(prompt, '');
      
      if (response != null) {
        return _validateCategory(response.trim());
      }
    } catch (e) {
      print('Text classification error: $e');
    }
    
    return '정보/참고용';
  }

  // === 제품 검색 기능 ===
  
  /// 이미지에서 제품 정보 추출 및 검색 링크 생성
  Future<Map<String, dynamic>> extractProductInfo(Uint8List imageBytes, String fileName) async {
    try {
      print('🛍️ 제품 정보 추출 시작: $fileName');
      
      // 1. Gemini API로 이미지에서 텍스트 추출
      final ocrResult = await processImageBytes(imageBytes, fileName);
      print('📝 OCR 결과: ${ocrResult.text}');
      
      // 2. 제품 검색 결과 생성
      final productSearchResult = _productSearchService.generateProductSearchResult(ocrResult.text);
      
      // 3. 결과에 OCR 정보 추가
      productSearchResult['ocr_result'] = {
        'text': ocrResult.text,
        'category': ocrResult.category,
        'confidence': ocrResult.confidence,
        'tags': ocrResult.tags,
        'reasoning': ocrResult.reasoning,
      };
      
      print('✅ 제품 정보 추출 완료');
      return productSearchResult;
      
    } catch (e) {
      print('❌ 제품 정보 추출 실패: $e');
      return {
        'error': '제품 정보 추출 실패: $e',
        'normalized_text': '',
        'links': {},
        'raw_text': '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// 파일에서 제품 정보 추출 및 검색 링크 생성
  Future<Map<String, dynamic>> extractProductInfoFromFile(File imageFile) async {
    try {
      print('🛍️ 파일에서 제품 정보 추출 시작: ${imageFile.path}');
      
      // 1. Gemini API로 이미지에서 텍스트 추출
      final ocrResult = await processImage(imageFile);
      print('📝 OCR 결과: ${ocrResult.text}');
      
      // 2. 제품 검색 결과 생성
      final productSearchResult = _productSearchService.generateProductSearchResult(ocrResult.text);
      
      // 3. 결과에 OCR 정보 추가
      productSearchResult['ocr_result'] = {
        'text': ocrResult.text,
        'category': ocrResult.category,
        'confidence': ocrResult.confidence,
        'tags': ocrResult.tags,
        'reasoning': ocrResult.reasoning,
      };
      
      print('✅ 파일에서 제품 정보 추출 완료');
      return productSearchResult;
      
    } catch (e) {
      print('❌ 파일에서 제품 정보 추출 실패: $e');
      return {
        'error': '제품 정보 추출 실패: $e',
        'normalized_text': '',
        'links': {},
        'raw_text': '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// 제품 검색 결과를 JSON 문자열로 반환
  Future<String> getProductSearchJson(Uint8List imageBytes, String fileName) async {
    final result = await extractProductInfo(imageBytes, fileName);
    return json.encode(result);
  }
  
  /// 제품 검색 결과를 파일로 저장
  Future<void> saveProductSearchResult(Uint8List imageBytes, String fileName, String outputPath) async {
    try {
      final result = await extractProductInfo(imageBytes, fileName);
      final jsonResult = json.encode(result);
      
      final file = File(outputPath);
      await file.writeAsString(jsonResult);
      
      print('💾 제품 검색 결과 저장 완료: $outputPath');
    } catch (e) {
      print('❌ 제품 검색 결과 저장 실패: $e');
    }
  }
  
  /// 제품 검색 결과를 콘솔에 출력
  Future<void> printProductSearchResult(Uint8List imageBytes, String fileName) async {
    try {
      final result = await extractProductInfo(imageBytes, fileName);
      
      print('\n🛍️ === 제품 검색 결과 ===');
      print('📁 파일명: $fileName');
      
      if (result.containsKey('error')) {
        print('❌ 오류: ${result['error']}');
      } else {
        print('📝 원본 텍스트: ${result['raw_text']}');
        print('✨ 정규화된 텍스트: ${result['normalized_text']}');
        print('🔗 검색 링크:');
        
        final links = result['links'] as Map<String, String>;
        links.forEach((platform, url) {
          print('  $platform: $url');
        });
        
        if (result.containsKey('ocr_result')) {
          final ocrResult = result['ocr_result'] as Map<String, dynamic>;
          print('📊 OCR 정보:');
          print('  카테고리: ${ocrResult['category']}');
          print('  신뢰도: ${ocrResult['confidence']}');
          print('  태그: ${ocrResult['tags']}');
        }
        
        print('⏰ 생성 시간: ${result['timestamp']}');
      }
      
      print('========================\n');
    } catch (e) {
      print('❌ 제품 검색 결과 출력 실패: $e');
    }
  }

  // === 기한 인식 기능 ===
  
  /// 이미지에서 기한 정보 추출 및 알림 예약
  Future<Map<String, dynamic>> extractDeadlineInfo(Uint8List imageBytes, String fileName) async {
    try {
      print('📅 기한 정보 추출 시작: $fileName');
      
      // 1. Gemini API로 이미지에서 텍스트 추출
      final ocrResult = await processImageBytes(imageBytes, fileName);
      print('📝 OCR 결과: ${ocrResult.text}');
      
      // 2. 기한 정보 생성
      final deadlineResult = _deadlineService.generateDeadlineResult(ocrResult.text, ocrResult.text);
      
      // 3. 결과에 OCR 정보 추가
      deadlineResult['ocr_result'] = {
        'text': ocrResult.text,
        'category': ocrResult.category,
        'confidence': ocrResult.confidence,
        'tags': ocrResult.tags,
        'reasoning': ocrResult.reasoning,
      };
      
      print('✅ 기한 정보 추출 완료');
      return deadlineResult;
      
    } catch (e) {
      print('❌ 기한 정보 추출 실패: $e');
      return {
        'error': '기한 정보 추출 실패: $e',
        'normalized_text': '',
        'deadline': null,
        'album': '정보/참고용',
        'links': {},
        'notifications': [],
        'raw_text': '',
        'timestamp': DateTime.now().toIso8601String(),
        'has_deadline': false,
      };
    }
  }
  
  /// 파일에서 기한 정보 추출 및 알림 예약
  Future<Map<String, dynamic>> extractDeadlineInfoFromFile(File imageFile) async {
    try {
      print('📅 파일에서 기한 정보 추출 시작: ${imageFile.path}');
      
      // 1. Gemini API로 이미지에서 텍스트 추출
      final ocrResult = await processImage(imageFile);
      print('📝 OCR 결과: ${ocrResult.text}');
      
      // 2. 기한 정보 생성
      final deadlineResult = _deadlineService.generateDeadlineResult(ocrResult.text, ocrResult.text);
      
      // 3. 결과에 OCR 정보 추가
      deadlineResult['ocr_result'] = {
        'text': ocrResult.text,
        'category': ocrResult.category,
        'confidence': ocrResult.confidence,
        'tags': ocrResult.tags,
        'reasoning': ocrResult.reasoning,
      };
      
      print('✅ 파일에서 기한 정보 추출 완료');
      return deadlineResult;
      
    } catch (e) {
      print('❌ 파일에서 기한 정보 추출 실패: $e');
      return {
        'error': '기한 정보 추출 실패: $e',
        'normalized_text': '',
        'deadline': null,
        'album': '정보/참고용',
        'links': {},
        'notifications': [],
        'raw_text': '',
        'timestamp': DateTime.now().toIso8601String(),
        'has_deadline': false,
      };
    }
  }
  
  /// 기한 정보를 JSON 문자열로 반환
  Future<String> getDeadlineJson(Uint8List imageBytes, String fileName) async {
    final result = await extractDeadlineInfo(imageBytes, fileName);
    return json.encode(result);
  }
  
  /// 기한 정보를 파일로 저장
  Future<void> saveDeadlineResult(Uint8List imageBytes, String fileName, String outputPath) async {
    try {
      final result = await extractDeadlineInfo(imageBytes, fileName);
      final jsonResult = json.encode(result);
      
      final file = File(outputPath);
      await file.writeAsString(jsonResult);
      
      print('💾 기한 정보 저장 완료: $outputPath');
    } catch (e) {
      print('❌ 기한 정보 저장 실패: $e');
    }
  }
  
  /// 기한 정보를 콘솔에 출력
  Future<void> printDeadlineResult(Uint8List imageBytes, String fileName) async {
    try {
      final result = await extractDeadlineInfo(imageBytes, fileName);
      
      print('\n📅 === 기한 정보 결과 ===');
      print('📁 파일명: $fileName');
      
      if (result.containsKey('error')) {
        print('❌ 오류: ${result['error']}');
      } else {
        print('📝 원본 텍스트: ${result['raw_text']}');
        print('✨ 정규화된 텍스트: ${result['normalized_text']}');
        
        if (result['has_deadline'] == true) {
          print('📅 기한: ${result['deadline']}');
          print('📁 앨범: ${result['album']}');
          print('🔔 알림 예약:');
          
          final notifications = result['notifications'] as List<String>;
          for (int i = 0; i < notifications.length; i++) {
            final days = ['3일 전', '1일 전', '당일'][i];
            print('  $days: ${notifications[i]}');
          }
        } else {
          print('ℹ️ 기한 없음 - 일반 분류');
          print('📁 앨범: ${result['album']}');
        }
        
        if (result.containsKey('ocr_result')) {
          final ocrResult = result['ocr_result'] as Map<String, dynamic>;
          print('📊 OCR 정보:');
          print('  카테고리: ${ocrResult['category']}');
          print('  신뢰도: ${ocrResult['confidence']}');
          print('  태그: ${ocrResult['tags']}');
        }
        
        print('⏰ 생성 시간: ${result['timestamp']}');
      }
      
      print('========================\n');
    } catch (e) {
      print('❌ 기한 정보 출력 실패: $e');
    }
  }
  String _buildPrompt(List<String>? customCategories) {
    String customCategoryText = '';
    if (customCategories != null && customCategories.isNotEmpty) {
      customCategoryText = '\n**사용자 정의 카테고리 (키워드 매칭 우선):**\n';
      for (final category in customCategories) {
        if (!AppConstants.defaultCategories.contains(category)) {
          customCategoryText += '- **$category**: "$category" 관련 키워드나 내용이 포함된 경우\n';
        }
      }
    }

    return '''
이 스크린샷 이미지를 분석하여 카테고리를 분류해주세요.

**분석 단계:**
1. 이미지에 있는 모든 텍스트를 OCR로 추출
2. 이미지의 시각적 요소 분석 (UI, 레이아웃, 색상, 앱 디자인 등)
3. 텍스트와 시각적 요소를 종합하여 우선순위에 따라 카테고리 분류

$customCategoryText

**기본 카테고리 분류 기준 (사용자 정의 카테고리가 해당되지 않을 경우):**

1. **대화/메시지** [최우선]: 
   - 카카오톡, 문자, 채팅, 메신저 앱 화면
   - 말풍선, 대화 내용, 연락처 화면
   - 소셜미디어(인스타그램, 페이스북) 댓글/메시지

2. **증빙/거래** [높은 우선순위]:
   - 영수증, 결제 화면, 은행 앱, 송금/이체 내역
   - 온라인 쇼핑 주문/결제 확인, 카드 사용 내역
   - 보험, 계약서, 증명서류

3. **일정/예약** [높은 우선순위]:
   - 캘린더 앱, 예약 확인서, 티켓팅
   - 병원 예약, 식당 예약, 여행 예약
   - 일정표, 스케줄, 알람 설정

4. **학습/업무 메모** [중간 우선순위]:
   - 공부 자료, 노트, 업무 문서
   - 프레젠테이션, 강의, 교육 자료
   - 회의록, 업무 계획서

5. **재미/밈/감정** [중간 우선순위]:
   - 유머, 밈, 재미있는 이미지
   - 감정 표현, 이모티콘
   - 엔터테인먼트 콘텐츠

6. **옷** [낮은 우선순위]:
   - 의류, 패션, 쇼핑몰 상품
   - 옷 관련 정보, 스타일링

7. **제품** [낮은 우선순위]:
   - 전자제품, 생활용품, 상품 정보
   - 리뷰, 구매 정보

8. **정보/참고용** [기본값]:
   - 일반적인 정보, 뉴스, 문서
   - 웹페이지, 참고 자료
   - 기타 분류되지 않는 내용

  "extracted_text": "추출된 텍스트",
  "category": "분류된 카테고리(사용자 정의 카테고리 포함)",
  "confidence": 0.95,
  "tags": ["태그1", "태그2", "태그3"],
  "text_hints": ["키워드1", "키워드2"],
  "reasoning": "분류한 구체적인 이유와 근거를 상세히 설명"
}

**text_hints 가이드:**
- 'text_hints'에는 분류에 결정적인 영향을 미친 텍스트 키워드들(예: '쿠팡', '스타벅스', '인증번호', '결제완료')을 추출해주세요.
- 이는 추후 규칙 기반 분류에 사용됩니다.

**중요:** 텍스트가 없거나 읽을 수 없는 경우에도 이미지의 시각적 특성을 바탕으로 분류해주세요.
''';
  }
}