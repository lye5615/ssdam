import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/album_model.dart';
import '../../providers/album_provider.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
      ),
      body: Consumer<AlbumProvider>(
        builder: (context, albumProvider, child) {
          if (albumProvider.albums.isEmpty) {
             return const Center(child: Text('카테고리가 없습니다.'));
          }

          return ListView.builder(
            itemCount: albumProvider.albums.length,
            itemBuilder: (context, index) {
              final album = albumProvider.albums[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(album.colorCode).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: album.iconPath != null && album.iconPath!.length <= 2 
                        ? Text(album.iconPath!, style: const TextStyle(fontSize: 20))
                        : Icon(Icons.folder, color: _parseColor(album.colorCode)),
                  ),
                ),
                title: Text(album.name),
                subtitle: Text('${album.photoCount ?? 0}장'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                      onPressed: () => _showRenameDialog(context, album),
                    ),
                    if (!album.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _showDeleteDialog(context, album),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AlbumModel album) {
    final TextEditingController controller = TextEditingController(text: album.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 수정'),
        content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                 TextField(
                   controller: controller,
                   decoration: const InputDecoration(labelText: '카테고리 이름'),
                   autofocus: true,
                 ),
                 const SizedBox(height: 16),
                 Row(
                    children: [
                        const Text('색상: '),
                        const SizedBox(width: 8),
                         GestureDetector(
                            onTap: () {
                                Navigator.pop(context); // Close rename
                                _showColorPickerDialog(context, album);
                            },
                             child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                    color: _parseColor(album.colorCode),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                ),
                             ),
                        ),
                    ]
                 )
             ]
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != album.name) {
                final success = await Provider.of<AlbumProvider>(context, listen: false)
                    .renameAlbum(album.id, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('수정되었습니다.')),
                     );
                  }
                }
              } else {
                   Navigator.pop(context); // No change
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AlbumModel album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('${album.name} 카테고리를 삭제하시겠습니까?\n포함된 사진도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AlbumProvider>(context, listen: false).deleteAlbum(album.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, AlbumModel album) {
      final List<String> colors = [
          '#FF0000', '#FF7F00', '#FFFF00', '#00FF00', '#0000FF', '#4B0082', '#9400D3',
          '#000000', '#FFFFFF', '#808080', '#FFC0CB', '#008080', '#A52A2A',
      ];
      
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('색상 선택'),
              content: Wrap(
                  spacing: 10, runSpacing: 10,
                  children: colors.map((c) => GestureDetector(
                      onTap: () async {
                           await Provider.of<AlbumProvider>(context, listen: false)
                              .changeAlbumColor(album.id, c);
                           if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: _parseColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                          ),
                      ),
                  )).toList(),
              ),
          ),
      );
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null) return Colors.grey;
    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
