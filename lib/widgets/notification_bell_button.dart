import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notificationService = provider.notificationService;
    final unreadCount = notificationService.unreadCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Уведомления',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotificationsSheet(context),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();
    final service = provider.notificationService;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final items = service.notifications;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Шапка
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: AppColors.primaryIndigo),
                            const SizedBox(width: 8),
                            const Text(
                              'Уведомления',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (items.isNotEmpty) ...[
                              TextButton(
                                onPressed: () async {
                                  await service.markAllAsRead();
                                  setSheetState(() {});
                                },
                                child: const Text('Прочитать все', style: TextStyle(fontSize: 12)),
                              ),
                              IconButton(
                                tooltip: 'Очистить историю',
                                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                                onPressed: () async {
                                  await service.clearAll();
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Список уведомлений
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'У вас пока нет уведомлений',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final n = items[i];
                          return ListTile(
                            leading: _buildIconForType(n.type),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  n.message,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd.MM HH:mm').format(n.timestamp),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: !n.isRead
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryIndigo,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              await service.markAsRead(n.id);
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.quarterCompleted:
      case AppNotificationType.calendarScheduled:
      case AppNotificationType.success:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 14,
          child: Icon(Icons.check, size: 16, color: Colors.white),
        );
      case AppNotificationType.quarterProgress:
        return const CircleAvatar(
          backgroundColor: AppColors.primaryIndigo,
          radius: 14,
          child: Icon(Icons.autorenew, size: 16, color: Colors.white),
        );
      case AppNotificationType.error:
        return const CircleAvatar(
          backgroundColor: Colors.redAccent,
          radius: 14,
          child: Icon(Icons.error_outline, size: 16, color: Colors.white),
        );
      case AppNotificationType.warning:
        return const CircleAvatar(
          backgroundColor: Colors.amber,
          radius: 14,
          child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.blueGrey,
          radius: 14,
          child: Icon(Icons.info_outline, size: 16, color: Colors.white),
        );
    }
  }
}
