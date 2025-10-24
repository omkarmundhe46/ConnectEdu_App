import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/club_edit_screen.dart';
import 'package:connectedu_app/screens/club_list_screen.dart';
import 'package:connectedu_app/screens/event_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import this

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  // Helper function to count upcoming events per club
  Map<int, int> _countUpcomingEventsPerClub(List<Event> events) {
    final Map<int, int> counts = {};
    for (var event in events) {
      if (event.clubId != null && event.status == 'UPCOMING') {
        counts[event.clubId!] = (counts[event.clubId!] ?? 0) + 1;
      }
    }
    return counts;
  }


  @override
  Widget build(BuildContext context) {
    final bool showFab = user.role == 'COLLEGE_ADMIN' || user.role == 'CLUB_ADMIN';

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu'
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome', style: TextStyle(fontSize: 12)),
            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}, tooltip: 'Search'),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthBloc>().add(LoggedOut()),
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('ConnectEdu', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
            )
        ),
      ),
      drawer: _buildAppDrawer(context),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeLoaded) {
            final eventCounts = _countUpcomingEventsPerClub(state.upcomingEvents);

            return RefreshIndicator(
              onRefresh: () async => context.read<HomeBloc>().add(LoadHomeData()),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: [
                  _buildBannerSection(context),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(context, 'Clubs', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: state.clubs.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('No clubs found.')))
                        : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: state.clubs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final club = state.clubs[index];
                        final count = eventCounts[club.id] ?? 0;
                        return _buildClubCard(context, club, count, () { // onTap navigates to EventListScreen
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventListScreen(club: club, currentUser: user)));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(context, 'Upcoming Events', () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to All Upcoming Events (Not Implemented)')));
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: state.upcomingEvents.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('No upcoming events found.')))
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: state.upcomingEvents.length,
                      itemBuilder: (context, index) {
                        final event = state.upcomingEvents[index];
                        return _buildEventCard(context, event, () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to Event: ${event.name} (Not Implemented)')));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          if (state is HomeError) {
            return Center( // Error UI with Retry Button
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load data',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () => context.read<HomeBloc>().add(LoadHomeData()),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: showFab ? FloatingActionButton(
        onPressed: () async { // Make the function async
          if (user.role == 'COLLEGE_ADMIN') {
            // 1. Navigate to the ClubEditScreen and provide a new, temporary
            //    ClubListBloc for it to use.
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (ctx) => ClubListBloc(
                    clubRepository: context.read<ClubRepository>(),
                    eventRepository: context.read<EventRepository>(),
                  ),
                  child: const ClubEditScreen(), // Create mode
                ),
              ),
            );

            // 2. When we return, if the result is 'true' (meaning success),
            //    refresh the HomeScreen's data.
            if (result == true && context.mounted) {
              context.read<HomeBloc>().add(LoadHomeData());
            }

          } else if (user.role == 'CLUB_ADMIN') {
            // TODO: Navigate to Create Event Screen (pass managedClubId)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Create Event (Not Implemented)')));
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        tooltip: user.role == 'COLLEGE_ADMIN' ? 'Create Clubs' : 'Create Event', // Updated tooltip
        child: const Icon(Icons.add),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('ConnectEdu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,),),
                const SizedBox(height: 8),
                Text(user.name, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16,),),
                Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14,),),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Clubs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LoggedOut());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context) {
    final List<Widget> banners = [
      _buildBannerCard(context, 'Campus Event Highlights', Colors.purpleAccent.withOpacity(0.7)),
      _buildBannerCard(context, 'Last Hackathon Winners', Colors.lightBlueAccent.withOpacity(0.7)),
      _buildBannerCard(context, 'Upcoming Workshop Ads', Colors.orangeAccent.withOpacity(0.7)),
    ];
    final PageController pageController = PageController(viewportFraction: 0.9, initialPage: 1000);
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: pageController,
        itemCount: banners.length * 2000,
        itemBuilder: (context, index) => banners[index % banners.length],
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, String text, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
            Shadow(blurRadius: 2.0, color: Colors.black26, offset: Offset(1,1))
          ]),
          ),
        ),
      ),
    );
  }

  // --- (THIS IS THE PRIMARY UPDATE) ---
  Widget _buildClubCard(BuildContext context, Club club, int eventCount, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use CachedNetworkImage to load the logoUrl
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
              child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                  ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: club.logoUrl!,
                  fit: BoxFit.cover,
                  width: 40, // Diameter of the CircleAvatar
                  height: 40,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                  errorWidget: (context, url, error) {
                    debugPrint("Error loading club logo ${club.name}: $error");
                    return _buildPlaceholderIcon(context, club.name); // Fallback icon
                  },
                ),
              )
                  : _buildPlaceholderIcon(context, club.name), // Default icon if no logoUrl
            ),
            const Spacer(),
            Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$eventCount Upcoming Event${eventCount != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
  // --- (END OF UPDATE) ---

  // --- (HELPER WIDGET FOR LOGO FALLBACK) ---
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
      size: 20, // Smaller icon for the 20 radius avatar
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }
  // --- (END OF HELPER) ---

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 65.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomNavItem(context, icon: Icons.home_filled, label: 'Home', isSelected: true, onTap: () {}),
            _buildBottomNavItem(context, icon: Icons.explore_outlined, label: 'Clubs', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
            }),
            const SizedBox(width: 48),
            _buildBottomNavItem(context, icon: Icons.notifications_outlined, label: 'Notify', onTap: () {}),
            _buildBottomNavItem(context, icon: Icons.person_outline, label: 'Profile', onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAllTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onSeeAllTap,
          child: Text('See All', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, VoidCallback onTap) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                    event.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container( height: 120, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator()));
                    },
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context, event.name, height: 120),
                  )
                      : _buildPlaceholderImage(context, event.name, height: 120),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('dd').format(event.date), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                        Text(DateFormat('MMM').format(event.date).toUpperCase(), style: const TextStyle(color: Colors.black87, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.location, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper for placeholder image, updated to handle different heights
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

  Widget _buildBottomNavItem(BuildContext context, {required IconData icon, required String label, bool isSelected = false, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).unselectedWidgetColor, size: 26),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).unselectedWidgetColor, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

