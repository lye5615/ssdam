import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';

class IntroPermissionDialog extends StatelessWidget {
  const IntroPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.photo_library,
            color: AppColors.primary,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            '사진 접근 권한 안내',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '원활한 앱 사용을 위해 다음 권한을 허용해주세요:',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          _PermissionItem(
            icon: Icons.photo_library,
            title: '갤러리 접근',
            description: '내 사진을 불러와서 자동으로 스마트하게 분류합니다 (필수)',
          ),
          SizedBox(height: 12),
          _PermissionItem(
            icon: Icons.notifications,
            title: '알림',
            description: '설정한 기한 리마인더 알림을 보내드립니다 (선택)',
          ),
          SizedBox(height: 12),
          _PermissionItem(
            icon: Icons.cloud_sync,
            title: '클라우드 동기화 (개인정보보호)',
            description: '추출된 텍스트와 분류 정보는 안전하게 암호화되어 클라우드에 백업됩니다. (원본 사진은 서버에 절대 저장되지 않습니다)',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text(
            '나중에',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('권한 허용하기'),
        ),
      ],
    );
  }
}

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.photo_library,
            color: AppColors.primary,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            '권한 필요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '김치찜이 정상적으로 작동하려면 다음 권한이 필요합니다:',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          _PermissionItem(
            icon: Icons.photo_library,
            title: '갤러리 접근',
            description: '스크린샷을 자동으로 찾아 분류합니다',
          ),
          SizedBox(height: 12),
          _PermissionItem(
            icon: Icons.notifications,
            title: '알림',
            description: '중요한 스크린샷 알림을 보내드립니다',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            '나중에',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('설정 열기'),
        ),
      ],
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
