import 'package:connectedu_app/bloc/event_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/certificate-service.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/repositories/discussion_repository.dart'; // --- ADD ---
import 'package:connectedu_app/services/api_service.dart'; // --- ADD ---
import 'package:connectedu_app/screens/event_details_screen.dart';
import 'package:connectedu_app/screens/event_edit_screen.dart';
import 'package:connectedu_app/screens/certificate_config_screen.dart'; // --- ADD ---
import 'package:connectedu_app/widgets/skeleton_event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:connectedu_app/widgets/skeleton_event_card.dart';

// --- UPDATED ENUM ---
enum EventAdminAction { update, delete, updateLink, designCertificate }
// --- END UPDATE ---

class EventListScreen extends StatelessWidget {
  final Club club;
  final User currentUser;

  const EventListScreen({super.key, required this.club, required this.currentUser});

  // --- CORRECTED LOGIC: Only the Club Admin for THIS club is an admin ---
  bool _isClubAdminForThisClub() {
    return currentUser.role == 'CLUB_ADMIN' && currentUser.managedClubId == club.id;
  }
  // --- END OF CORRECTION ---

  Future<void> _showUpdateLinkDialog(BuildContext context, Event event, EventListBloc bloc) async {
    final controller = TextEditingController(text: event.meetingLink ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Meeting Link'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://zoom.us/j/123456...',
              labelText: 'Meeting URL',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                final newLink = controller.text;
                // Dispatch the BLoC event
                bloc.add(UpdateMeetingLink(
                  clubId: club.id,
                  eventId: event.id,
                  meetingLink: newLink,
                ));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper for Delete Confirmation Dialog
  Future<bool> _showDeleteConfirmationDialog(BuildContext context, Event event) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the event "${event.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Use the corrected helper method
    final bool isAuthorizedAdmin = _isClubAdminForThisClub();

    return BlocProvider(
      create: (context) => EventListBloc(
        eventRepository: context.read<EventRepository>(),
      )..add(LoadEvents(club.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(club.name),
          actions: [
            // --- CORRECTED LOGIC: Button is only visible to the correct admin ---
            if (isAuthorizedAdmin)
              Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Create New Event',
                      onPressed: () async {
                        final result = await Navigator.push(
                          buttonContext,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: buttonContext.read<EventListBloc>(),
                              child: EventEditScreen(club: club), // Pass club, event is null (Create mode)
                            ),
                          ),
                        );
                        if (result == true && buttonContext.mounted) {
                          buttonContext.read<EventListBloc>().add(LoadEvents(club.id));
                        }
                      },
                    );
                  }
              ),
          ],
        ),
        body: BlocConsumer<EventListBloc, EventListState>(
          listener: (context, state) {
            if (state is EventActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
            } else if (state is EventActionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is EventListLoading) {
              // Instead of const Center(child: CircularProgressIndicator()), do this:
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 6, // Show 6 fake cards
                itemBuilder: (context, index) => const SkeletonEventCard(),
              );
            }

            EventListLoaded? loadedState;
            bool isLoadingOverlay = false;
            if (state is EventListLoaded) {
              loadedState = state;
            } else if (state is EventActionInProgress) {
              loadedState = state.previousState;
              isLoadingOverlay = true;
            }

            if (loadedState != null) {
              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: SegmentedButton<EventFilter>(
                          segments: const <ButtonSegment<EventFilter>>[
                            ButtonSegment<EventFilter>(value: EventFilter.upcoming, label: Text('Upcoming'), icon: Icon(Icons.event_available)),
                            ButtonSegment<EventFilter>(value: EventFilter.past, label: Text('Past'), icon: Icon(Icons.event_busy)),
                          ],
                          selected: {loadedState.currentFilter},
                          onSelectionChanged: (Set<EventFilter> newSelection) {
                            if (newSelection.isNotEmpty) {
                              context.read<EventListBloc>().add(FilterEvents(newSelection.first));
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: loadedState.filteredEvents.isEmpty
                            ? Center(child: Text('No ${loadedState.currentFilter.name} events found.'))
                            : RefreshIndicator(
                          onRefresh: () async => context.read<EventListBloc>().add(LoadEvents(club.id)),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: loadedState.filteredEvents.length,
                            itemBuilder: (listContext, index) {
                              final event = loadedState!.filteredEvents[index];
                              return _buildEventCard(listContext, event, isAuthorizedAdmin);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoadingOverlay)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            }
            if (state is EventListError) {
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
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildEventCard(BuildContext context, Event event, bool isAdmin) {
    final bool isUpcoming = event.status == 'UPCOMING';
    final DateFormat dateFormat = DateFormat('EEE, MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final eventListBloc = BlocProvider.of<EventListBloc>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(
                club: club,
                event: event,
                currentUser: currentUser,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              SizedBox(
                width: 100,
                height: 150,
                child: ClipRRect( // Clip the image to rounded corners
                  borderRadius: BorderRadius.circular(8.0),
                  // child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                  //     ? CachedNetworkImage(
                  //   imageUrl: event.imageUrl!,
                  //   fit: BoxFit.cover,
                  //   placeholder: (context, url) => Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
                  //   errorWidget: (context, url, error) => _buildPlaceholderImage(context, event.name),
                  // )
                  child: Hero(
                    // The tag MUST be unique per image. Using the URL is usually safe.
                    // If URL is null, use the event ID string.
                    tag: event.imageUrl ?? 'event_${event.id}',
                    child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      // ... existing placeholder/error logic ...
                    )
                      : _buildPlaceholderImage(context, event.name),
                ),
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
                    Text('${dateFormat.format(event.date)} at ${timeFormat.format(event.date)}',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(event.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.location, style: TextStyle(color: Theme.of(context).hintColor))),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                SizedBox(
                  width: 40,
                  child: PopupMenuButton<EventAdminAction>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Event Actions',
                    onSelected: (EventAdminAction action) async {
                      if (action == EventAdminAction.update) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: eventListBloc,
                              child: EventEditScreen(club: club, event: event),
                            ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          eventListBloc.add(LoadEvents(club.id));
                        }
                      } else if (action == EventAdminAction.delete) {
                        bool confirmed = await _showDeleteConfirmationDialog(context, event);
                        if (confirmed && context.mounted) {
                          eventListBloc.add(DeleteEvent(clubId: club.id, eventId: event.id));
                        }
                      } else if (action == EventAdminAction.updateLink) {
                        _showUpdateLinkDialog(context, event, eventListBloc);


                      } else if (action == EventAdminAction.designCertificate) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RepositoryProvider(
                              create: (c) => CertificateRepository(context.read<ApiService>()), // Use CertificateRepo
                              child: CertificateConfigScreen(
                                  eventId: event.id,
                                  // Pass the actual category from the Club object
                                  clubCategory: club.category
                              ),
                            ),
                          ),
                        );
                      }

                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<EventAdminAction>>[
                      const PopupMenuItem<EventAdminAction>(
                        value: EventAdminAction.update,
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Event')),
                      ),
                      const PopupMenuItem<EventAdminAction>(
                        value: EventAdminAction.updateLink,
                        child: ListTile(leading: Icon(Icons.link_outlined), title: Text('Update Link')),
                      ),
                      // --- ADD MENU ITEM ---
                      const PopupMenuItem<EventAdminAction>(
                        value: EventAdminAction.designCertificate,
                        child: ListTile(leading: Icon(Icons.card_membership), title: Text('Design Certificate')),
                      ),
                      // --- END ADDITION ---
                      const PopupMenuItem<EventAdminAction>(
                        value: EventAdminAction.delete,
                        child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.redAccent), title: Text('Delete Event')),
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

  Widget _buildPlaceholderImage(BuildContext context, String eventName) {
    return Container(
      width: 100,
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              eventName,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
            ),
          )
      ),
    );
  }
}