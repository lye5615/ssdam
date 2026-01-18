import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/photo_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'classification_summary_screen.dart';

class InitialScanScreen extends StatefulWidget {
  const InitialScanScreen({super.key});

  @override
  State<InitialScanScreen> createState() => _InitialScanScreenState();
}

class _InitialScanScreenState extends State<InitialScanScreen> {
  bool _isScanning = false;

  void _startScan() async {
    setState(() => _isScanning = true);

    // ... inside _startScan
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid ?? 'mock_user_123';
    
    // Trigger scanning and processing
    await photoProvider.processNewScreenshots(userId);
    
    // Refresh the provider list to ensure UI updates
    await photoProvider.loadUserPhotos(userId);

    if (mounted) {
      setState(() => _isScanning = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ClassificationSummaryScreen(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              '첫 스캔을 시작해보세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '갤러리의 스크린샷을 불러와\n자동으로 정리해드립니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            _isScanning
                ? const CircularProgressIndicator(color: AppColors.primary)
                : ElevatedButton(
                    onPressed: _startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Dark button as per aesthetic
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      '새로고침 (스캔 시작)',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
