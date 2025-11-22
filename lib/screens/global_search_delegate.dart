import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/event_details_screen.dart';
import 'package:connectedu_app/screens/event_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final ClubRepository clubRepository;
  final EventRepository eventRepository;
  final User currentUser;

  GlobalSearchDelegate({
    required this.clubRepository,
    required this.eventRepository,
    required this.currentUser,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Clear button (X)
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Back button
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for clubs or events...'));
    }
    // We use the same logic for suggestions to give "live" results
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    // Avoid searching for very short strings to reduce API load
    if (query.length < 2) {
      return Container();
    }

    return FutureBuilder(
      // Run both searches in parallel
      future: Future.wait([
        clubRepository.searchClubs(query),
        eventRepository.searchEvents(query),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error searching. Please try again.'));
        }

        final clubs = snapshot.data?[0] as List<Club>? ?? [];
        final events = snapshot.data?[1] as List<Event>? ?? [];

        if (clubs.isEmpty && events.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (clubs.isNotEmpty) ...[
              _buildSectionTitle(context, 'Clubs'),
              ...clubs.map((club) => _buildClubTile(context, club)),
              const SizedBox(height: 16),
            ],
            if (events.isNotEmpty) ...[
              _buildSectionTitle(context, 'Events'),
              ...events.map((event) => _buildEventTile(context, event)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildClubTile(BuildContext context, Club club) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(club.logoUrl!)
            : null,
        child: (club.logoUrl == null || club.logoUrl!.isEmpty)
            ? const Icon(Icons.groups)
            : null,
      ),
      title: Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(club.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        // Navigate to the Club's Event List
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventListScreen(club: club, currentUser: currentUser),
          ),
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: event.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.event),
        )
            : const Icon(Icons.event, size: 40),
      ),
      title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${DateFormat('MMM d').format(event.date)} • ${event.location}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: event.status == 'UPCOMING'
          ? const Icon(Icons.calendar_today, size: 16, color: Colors.green)
          : const Icon(Icons.history, size: 16, color: Colors.grey),
      onTap: () {
        // Create a placeholder club object because we only have the ID
        // The EventDetailsScreen BLoC will fetch the real club details
        final partialClub = Club(
            id: event.clubId ?? 0,
            name: 'Loading...',
            description: '',
            adminId: 0
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
      },
    );
  }
}