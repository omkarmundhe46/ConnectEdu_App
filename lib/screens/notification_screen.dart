import 'package:connectedu_app/bloc/notification_bloc/notification_bloc.dart';
import 'package:connectedu_app/models/notification_log.dart';
// --- ADD THIS IMPORT ---
import 'package:connectedu_app/screens/notification_detail_screen.dart';
// --- END OF IMPORT ---
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        context.read<NotificationBloc>().add(LoadNotifications());
                      },
                    )
                  ],
                ),
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(LoadNotifications());
                },
                child: ListView( // Wrap in ListView to allow pull-to-refresh
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(
                        child: Text('You have no notifications.'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationCard(context, notification);
                },
              ),
            );
          }

          // Initial state
          return const Center(child: Text('Loading notifications...'));
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationLog notification) {
    // Simple way to parse the HTML-like body from the backend
    final String bodyText = notification.body
        .replaceAll(RegExp(r'<[^>]*>'), ' ') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ')    // Remove extra whitespace
        .trim();

    // Determine an icon
    IconData icon = Icons.notifications;
    Color iconColor = Colors.blue;
    if (notification.subject.toLowerCase().contains('welcome')) {
      icon = Icons.person_add;
      iconColor = Colors.green;
    } else if (notification.subject.toLowerCase().contains('certificate')) {
      icon = Icons.school;
      iconColor = Colors.purple;
    } else if (notification.subject.toLowerCase().contains('registered')) {
      icon = Icons.check_circle;
      iconColor = Colors.blueAccent;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        notification.subject,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        bodyText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        DateFormat('MMM d').format(notification.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      // --- THIS IS THE CHANGE ---
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Navigate to the detail screen you created
            builder: (_) => NotificationDetailScreen(notification: notification),
          ),
        );
      },
      // --- END OF CHANGE ---
    );
  }
}