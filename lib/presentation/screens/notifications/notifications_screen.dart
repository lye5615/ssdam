import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/models/photo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/photo_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.uid;

    // Trigger photo reload if needed to ensure assets are available
    // context.read<PhotoProvider>().initialize(userId!); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: userId == null
          ? const Center(child: Text('로그인이 필요합니다'))
          : StreamBuilder<List<ReminderModel>>(
              stream: ServiceLocator.firestoreService.getUserRemindersStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                final reminders = snapshot.data ?? [];
                if (reminders.isEmpty) {
                  return const _EmptyView();
                }
                // 날짜순 정렬 (빠른 기한 순)
                reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final tomorrowStart = todayStart.add(const Duration(days: 1));

                final pastReminders = <ReminderModel>[];
                final todayReminders = <ReminderModel>[];
                final upcomingReminders = <ReminderModel>[];

                for (final r in reminders) {
                  if (r.reminderDate.isBefore(todayStart)) {
                    pastReminders.add(r);
                  } else if (r.reminderDate.isBefore(tomorrowStart)) {
                    todayReminders.add(r);
                  } else {
                    upcomingReminders.add(r);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (todayReminders.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          '오늘의 알림',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...todayReminders.map((r) => _ReminderTile(reminder: r)),
                      const SizedBox(height: 16),
                    ],

                    if (upcomingReminders.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          '다가오는 알림',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ...upcomingReminders.map((r) => _ReminderTile(reminder: r)),
                      const SizedBox(height: 16),
                    ],

                    if (pastReminders.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          '지난 알림',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      ...pastReminders.map((r) => Opacity(
                        opacity: 0.6,
                        child: _ReminderTile(reminder: r),
                      )),
                    ],
                  ],
                );
              },
            ),
    );
  }
}



class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    // ... existing Asset Logic ...
    return Consumer2<PhotoProvider, AuthProvider>(builder: (context, photoProvider, authProvider, child) {
      final photoId = reminder.photoId; 
      
      final photo = photoProvider.photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.id == photoId,
        orElse: () => null,
      );
      
      final assetId = photo?.assetEntityId;
      
      final asset = (assetId != null && assetId.isNotEmpty) 
          ? photoProvider.findAssetById(assetId) 
          : null;

      return Dismissible(
        key: Key('reminder_${reminder.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) async {
           await ServiceLocator.firestoreService.deleteReminder(reminder.id);
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('알림이 삭제되었습니다')),
             );
           }
        },
        child: ListTile(
          onTap: () => _showEditReminderDialog(context, reminder), // Add onTap
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: asset != null 
                ? FutureBuilder<Uint8List?>(
                    future: asset.thumbnailData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Container(color: AppColors.surfaceVariant);
                    },
                  )
                : Container(
                    color: AppColors.surfaceVariant,
                    child: Center(
                      child: Text(
                        reminder.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
            ),
          ),
          title: Text(
            (reminder.description?.isNotEmpty ?? false) ? reminder.description! : reminder.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(reminder.reminderDate),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          isThreeLine: true,
          trailing: Icon(
            reminder.isCompleted ? Icons.check_circle : Icons.alarm,
            color: reminder.isCompleted ? AppColors.success : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showEditReminderDialog(BuildContext context, ReminderModel reminder) {
    DateTime selectedDate = reminder.reminderDate;
    final memoController = TextEditingController(text: reminder.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(
            children: [
              const Text(
               '알림 수정',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Date & Time Selectors (Hybrid)
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Column(
                      children: [
                        // Date Selection (Calendar)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month),
                          title: const Text('날짜'),
                          subtitle: Text(
                            "${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow editing past reminders? Assuming yes or strict future? Let's allow flexible.
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setInnerState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  selectedDate.hour,
                                  selectedDate.minute,
                                );
                              });
                            }
                          },
                        ),
                        // Time Selection (Dial)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: const Text('시간'),
                          subtitle: Text(
                            "${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SizedBox(
                                height: 250,
                                child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                    brightness: Theme.of(context).brightness, // Adaptive brightness
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.time,
                                    initialDateTime: selectedDate,
                                    use24hFormat: true,
                                    onDateTimeChanged: (val) {
                                       setInnerState(() {
                                         selectedDate = DateTime(
                                           selectedDate.year,
                                           selectedDate.month,
                                           selectedDate.day,
                                           val.hour,
                                           val.minute,
                                         );
                                       });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                ),
              ),

              const SizedBox(height: 20),
              
              // Memo Field
              TextField(
                controller: memoController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 20),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final updatedReminder = reminder.copyWith(
                        description: memoController.text,
                        reminderDate: selectedDate,
                        updatedAt: DateTime.now(),
                      );
                      
                      await ServiceLocator.firestoreService.updateReminder(updatedReminder);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('알림이 수정되었습니다'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('수정 실패: $e')),
                        );
                      }
                    }
                  },
                  child: Text('수정 완료', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '스크린샷에 알림을 설정하면 여기에 표시됩니다',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
