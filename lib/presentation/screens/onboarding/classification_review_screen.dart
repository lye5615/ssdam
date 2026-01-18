import 'package:flutter/material.dart';
import '../../providers/photo_provider.dart';
import '../../../data/models/photo_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../data/services/rule_service.dart';
import '../../../core/di/service_locator.dart';

class ClassificationReviewScreen extends StatefulWidget {
  final List<PhotoModel> initialPhotos; // Photos to review

  const ClassificationReviewScreen({super.key, required this.initialPhotos});

  @override
  State<ClassificationReviewScreen> createState() => _ClassificationReviewScreenState();
}

class _ClassificationReviewScreenState extends State<ClassificationReviewScreen> {
  // Map of Category -> List of Photos
  late Map<String, List<PhotoModel>> _categorizedPhotos;
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialSort();
  }

  void _initialSort() {
    _categorizedPhotos = {};
    for (var photo in widget.initialPhotos) {
      final category = photo.category.isEmpty ? 'Uncategorized' : photo.category;
      _categorizedPhotos.putIfAbsent(category, () => []).add(photo);
    }
  }

  void _addCategory() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newCat = controller.text.trim();
              if (newCat.isNotEmpty && !_categorizedPhotos.containsKey(newCat)) {
                setState(() {
                  _categorizedPhotos[newCat] = [];
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    if (_categorizedPhotos[category]?.isEmpty ?? true) {
      setState(() {
        _categorizedPhotos.remove(category);
      });
      return;
    }

    // Ask where to move photos
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$category"?'),
        content: const Text('Photos in this category will be moved to "Uncategorized".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                final photos = _categorizedPhotos[category]!;
                _categorizedPhotos.putIfAbsent('Uncategorized', () => []).addAll(photos);
                _categorizedPhotos.remove(category);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _movePhoto(PhotoModel photo, String oldCategory, String newCategory) {
    setState(() {
      _categorizedPhotos[oldCategory]?.remove(photo);
      _categorizedPhotos[newCategory]?.add(photo.copyWith(category: newCategory));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories to keep UI stable
    final categories = _categorizedPhotos.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('카테고리 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: _addCategory,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategorySection(category);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveChanges,
        backgroundColor: Colors.black,
        label: const Text('저장 완료', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final photos = _categorizedPhotos[category]!;
    
    return Card(
      key: ValueKey(category),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              category, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}', 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteCategory(category),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          // Using DragTarget for future D&D, currently just Grid with LongPress
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _buildPhotoItem(photo, category);
            },
          ),
          if (photos.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('비어있음', style: TextStyle(color: Colors.grey)),
             ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo, String currentCategory) {
    return GestureDetector(
      onLongPress: () => _showMoveDialog(photo, currentCategory),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
          // image: photo.thumbnailPath if available...
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.image, color: Colors.white54)),
            // If local path exists, try to show it (mock logic for now for brevity)
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(PhotoModel photo, String currentCategory) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Photo'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _categorizedPhotos.keys
                  .where((c) => c != currentCategory)
                  .map((category) => ListTile(
                        title: Text(category),
                        onTap: () {
                          _movePhoto(photo, currentCategory, category);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }



  Future<void> _saveChanges() async {
    setState(() => _isProcessing = true);
    
    if (mounted) {
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      final userId = photoProvider.photos.isNotEmpty ? photoProvider.photos.first.userId : 'mock_user_123';
      final ruleService = ServiceLocator.ruleService;

      try {
        // Iterate over categorized photos to find changes
        final allCurrentPhotos = _categorizedPhotos.values.expand((element) => element).toList();
        
        for (var photo in allCurrentPhotos) {
            // Check if category changed
            final original = widget.initialPhotos.firstWhere((p) => p.id == photo.id, orElse: () => PhotoModel.empty());
            
            if (original.id.isNotEmpty && original.category != photo.category) {
                 // 1. Move Photo to new Album
                 await photoProvider.movePhotoToAlbum(photo.id, '', newCategoryName: photo.category);
                 
                 // 2. Smart Learning: Derive a rule for future auto-classification
                 final newRule = ruleService.deriveRule(
                    photo: photo, 
                    targetCategoryId: '', // Will be resolved by Service if empty, or we use name
                    targetCategoryName: photo.category,
                    userId: userId,
                 );
                 
                 if (newRule != null) {
                    await ruleService.saveRule(newRule, userId);
                    print('✨ New Rule derived: "${newRule.pattern}" -> ${newRule.categoryName}');
                 }
            }
        }
        
      } catch (e) {
        print('Error saving changes: $e');
      }
      
      Navigator.pop(context); 
    }
  }
}
