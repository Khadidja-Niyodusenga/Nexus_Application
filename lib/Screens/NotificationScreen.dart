import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem {
  final String type; // "Tips", "New Updates", "Success Stories"
  final String title;
  final DateTime dateTime;
  final String message;
  bool isRead;

  NotificationItem({
    required this.type,
    required this.title,
    required this.dateTime,
    required this.message,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [
    NotificationItem(
      type: "Tips",
      title: "Water Day",
      dateTime: DateTime.now().subtract(Duration(minutes: 5)),
      message:
          "Today is World Water Day! 🌍 Take action now. Be responsible with water usage and help your community save water.",
    ),
    NotificationItem(
      type: "New Updates",
      title: "Energy Alert",
      dateTime: DateTime.now().subtract(Duration(minutes: 15)),
      message:
          "Reminder to save electricity today. Turn off unused lights and unplug devices when not in use.",
    ),
    NotificationItem(
      type: "Success Stories",
      title: "Community Event",
      dateTime: DateTime.now().subtract(Duration(hours: 1)),
      message:
          "Join the local cleanup drive this afternoon in your area. Let's make our community cleaner and greener!",
    ),
    NotificationItem(
      type: "Tips",
      title: "Recycle",
      dateTime: DateTime.now().subtract(Duration(hours: 2)),
      message: "Remember to recycle paper, plastic, and glass to reduce waste.",
    ),
  ];

  Map<String, Color> categoryColors = {
    "Tips": Colors.blue,
    "New Updates": Colors.green,
    "Success Stories": Colors.orange,
  };

  String formatTime(DateTime dateTime) {
    return DateFormat.Hm().format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    // Group notifications by type
    Map<String, List<NotificationItem>> grouped = {};
    for (var n in notifications) {
      grouped.putIfAbsent(n.type, () => []);
      grouped[n.type]!.add(n);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[300], // background grey
        foregroundColor: Colors.black, // makes title + icons black
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: grouped.entries.map((entry) {
          String type = entry.key;
          List<NotificationItem> items = entry.value;
          items
              .sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: categoryColors[type] ?? Colors.grey,
                        child: Text(
                          type.isNotEmpty ? type[0] : "?",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Notification list per category
                ...items.map((notification) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        notification.isRead = true;
                      });
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailScreen(
                              notification: notification),
                        ),
                      );
                      setState(() {}); // refresh list after returning
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message area
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time + unread number column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTime(notification.dateTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: notification.isRead
                                      ? Colors.black
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (!notification.isRead)
                                Text(
                                  "1", // number of unread notifications
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  String formatTime(DateTime dateTime) {
    return DateFormat.Hm().format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // <-- Change here to show the notification's category type
        title: Text(
          notification.type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[300], // ✅ Same as Feedback screen
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Time below container, left-aligned
            Text(
              formatTime(notification.dateTime),
              style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
