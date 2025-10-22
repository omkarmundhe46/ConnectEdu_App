import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/user.dart'; // Import User model
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
// TODO: Import EventListScreen when created

// Define enum for admin actions
enum ClubAdminAction { create, update, delete }

class ClubListScreen extends StatelessWidget {
  final User currentUser; // Pass the logged-in user to check role

  const ClubListScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide necessary repositories to the BLoC
      create: (context) => ClubListBloc(
        clubRepository: context.read<ClubRepository>(),
        eventRepository: context.read<EventRepository>(),
      )..add(LoadClubs()), // Load data immediately
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clubs'),
          actions: [
            // --- Conditional Admin Menu ---
            if (currentUser.role == 'COLLEGE_ADMIN')
              PopupMenuButton<ClubAdminAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (ClubAdminAction result) {
                  switch (result) {
                    case ClubAdminAction.create:
                    // TODO: Navigate to Create Club Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to Create Club (Not Implemented)')));
                      break;
                  // Update/Delete would typically happen on a specific club's detail page
                  // but we can add placeholders here if needed for direct actions.
                    case ClubAdminAction.update:
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Update Club action (Not Implemented)')));
                      break;
                    case ClubAdminAction.delete:
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete Club action (Not Implemented)')));
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<ClubAdminAction>>[
                  const PopupMenuItem<ClubAdminAction>(
                    value: ClubAdminAction.create,
                    child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Create Club')),
                  ),
                  const PopupMenuItem<ClubAdminAction>(
                    value: ClubAdminAction.update,
                    child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Update Club')),
                  ),
                  const PopupMenuItem<ClubAdminAction>(
                    value: ClubAdminAction.delete,
                    child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete Club')),
                  ),
                ],
              ),
          ],
        ),
        body: BlocConsumer<ClubListBloc, ClubListState>(
          listener: (context, state) {
            if (state is ClubListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
              );
            }
          },
          builder: (context, state) {
            if (state is ClubListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ClubListLoaded) {
              if (state.clubsWithEventCounts.isEmpty) {
                return RefreshIndicator( // Allow refresh even when empty
                    onRefresh: () async => context.read<ClubListBloc>().add(LoadClubs()),
                    child: const Center(child: Text('No clubs found.'))
                );
              }
              return RefreshIndicator(
                onRefresh: () async => context.read<ClubListBloc>().add(LoadClubs()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.clubsWithEventCounts.length,
                  itemBuilder: (context, index) {
                    final clubData = state.clubsWithEventCounts[index];
                    return _buildClubCard(context, clubData['club'] as Club, clubData['eventCount'] as int);
                  },
                ),
              );
            }
            if (state is ClubListError) {
              return Center(
                  child: Column( // Show error message with retry
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text('Error loading clubs: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<ClubListBloc>().add(LoadClubs()),
                        child: const Text('Retry'),
                      )
                    ],
                  )
              );
            }
            return const Center(child: Text('Press refresh or pull down to load clubs.')); // Initial state
          },
        ),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Club club, int eventCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensure InkWell ripple effect respects border radius
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navigate to Event List Screen for this club
          // Navigator.push(context, MaterialPageRoute(builder: (_) => EventListScreen(club: club)));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigate to events for ${club.name} (Not Implemented)')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder Logo/Image with some styling
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon( // Dynamic Icon based on club name
                      club.name.toLowerCase().contains('code') || club.name.toLowerCase().contains('tech') ? Icons.code
                          : club.name.toLowerCase().contains('sport') ? Icons.sports_basketball
                          : club.name.toLowerCase().contains('music') ? Icons.music_note
                          : Icons.groups, // Default icon
                      size: 30,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          club.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              // Event Count Display
              Row(
                children: [
                  Icon(Icons.event_note, size: 16, color: Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '$eventCount Event${eventCount != 1 ? 's' : ''} upcoming', // Clarify count
                    style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

