import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/club_edit_screen.dart'; // Import Edit Screen
import 'package:connectedu_app/screens/event_list_screen.dart'; // Import Event List Screen
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

// Enum for Admin actions
enum ClubAdminAction { update, delete }

class ClubListScreen extends StatelessWidget {
  final User currentUser;
  const ClubListScreen({super.key, required this.currentUser});

  // Helper to show confirmation dialog for deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context, Club club) async {
    // This context will have the BLoC
    final bloc = BlocProvider.of<ClubListBloc>(context);
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) { // Use different context name
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the club "${club.name}"? This action cannot be undone.'),
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
    final bool isCollegeAdmin = currentUser.role == 'COLLEGE_ADMIN';

    // Provide the BLoC at this screen level
    return BlocProvider(
      create: (context) => ClubListBloc(
        clubRepository: context.read<ClubRepository>(),
        eventRepository: context.read<EventRepository>(),
      )..add(LoadClubsAndEvents()), // Load data immediately
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clubs'),
          actions: [
            // Conditional "Create Club" button for College Admin
            if (isCollegeAdmin)
            // Use Builder to get Scaffold context that has the BlocProvider
              Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Create New Club',
                      onPressed: () {
                        Navigator.push(
                          buttonContext, // Use context from Builder
                          MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: buttonContext.read<ClubListBloc>(), // Provide existing BLoC
                                child: const ClubEditScreen(), // No club passed = Create mode
                              )),
                        );
                      },
                    );
                  }
              ),
          ],
        ),
        body: BlocConsumer<ClubListBloc, ClubListState>(
          listener: (context, state) {
            // Show SnackBars for success/failure feedback on actions
            if (state is ClubActionSuccess) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
              );
            } else if (state is ClubActionFailure) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
              );
            } else if (state is ClubListError && state.isRefreshError) { // Show refresh errors briefly
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refresh Error: ${state.message}'), backgroundColor: Colors.orange, duration: const Duration(seconds: 3)),
              );
            }
          },
          builder: (context, state) {
            // Handle Loading state (initial load only)
            if (state is ClubListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Define loadedState and isLoading for clarity
            ClubListLoaded? loadedState;
            bool isLoading = false;

            if (state is ClubListLoaded) {
              loadedState = state;
            } else if (state is ClubActionInProgress) {
              loadedState = state.previousState; // May be null
              isLoading = true;
            }

            // Handle Loaded state (displays list + potential loading overlay)
            if (loadedState != null) {
              // --- THIS IS THE FIX ---
              // Create local non-nullable variables inside the null check
              final clubs = loadedState.clubs;
              final eventCounts = loadedState.eventCounts;
              // --- END OF FIX ---

              return Stack( // Use Stack to show loading overlay during actions
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<ClubListBloc>().add(LoadClubsAndEvents());
                    },
                    child: clubs.isEmpty // Use the safe 'clubs' variable
                        ? LayoutBuilder( // Allows RefreshIndicator on empty list
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No clubs found.\nPull down to refresh.', textAlign: TextAlign.center,),
                          )),
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: clubs.length, // Use the safe 'clubs' variable
                      itemBuilder: (context, index) {
                        final club = clubs[index]; // Use the safe 'clubs' variable
                        final count = eventCounts[club.id] ?? 0;
                        // Pass the BLoC's context down to the card for actions
                        return _buildClubCard(context, club, count, isCollegeAdmin);
                      },
                    ),
                  ),
                  // Show overlay if an action is in progress on top of the list
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            }
            // Handle Error state (initial load error)
            if (state is ClubListError && !state.isRefreshError) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text('Error loading clubs: ${state.message}', textAlign: TextAlign.center,),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            onPressed: () => context.read<ClubListBloc>().add(LoadClubsAndEvents()),
                          )
                        ],
                      )
                  )
              );
            }
            // Initial state (before loading starts or if loadedState is null)
            return const Center(child: Text('Loading clubs...'));
          },
        ),
      ),
    );
  }

  // Updated Club Card to pass BLoC context for actions
  Widget _buildClubCard(BuildContext context, Club club, int eventCount, bool isCollegeAdmin) {
    // Need context that has ClubListBloc for the actions
    final clubListBloc = BlocProvider.of<ClubListBloc>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to EventListScreen, providing necessary repositories/user
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventListScreen(club: club, currentUser: currentUser),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align items top
            children: [
              // --- Use CachedNetworkImage to load the logoUrl ---
              CircleAvatar(
                radius: 30, // Increased radius
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                // Check if logoUrl is valid and not empty
                child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: club.logoUrl!,
                    fit: BoxFit.cover,
                    width: 60, // Diameter of the CircleAvatar
                    height: 60,
                    // Loading placeholder
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    // Error fallback
                    errorWidget: (context, url, error) {
                      debugPrint("Error loading club logo ${club.name}: $error");
                      return _buildPlaceholderIcon(context, club.name); // Fallback icon
                    },
                  ),
                )
                    : _buildPlaceholderIcon(context, club.name), // Default icon if no logoUrl
              ),
              // --- END OF IMAGE FIX ---

              const SizedBox(width: 16),
              // Club Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Adjusted size
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor), // Adjusted size
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Event Count Display
                    Row(
                      children: [
                        Icon(Icons.event_note_outlined, size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                          '$eventCount Upcoming Event${eventCount != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Conditional Admin Menu
              if (isCollegeAdmin)
                SizedBox( // Constrain width of the button
                  width: 40,
                  child: PopupMenuButton<ClubAdminAction>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Admin Actions',
                    onSelected: (ClubAdminAction action) async {
                      if (action == ClubAdminAction.update) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: clubListBloc, // Use BLoC from Card's context
                                child: ClubEditScreen(club: club), // Pass club for Edit mode
                              )),
                        );
                      } else if (action == ClubAdminAction.delete) {
                        // Use the context passed into _buildClubCard
                        bool confirmed = await _showDeleteConfirmationDialog(context, club);

                        // Check context is still valid after await
                        if (confirmed && context.mounted) {
                          clubListBloc.add(DeleteClub(club.id));
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<ClubAdminAction>>[
                      const PopupMenuItem<ClubAdminAction>(
                        value: ClubAdminAction.update,
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Club')),
                      ),
                      const PopupMenuItem<ClubAdminAction>(
                        value: ClubAdminAction.delete,
                        child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.redAccent), title: Text('Delete Club', style: TextStyle(color: Colors.redAccent))),
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

  // Helper widget for the placeholder icon
  Widget _buildPlaceholderIcon(BuildContext context, String clubName) {
    IconData iconData = Icons.groups; // Default
    if (clubName.toLowerCase().contains('code') || clubName.toLowerCase().contains('tech')) {
      iconData = Icons.code;
    } else if (clubName.toLowerCase().contains('sport')) {
      iconData = Icons.sports_basketball;
    } else if (clubName.toLowerCase().contains('music')) {
      iconData = Icons.music_note;
    }
    return Icon(
      iconData,
      size: 30,
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }
}

