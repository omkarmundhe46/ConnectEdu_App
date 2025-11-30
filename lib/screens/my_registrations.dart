import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/my_registration.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  late Future<List<MyRegistration>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the data when the screen is first built
    _registrationsFuture = context.read<EventRepository>().getMyRegistrations();
  }

  // Helper to refresh the data
  Future<void> _refresh() async {
    setState(() {
      _registrationsFuture = context.read<EventRepository>().getMyRegistrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registrations'),
      ),
      body: FutureBuilder<List<MyRegistration>>(
        future: _registrationsFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading registrations: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _refresh,
                    )
                  ],
                ),
              ),
            );
          }

          // --- Empty State ---
          final registrations = snapshot.data;
          if (registrations == null || registrations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView( // Wrap in ListView to allow pull-to-refresh
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: Text('You have not registered for any events yet.'),
                    ),
                  ),
                ],
              ),
            );
          }

          // --- Loaded State ---
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final reg = registrations[index];
                return _buildRegistrationCard(context, reg);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegistrationCard(BuildContext context, MyRegistration reg) {
    final theme = Theme.of(context);
    final bool isUpcoming = reg.eventStatus == 'UPCOMING';

    // --- ADD THIS: Get the current user from the AuthBloc ---
    final authState = context.read<AuthBloc>().state;
    User? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }
    // --- END ---

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      // --- WRAP THE PADDING WITH AN INKWELL ---
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // --- ADD NAVIGATION LOGIC ---
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: User not found.')),
            );
            return;
          }

          // 1. Create a partial Event object from the registration data
          final Event event = Event(
            id: reg.eventId,
            name: reg.eventName,
            description: 'Loading...', // BLoC will fetch the full data
            date: reg.eventDate,
            location: 'Loading...', // BLoC will fetch the full data
            status: reg.eventStatus,
            clubId: reg.clubId,
            imageUrl: reg.eventImageUrl,
            // Other fields (contacts, etc.) will be null
          );

          // 2. Create a partial Club object
          final Club club = Club(
            id: reg.clubId,
            name: 'Loading...', // BLoC will fetch the full data
            description: '',
            adminId: 0, // This isn't used by the BLoC's logic
            category: 'ALL',
          );

          // 3. Navigate
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(
                club: club,
                event: event,
                currentUser: currentUser!,
              ),
            ),
          );
          // --- END NAVIGATION LOGIC ---
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: reg.eventImageUrl ?? '',
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    child: Center(
                      child: Text(
                        reg.eventName.substring(0, 1),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reg.eventName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('E, MMM d, yyyy').format(reg.eventDate),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${DateFormat('MMM d, hh:mm a').format(reg.registeredAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isUpcoming ? Colors.blue : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reg.eventStatus,
                        style: TextStyle(
                          color: (isUpcoming ? Colors.blue[800] : Colors.green[800]),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
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