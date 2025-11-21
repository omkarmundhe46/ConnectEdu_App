import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/club_edit_screen.dart';
import 'package:connectedu_app/screens/event_list_screen.dart';
import 'package:connectedu_app/screens/add_member_dialog.dart';
import 'package:connectedu_app/screens/member_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Enum for College Admin actions
enum ClubAdminAction { update, delete }

// Enum for Club Admin actions
enum ClubMemberAction { addMember, manageMembers }

class ClubListScreen extends StatelessWidget {
  final User currentUser;
  const ClubListScreen({super.key, required this.currentUser});

  // Helper to show confirmation dialog for deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context, Club club) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
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

    return BlocProvider(
      create: (context) => ClubListBloc(
        clubRepository: context.read<ClubRepository>(),
        eventRepository: context.read<EventRepository>(),
      )..add(LoadClubsAndEvents()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clubs'),
          actions: [
            if (isCollegeAdmin)
              Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Create New Club',
                      onPressed: () {
                        Navigator.push(
                          buttonContext,
                          MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: buttonContext.read<ClubListBloc>(),
                                child: const ClubEditScreen(),
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
            } else if (state is ClubListError && state.isRefreshError) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refresh Error: ${state.message}'), backgroundColor: Colors.orange, duration: const Duration(seconds: 3)),
              );
            }
          },
          builder: (context, state) {
            if (state is ClubListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            ClubListLoaded? loadedState;
            bool isLoading = false;

            if (state is ClubListLoaded) {
              loadedState = state;
            } else if (state is ClubActionInProgress) {
              loadedState = state.previousState;
              isLoading = true;
            }

            if (loadedState != null) {
              final clubs = loadedState.clubs;
              final eventCounts = loadedState.eventCounts;

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<ClubListBloc>().add(LoadClubsAndEvents());
                    },
                    child: clubs.isEmpty
                        ? LayoutBuilder(
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
                      itemCount: clubs.length,
                      itemBuilder: (context, index) {
                        final club = clubs[index];
                        final count = eventCounts[club.id] ?? 0;
                        return _buildClubCard(context, club, count, isCollegeAdmin);
                      },
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            }
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
            return const Center(child: Text('Loading clubs...'));
          },
        ),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Club club, int eventCount, bool isCollegeAdmin) {
    final clubListBloc = BlocProvider.of<ClubListBloc>(context);

    // Check if user is Club Admin for THIS specific club
    final bool isClubAdmin = currentUser.role == 'CLUB_ADMIN' && currentUser.managedClubId == club.id;

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
              builder: (_) => EventListScreen(club: club, currentUser: currentUser),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: club.logoUrl!,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    errorWidget: (context, url, error) {
                      debugPrint("Error loading club logo ${club.name}: $error");
                      return _buildPlaceholderIcon(context, club.name);
                    },
                  ),
                )
                    : _buildPlaceholderIcon(context, club.name),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
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

              // --- 1. COLLEGE ADMIN MENU ---
              if (isCollegeAdmin)
                SizedBox(
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
                                value: clubListBloc,
                                child: ClubEditScreen(club: club),
                              )),
                        );
                      } else if (action == ClubAdminAction.delete) {
                        bool confirmed = await _showDeleteConfirmationDialog(context, club);
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
                )

              // --- 2. CLUB ADMIN MENU ---
              else if (isClubAdmin)
                SizedBox(
                  width: 40,
                  child: PopupMenuButton<ClubMemberAction>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Club Actions',
                    onSelected: (ClubMemberAction action) async {
                      if (action == ClubMemberAction.addMember) {
                        final bool? success = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AddMemberDialog(clubId: club.id),
                        );

                        if (success == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      } else if (action == ClubMemberAction.manageMembers) {
                        // Navigate to the new management screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RepositoryProvider.value(
                                value: context.read<ClubRepository>(),
                                child: MemberManagementScreen(club: club),
                              )
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<ClubMemberAction>>[
                      const PopupMenuItem<ClubMemberAction>(
                        value: ClubMemberAction.addMember,
                        child: ListTile(
                          leading: Icon(Icons.person_add_alt_1_outlined),
                          title: Text('Add Member'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<ClubMemberAction>(
                        value: ClubMemberAction.manageMembers,
                        child: ListTile(
                          leading: Icon(Icons.manage_accounts_outlined),
                          title: Text('Manage Members'),
                          contentPadding: EdgeInsets.zero,
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

  Widget _buildPlaceholderIcon(BuildContext context, String clubName) {
    IconData iconData = Icons.groups;
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