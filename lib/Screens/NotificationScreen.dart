import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final DateTime dateTime;
  final String message;
  final String url;
  final String status;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    required this.message,
    required this.url,
    required this.status,
    this.isRead = false,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      type: data['notification_type'] ?? "Unknown",
      title: data['title'] ?? "No Title",
      dateTime: (data['timestamp'] as Timestamp).toDate(),
      message: data['description'] ?? "",
      url: data['url'] ?? "",
      status: data['status'] ?? "",
      isRead: data['isRead'] ?? false,
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat.Hm().format(dateTime); // Today → hour
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return "Yesterday"; // Will display below container
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime); // Older → date
    }
  }

  Future<void> markAsRead(NotificationItem notification) async {
    if (!notification.isRead) {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(notification.id)
          .update({"isRead": true});
      notification.isRead = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            //.where("status", isEqualTo: "Published")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No published notifications yet"));
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationItem.fromFirestore(doc))
              .where((n) => n.status == "Published") // 👈 filter locally
              .toList();

          // Keep only latest notification per type & unread count
          final Map<String, NotificationItem> latestByType = {};
          final Map<String, int> unreadCountByType = {};
          for (var n in notifications) {
            if (!latestByType.containsKey(n.type)) {
              latestByType[n.type] = n;
            }
            if (!n.isRead) {
              unreadCountByType[n.type] = (unreadCountByType[n.type] ?? 0) + 1;
            }
          }

          if (latestByType.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: latestByType.entries.map((entry) {
              final type = entry.key;
              final notification = entry.value;
              final unreadCount = unreadCountByType[type] ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // mark all notifications of this type as read
                      final typeNotifications =
                          notifications.where((n) => n.type == type).toList();

                      for (var n in typeNotifications) {
                        await markAsRead(n);
                      }

                      // Navigate to detail screen showing all notifications of this type
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailScreen(
                              type: type, notifications: typeNotifications),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTime(notification.dateTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: unreadCount > 0
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final String type;
  final List<NotificationItem> notifications;

  const NotificationDetailScreen({
    super.key,
    required this.type,
    required this.notifications,
  });

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat.Hm().format(dateTime);
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Ensure it opens in external browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Older notifications on top
    notifications.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: Text(type),
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    // Add URL at the end of the notification
                    if (n.url.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openUrl(context, n.url),
                        child: Text(
                          n.url,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 6),
                child: Text(
                  formatTime(n.dateTime),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
