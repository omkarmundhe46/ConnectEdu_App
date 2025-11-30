import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AllUpcomingEventsScreen extends StatefulWidget {
  const AllUpcomingEventsScreen({super.key});

  @override
  State<AllUpcomingEventsScreen> createState() => _AllUpcomingEventsScreenState();
}

class _AllUpcomingEventsScreenState extends State<AllUpcomingEventsScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = context.read<EventRepository>().getAllUpcomingEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = context.read<EventRepository>().getAllUpcomingEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current user for passing to details screen
    final authState = context.read<AuthBloc>().state;
    final User? currentUser = (authState is AuthAuthenticated) ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Upcoming Events'),
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text('Failed to load events'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events found.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventCard(context, event, currentUser);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, User? currentUser) {
    final DateFormat dateFormat = DateFormat('EEE, MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (currentUser != null) {
            // Create a placeholder club object since we only have the ID
            final partialClub = Club(
                id: event.clubId ?? 0,
                name: 'Loading Club...',
                description: '',
                adminId: 0,
              category: 'ALL',
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(
                  club: partialClub,
                  event: event,
                  currentUser: currentUser,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              SizedBox(
                width: 100,
                height: 110, // Slightly smaller for list view
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.event)),
                  )
                      : Container(color: Colors.grey[300], child: const Icon(Icons.event)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                        "UPCOMING",
                        style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 10
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${dateFormat.format(event.date)} • ${timeFormat.format(event.date)}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(event.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.location, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}