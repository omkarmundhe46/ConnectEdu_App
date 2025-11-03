import 'package:connectedu_app/models/notification_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // Import the new package
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationLog notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Subject ---
            Text(
              notification.subject,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // --- Date ---
            Text(
              DateFormat('E, MMM d, yyyy • hh:mm a').format(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const Divider(height: 32),
            // --- HTML Body ---
            // This widget renders the HTML content from your backend
            Html(
              data: notification.body,
              style: {
                "body": Style(
                  fontSize: FontSize(16.0),
                  lineHeight: const LineHeight(1.5),
                  margin: Margins.zero, // Remove default margin
                ),
                "h1": Style(fontSize: FontSize(24.0)),
                "p": Style(fontSize: FontSize(16.0)),
                "b": Style(fontWeight: FontWeight.bold),
              },
            ),
          ],
        ),
      ),
    );
  }
}