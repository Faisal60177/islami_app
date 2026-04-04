import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../model/notification_model.dart';
import 'type_badge.dart';

const _accent   = Color(0xFF4CAF82);
const _surface  = Color(0xFF0D2E1C);
const _bgDeep   = Color(0xFF011A0D);

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onMarkUnread;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onMarkUnread,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final n  = notification;
    final unread = !n.isRead;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      // Red delete background revealed on swipe
      background: _swipeBg(sw),
      confirmDismiss: (_) => _confirmDelete(context, sw),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          // Auto mark read when user opens
          if (unread) onMarkRead();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.only(bottom: sw * 0.032),
          decoration: BoxDecoration(
            color: unread
                ? const Color(0xFF0B2E1C)
                : _surface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(sw * 0.042),
            border: Border.all(
              color: unread
                  ? _accent.withOpacity(0.35)
                  : Colors.white.withOpacity(0.07),
              width: unread ? 1.0 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(sw * 0.042),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Unread indicator bar ─────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 4,
                    color: unread ? _accent : Colors.transparent,
                  ),

                  // ── Tile content ─────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(sw * 0.038),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: badge | time | menu
                          Row(
                            children: [
                              TypeBadge(type: n.type),
                              const Spacer(),
                              Text(
                                timeago.format(n.createdAt),
                                style: TextStyle(
                                    color: Colors.white30,
                                    fontSize: sw * 0.028),
                              ),
                              SizedBox(width: sw * 0.010),
                              _menu(context, sw),
                            ],
                          ),
                          SizedBox(height: sw * 0.020),

                          // Title
                          Text(
                            n.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? Colors.white : Colors.white70,
                              fontSize: sw * 0.040,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: sw * 0.012),

                          // Body preview (2 lines max)
                          Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: sw * 0.032,
                                height: 1.5),
                          ),

                          // Source tag (hadiths)
                          if (n.source != null) ...[
                            SizedBox(height: sw * 0.016),
                            Text(
                              '— ${n.source}',
                              style: TextStyle(
                                color: _accent.withOpacity(0.55),
                                fontSize: sw * 0.028,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Red swipe-delete background
  Widget _swipeBg(double sw) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: sw * 0.065),
      margin: EdgeInsets.only(bottom: sw * 0.032),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(sw * 0.042),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: Colors.red[300], size: sw * 0.062),
          SizedBox(height: sw * 0.008),
          Text('Delete',
              style: TextStyle(
                  color: Colors.red[300],
                  fontSize: sw * 0.028,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Three-dot popup menu
  Widget _menu(BuildContext context, double sw) {
    final n = notification;
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: const Color(0xFF0A2E1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sw * 0.032),
        side: BorderSide(color: _accent.withOpacity(0.18)),
      ),
      icon: Icon(Icons.more_vert_rounded,
          color: Colors.white30, size: sw * 0.048),
      onSelected: (val) {
        switch (val) {
          case 'read':   onMarkRead();   break;
          case 'unread': onMarkUnread(); break;
          case 'delete': onDelete();     break;
          case 'share':
            Share.share(
              '${n.title}\n\n${n.body}'
                  '${n.source != null ? '\n\n— ${n.source}' : ''}',
            );
        }
      },
      itemBuilder: (_) => [
        if (!n.isRead)
          _item('read',   Icons.mark_email_read_rounded,   'Mark as read'),
        if (n.isRead)
          _item('unread', Icons.mark_email_unread_rounded, 'Mark as unread'),
        _item('share',  Icons.share_rounded,               'Share'),
        _item('delete', Icons.delete_rounded,              'Delete',
            color: Colors.red[300]!),
      ],
    );
  }

  PopupMenuItem<String> _item(
      String val, IconData icon, String label,
      {Color color = Colors.white70}) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, double sw) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A2E1C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw * 0.050)),
        title: Text('Delete notification',
            style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.042,
                fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently remove this notification.',
            style: TextStyle(color: Colors.white54, fontSize: sw * 0.034)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(color: _accent, fontSize: sw * 0.035))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: TextStyle(
                      color: Colors.red[300],
                      fontSize: sw * 0.035,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}