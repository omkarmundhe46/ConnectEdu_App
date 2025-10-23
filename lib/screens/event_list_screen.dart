import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/event_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:intl/intl.dart';

// Enum for Admin actions
enum EventAdminAction { create, update, delete }

class EventListScreen extends StatelessWidget {
  final Club club;
  final User currentUser;

  const EventListScreen({super.key, required this.club, required this.currentUser});

  // Helper to determine if the current user is an authorized admin for THIS club
  bool _isAuthorizedAdmin() {
    return currentUser.role == 'COLLEGE_ADMIN' ||
        (currentUser.role == 'CLUB_ADMIN' && currentUser.managedClubId == club.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventListBloc(
        eventRepository: context.read<EventRepository>(),
      )..add(LoadEvents(club.id)), // Load events for this specific club
      child: Scaffold(
        appBar: AppBar(
          title: Text(club.name), // Show club name as title
          actions: [
            // --- Conditional Admin Menu ---
            if (_isAuthorizedAdmin())
              PopupMenuButton<EventAdminAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (EventAdminAction result) {
                  switch (result) {
                    case EventAdminAction.create:
                    // TODO: Navigate to Create Event Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to Create Event (Not Implemented)')));
                      break;
                  // Update/Delete require selecting an event first,
                  // usually done via a long-press or icon on the event card itself.
                    case EventAdminAction.update:
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Update Event action (Not Implemented - select an event)')));
                      break;
                    case EventAdminAction.delete:
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete Event action (Not Implemented - select an event)')));
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<EventAdminAction>>[
                  const PopupMenuItem<EventAdminAction>(
                    value: EventAdminAction.create,
                    child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Create Event')),
                  ),
                  const PopupMenuItem<EventAdminAction>(
                    value: EventAdminAction.update,
                    child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Update Event')),
                  ),
                  const PopupMenuItem<EventAdminAction>(
                    value: EventAdminAction.delete,
                    child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete Event')),
                  ),
                ],
              ),
          ],
        ),
        body: BlocConsumer<EventListBloc, EventListState>(
          listener: (context, state) {
            if (state is EventListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
              );
            }
          },
          builder: (context, state) {
            if (state is EventListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EventListLoaded) {
              return Column( // Use Column to hold filters and list
                children: [
                  // --- Filter Chips ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: SegmentedButton<EventFilter>(
                      segments: const <ButtonSegment<EventFilter>>[
                        ButtonSegment<EventFilter>(value: EventFilter.upcoming, label: Text('Upcoming'), icon: Icon(Icons.event_available)),
                        ButtonSegment<EventFilter>(value: EventFilter.past, label: Text('Past'), icon: Icon(Icons.event_busy)),
                      ],
                      selected: {state.currentFilter},
                      onSelectionChanged: (Set<EventFilter> newSelection) {
                        // Dispatch the FilterEvents event to the BLoC when the user taps a segment
                        if (newSelection.isNotEmpty) {
                          context.read<EventListBloc>().add(FilterEvents(newSelection.first));
                        }
                      },
                    ),
                  ),
                  // --- Event List ---
                  Expanded( // Make the list take remaining space
                    child: state.filteredEvents.isEmpty
                        ? Center(child: Text('No ${state.currentFilter.name} events found.'))
                        : RefreshIndicator(
                      onRefresh: () async => context.read<EventListBloc>().add(LoadEvents(club.id)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = state.filteredEvents[index];
                          return _buildEventCard(context, event);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            if (state is EventListError) {
              // Error display with retry
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text('Error loading events: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<EventListBloc>().add(LoadEvents(club.id)),
                        child: const Text('Retry'),
                      )
                    ],
                  )
              );
            }
            return const Center(child: Text('Press refresh or pull down to load events.'));
          },
        ),
        // --- Conditional Floating Action Button ---
        floatingActionButton: _isAuthorizedAdmin() ? FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to Create Event Screen
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Create Event (Not Implemented)')));
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          tooltip: 'Create Event',
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEventCard(BuildContext context, Event event) {
    final bool isUpcoming = event.status == 'UPCOMING';
    final DateFormat dateFormat = DateFormat('EEE, MMM d, yyyy'); // e.g., Sat, Apr 24, 2025
    final DateFormat timeFormat = DateFormat('h:mm a'); // e.g., 11:30 AM

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navigate to Event Details Screen
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigate to details for ${event.name} (Not Implemented)')));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image (using same logic as home screen)
            event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? Image.network(
              event.imageUrl!,
              height: 150, // Slightly taller image
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 150, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context, event.name, height: 150.0),
            )
                : _buildPlaceholderImage(context, event.name, height: 150.0),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isUpcoming ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                          color: isUpcoming ? Colors.green[800] : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 10
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date and Time
                  Text(
                    '${dateFormat.format(event.date)} at ${timeFormat.format(event.date)}',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  // Event Name
                  Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // TODO: Add Participant Count (requires backend change or N+1 call)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder image helper
  Widget _buildPlaceholderImage(BuildContext context, String eventName, {double height = 120.0}) {
    return Container(
      height: height,
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: Center(
          child: Text(
            eventName,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
          )
      ),
    );
  }
}
