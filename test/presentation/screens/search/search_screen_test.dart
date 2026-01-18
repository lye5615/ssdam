import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kimchi_jjim/presentation/screens/search/search_screen.dart';
import 'package:kimchi_jjim/presentation/providers/auth_provider.dart' as app_auth;
import 'package:kimchi_jjim/presentation/providers/photo_provider.dart';
import 'package:kimchi_jjim/data/models/photo_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kimchi_jjim/core/di/service_locator.dart';
import 'package:kimchi_jjim/data/models/user_model.dart';

// Simple Mock classes
class MockAuthProvider extends app_auth.AuthProvider {
  @override
  UserModel? get currentUser => UserModel(
    uid: 'test_uid',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
  ); 
  
  @override
  bool get isAuthenticated => true; 
}

class MockPhotoProvider extends PhotoProvider {
  List<PhotoModel> mockSearchResults = [];

  @override
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    // Mock implementation for UI test
    // In real app: filters by ocrText, tags, category (excludes fileName)
    return mockSearchResults;
  }
}

void main() {
  setUpAll(() {
     ServiceLocator.init(useMock: true);
  });

  testWidgets('SearchScreen UI Test', (WidgetTester tester) async {
    final mockPhotoProvider = MockPhotoProvider();
    final mockAuthProvider = MockAuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<PhotoProvider>.value(value: mockPhotoProvider),
        ],
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('키워드 검색 (텍스트, 태그 등)'), findsOneWidget);
    expect(find.text('검색어를 입력하세요'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNWidgets(2)); // AppBar icon + Body icon

    // Enter text
    await tester.enterText(find.byType(TextField), 'test');
    await tester.impliedIconTap(find.widgetWithIcon(IconButton, Icons.search)); // AppBar action
    
    await tester.pumpAndSettle();

    // Debugging output if fails
    if (find.text('검색 결과가 없습니다').evaluate().isEmpty) {
      debugPrint('State check:');
      debugPrint('Is "검색어를 입력하세요" visible? ${find.text('검색어를 입력하세요').evaluate().isNotEmpty}');
      debugPrint('Is "검색 중" visible? ${find.byType(CircularProgressIndicator).evaluate().isNotEmpty}');
    }

    // Verify loading or empty result (since mock returns empty list by default)
    expect(find.text('검색 결과가 없습니다'), findsOneWidget);
  });
}

// Extension to help tapping icons which might be in actions
extension TesterExtensions on WidgetTester {
  Future<void> impliedIconTap(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }
}
