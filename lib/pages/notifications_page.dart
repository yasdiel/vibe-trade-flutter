import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/notification_model.dart';
import 'package:vibe_trade_v1/pages/chat_thread_page.dart';
import 'package:vibe_trade_v1/pages/public_offer_page.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/notifications_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NotificationsService.fetchNotifications();
      await NotificationsService.markRead();
      if (!mounted) return;
      setState(() => _loading = false);
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tu sesión expiró. Inicia sesión nuevamente.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openNotification(NotificationModel item) async {
    if (item.threadId != null && item.threadId!.trim().isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadPage(threadId: item.threadId!),
        ),
      );
      return;
    }
    if (item.offerId != null && item.offerId!.trim().isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PublicOfferPage(offerId: item.offerId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBgColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _load,
        child: ValueListenableBuilder<List<NotificationModel>>(
          valueListenable: NotificationsService.itemsNotifier,
          builder: (context, items, _) {
            if (_loading && items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                ],
              );
            }
            if (_error != null && items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.error_outline, color: AppTheme.errorColor, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              );
            }
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.notifications_none_outlined,
                    color: AppTheme.textMuted,
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes notificaciones todavía.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationTile(
                  item: item,
                  onTap: () => _openNotification(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  String _timeLabel(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  IconData _iconForKind(String kind) {
    if (kind == 'offer_like' || kind == 'qa_comment_like') {
      return Icons.favorite_border;
    }
    if (kind == 'offer_comment') return Icons.forum_outlined;
    if (kind == 'chat_message') return Icons.chat_bubble_outline;
    if (kind.contains('route')) return Icons.route_outlined;
    return Icons.notifications_none_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.read ? AppTheme.dividerColor : AppTheme.primaryColor,
              width: item.read ? 1 : 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForKind(item.kind),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight:
                                  item.read ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel(item.createdAt),
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
