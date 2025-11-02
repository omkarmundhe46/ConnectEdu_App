import 'package:connectedu_app/bloc/event_detail_bloc.dart';
import 'package:connectedu_app/bloc/event_detail_event.dart';
import 'package:connectedu_app/bloc/event_detail_state.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/certificate-service.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/registration_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatelessWidget {
  final Club club;
  final Event event;
  final User currentUser;

  const EventDetailsScreen({
    super.key,
    required this.club,
    required this.event,
    required this.currentUser,
  });

  // Helper function to share the event
  void _shareEvent(BuildContext context) {
    final eventDetails = 'Check out this event: ${event.name} on ${DateFormat('MMM d').format(event.date)}! Join now on ConnectEdu.';
    Share.share(eventDetails, subject: 'Event Invitation: ${event.name}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventDetailBloc(
        clubRepository: context.read<ClubRepository>(),
        eventRepository: context.read<EventRepository>(),
      )..add(LoadDetails(
        clubId: club.id,
        eventId: event.id,
        userId: currentUser.id,
      )),
      child: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            _buildSliverAppBar(context),
            _buildSliverContent(context),
          ],
        ),
        bottomNavigationBar: _buildBottomButton(context),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () => _shareEvent(context),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: event.imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildPlaceholderImage(context, event.name),
        )
            : _buildPlaceholderImage(context, event.name),
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                ]
            ),
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildParticipantList(),
                      const SizedBox(height: 24),
                      Text(event.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildInfoRow(context, Icons.calendar_today_outlined,
                          DateFormat('E, MMM d, yyyy • hh:mm a').format(event.date)),
                      _buildInfoRow(context, Icons.location_on_outlined, event.location),
                      _buildInfoRow(context, Icons.group_outlined, 'Organized by ${club.name}'),
                      const Divider(height: 32),

                      Text('Event Coordinators', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (event.contactName1 != null && event.contactPhone1 != null)
                        _buildContactRow(context, event.contactName1!, event.contactPhone1!),
                      if (event.contactName2 != null && event.contactPhone2 != null)
                        _buildContactRow(context, event.contactName2!, event.contactPhone2!),

                      const Divider(height: 32),
                      Text('About this Event', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: Theme.of(context).textTheme.bodySmall?.color)
                      ),
                      const SizedBox(height: 100), // Padding for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantList() {
    return BlocBuilder<EventDetailBloc, EventDetailState>(
      builder: (context, state) {
        if (state is EventDetailLoaded) {
          if (state.participants.isEmpty) {
            return const Center(child: Text('Be the first to register!'));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 36,
                    child: Stack(
                      children: List.generate(
                        state.participants.length.clamp(0, 4),
                            (index) => Positioned(
                          left: (index * 18.0),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blueGrey[100],
                              child: const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                            ),
                          ),
                        ),
                      ).reversed.toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${state.participants.length} Going',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Invite'),
                onPressed: () => _shareEvent(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          );
        }
        return Container(
          height: 40,
          alignment: Alignment.centerLeft,
          child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 20),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, String name, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.account_circle_outlined, color: Theme.of(context).hintColor, size: 24),
          const SizedBox(width: 20),
          Expanded(child: Text(name, style: Theme.of(context).textTheme.bodyLarge)),
          IconButton(
            icon: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
            tooltip: 'Call $name',
            onPressed: () async {
              final Uri launchUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context, String text) {
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: BlocBuilder<EventDetailBloc, EventDetailState>(
        builder: (context, state) {
          // Default: Loading state
          if (state is EventDetailLoading || state is EventDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventDetailError) {
            return const SizedBox.shrink(); // Don't show a button on error
          }

          // We must be in EventDetailLoaded state here
          final loadedState = state as EventDetailLoaded;
          bool isEventOver = event.status == 'COMPLETED';
          String userRole = currentUser.role;

          // --- 1. CHECK IF USER IS STAFF OF *THIS* CLUB ---
          bool isThisClubStaff = (userRole == 'CLUB_ADMIN' && currentUser.managedClubId == club.id) ||
              (userRole == 'CLUB_MEMBER' && loadedState.isClubMember);

          // Priority 1: User is already registered for the event.
          if (loadedState.isRegistered) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Certificate'),
                    // --- START OF CHANGE ---
                    // Make the onPressed async
                    onPressed: isEventOver ? () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Downloading Certificate...'),
                            ],
                          ),
                          duration: Duration(seconds: 30),
                        ),
                      );

                      try {
                        // Call the new repository
                        await context.read<CertificateRepository>().downloadCertificate(
                          event.id,
                          currentUser.id,
                          event.name,
                        );
                        scaffoldMessenger.removeCurrentSnackBar();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Download complete! Opening file...'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        scaffoldMessenger.removeCurrentSnackBar();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Download Failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
                        );
                      }
                    } : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // --- 2. SHOW JOIN BUTTON IF STAFF ---
                // If they are registered, they might also be staff. Show Join button.
                if (isThisClubStaff && event.meetingLink != null && event.meetingLink!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Join'),
                      onPressed: () => _launchMeetingLink(context, event.meetingLink!),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }

          // Priority 2: Event is over and user is not registered.
          if (isEventOver) {
            return const SizedBox.shrink();
          }

          // --- 3. SHOW ADMIN/STAFF BUTTONS ---
          // If the user is staff AND not registered, show the admin buttons.

          if (isThisClubStaff) {
            return _buildAdminButtonRow(context, event);
          }

          // Priority 4: User is COLLEGE_ADMIN (but not staff of this club)
          if (userRole == 'COLLEGE_ADMIN') {
            return const SizedBox.shrink(); // College Admins can't register
          }

          // Priority 5: User is a USER or a CLUB_MEMBER of a DIFFERENT club.
          // Both are allowed to register.
          return _buildRegisterButton(context);
        },
      ),
    );
  }

  Widget _buildAdminButtonRow(BuildContext context, Event event) {
    bool canJoin = event.meetingLink != null && event.meetingLink!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: const Text('Excel'),
            onPressed: () async {
              // Show a loading snackbar
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Downloading Excel file...'),
                    ],
                  ),
                  duration: Duration(seconds: 30), // Keep it open
                ),
              );

              try {
                // Call the repository method
                await context.read<EventRepository>().downloadParticipantsExcel(
                  club.id,
                  event.id,
                  event.name.replaceAll(' ', '_'), // Create a safe filename
                );
                scaffoldMessenger.removeCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Download complete! Opening file...'), backgroundColor: Colors.green),
                );
              } catch (e) {
                scaffoldMessenger.removeCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Download Failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Join'),
            // Enable/disable based on meeting link
            onPressed: canJoin ? () => _launchMeetingLink(context, event.meetingLink!) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- ADD THIS HELPER METHOD ---
  Future<void> _launchMeetingLink(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch meeting link'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper widget for the Register button
  Widget _buildRegisterButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: BlocProvider.of<EventDetailBloc>(context),
              child: RegistrationFormScreen(event: event, currentUser: currentUser),
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Register Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}
