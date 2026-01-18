import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/photo_provider.dart';
import '../../providers/album_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'classification_review_screen.dart';
import '../home/home_screen.dart'; // Assuming home screen exists

class ClassificationSummaryScreen extends StatelessWidget {
  const ClassificationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final albumProvider = Provider.of<AlbumProvider>(context);
    
    // Group photos by category for statistics
    final photos = photoProvider.photos;
    final Map<String, int> stats = {};
    
    // Initialize defaults
    for (var cat in AppConstants.defaultCategories) {
      stats[cat] = 0;
    }
    
    // Count real data
    for (var photo in photos) {
      final cat = photo.category.isEmpty ? '정보/참고용' : photo.category;
      stats[cat] = (stats[cat] ?? 0) + 1;
    }

    return Dialog(
      backgroundColor: Colors.transparent, // Transparent to show overlay effect if needed
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           color: const Color(0xFFEFEFEF), // Light grey background like in sketch base
           borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '분류 결과',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            
            // Main Card (Grey box with stats)
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFA0A0A0), // Dark grey inner card
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...stats.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: itemRow(e.key, e.value),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      TextButton(
                        onPressed: () {
                           // For Modify, we likely want to push a full screen OR show another dialog.
                           // Given the complexity of modification (images), a full screen on top is okay,
                           // or we can dismiss this dialog and open the review screen, then show this dialog again on return.
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ClassificationReviewScreen(initialPhotos: photos),
                            ),
                          ).then((_) {
                             // Re-show dialog or setState if this was stateful?
                             // Since it's a Dialog, it might be safer to rebuild or pop/push.
                             // Actually, since build() reads provider, if we stay here, we just need to trigger rebuild.
                             // But since it's a Dialog and we pushed a route on top, when we return, this dialog is still there.
                             // Does Provider update reflect immediately?
                             // Yes, but only if the Dialog is listening. It is listening via build context.
                             // So returning should auto-update the stats if NotifyListeners called.
                          });
                        },
                        child: const Text(
                          '수정하기',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Confirm Button (can be outside or inside, user sketch shows it floating or at bottom)
            // Let's put it at the bottom as per code structure but styled well.
            const SizedBox(height: 24),
            SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      '확인 (완료)',
                      style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.normal),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget itemRow(String category, int count) {
    return Text(
      '= $category ${count}Photos',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white, // White text on dark grey Card
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
