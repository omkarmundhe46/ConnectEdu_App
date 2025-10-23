import 'package:connectedu_app/screens/club_list_screen.dart'; // For "See All" Clubs navigation
import 'package:connectedu_app/screens/event_list_screen.dart'; // For Club Card navigation
import 'package:flutter/material.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Ensure this is imported

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  // Helper function to count upcoming events per club
  Map<int, int> _countUpcomingEventsPerClub(List<Event> events) {
    final Map<int, int> counts = {};
    for (var event in events) {
      // Ensure clubId is not null before using it
      if (event.clubId != null && event.status == 'UPCOMING') { // Count only upcoming
        counts[event.clubId!] = (counts[event.clubId!] ?? 0) + 1;
      }
    }
    return counts;
  }


  @override
  Widget build(BuildContext context) {
    // Determine if the FAB should be shown based on role
    final bool showFab = user.role == 'COLLEGE_ADMIN' || user.role == 'CLUB_ADMIN';

    return Scaffold(
      appBar: AppBar(
        // Updated AppBar based on sketch
        leading: Builder( // Use Builder to get Scaffold context for Drawer
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(), // Open drawer on tap
              tooltip: 'Menu'
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome', style: TextStyle(fontSize: 12)),
            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Display Name
          ],
        ),
        centerTitle: false, // Align title left
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            // TODO: Implement search functionality
          }, tooltip: 'Search'),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthBloc>().add(LoggedOut()),
          ),
        ],
        bottom: PreferredSize( // Add app name below title
            preferredSize: const Size.fromHeight(20.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('ConnectEdu', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
            )
        ),
      ),
      drawer: _buildAppDrawer(context), // Add a Drawer for the menu button
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
            // Calculate upcoming event counts for clubs
            final eventCounts = _countUpcomingEventsPerClub(state.upcomingEvents);

            return RefreshIndicator(
              onRefresh: () async => context.read<HomeBloc>().add(LoadHomeData()),
              child: ListView( // Use ListView for vertical scrolling of sections
                padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding top/bottom only
                children: [
                  // Section 2: Banners (Placeholder)
                  _buildBannerSection(context),
                  const SizedBox(height: 24),

                  // Section 3: Clubs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(context, 'Clubs', () {
                      // Navigate to ClubListScreen on "See All" tap
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120, // Height for the horizontal list
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
                        // Navigate to EventListScreen when tapping a club card
                        return _buildClubCard(context, club, count, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventListScreen(club: club, currentUser: user)));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Upcoming Events
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(context, 'Upcoming Events', () {
                      // TODO: Navigate to a screen showing ALL upcoming events
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
                          // TODO: Navigate to Event Details Screen
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to Event: ${event.name} (Not Implemented)')));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 80), // Padding at the bottom
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
          return const SizedBox.shrink(); // Default empty state
        },
      ),
      floatingActionButton: showFab ? FloatingActionButton(
        onPressed: () {
          if (user.role == 'COLLEGE_ADMIN') {
            // TODO: Navigate to Create Club Screen
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Create Club (Not Implemented)')));
          } else if (user.role == 'CLUB_ADMIN') {
            // TODO: Navigate to Create Event Screen (pass managedClubId)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Create Event (Not Implemented)')));
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        tooltip: user.role == 'COLLEGE_ADMIN' ? 'Create Club' : 'Create Event',
        child: const Icon(Icons.add),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildAppDrawer(BuildContext context) {
    // Basic Drawer implementation
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, // Align content to bottom
              children: [
                Text(
                  'ConnectEdu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name, // Display user name
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                Text(
                  user.email, // Display user email
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Clubs'), // Changed label
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              // TODO: Navigate to Notifications Screen
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Notifications (Not Implemented)')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              // TODO: Navigate to Profile Screen
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Profile (Not Implemented)')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              context.read<AuthBloc>().add(LoggedOut());
            },
          ),
        ],
      ),
    );
  }


  Widget _buildBannerSection(BuildContext context) {
    // Placeholder using PageView
    final List<Widget> banners = [
      _buildBannerCard(context, 'Campus Event Highlights', Colors.purpleAccent.withOpacity(0.7)),
      _buildBannerCard(context, 'Last Hackathon Winners', Colors.lightBlueAccent.withOpacity(0.7)),
      _buildBannerCard(context, 'Upcoming Workshop Ads', Colors.orangeAccent.withOpacity(0.7)),
    ];

    // Added Auto-scroll functionality (Optional)
    final PageController _pageController = PageController(viewportFraction: 0.9, initialPage: 1000); // Start far for infinite feel
    // You could use a Timer here to auto-scroll if desired

    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        // itemCount: null, // For infinite scroll (requires more logic)
        itemCount: banners.length * 2000, // Simulate infinite scroll
        itemBuilder: (context, index) => banners[index % banners.length], // Loop through banners
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, String text, Color color) {
    // Banner card UI
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
              Shadow(blurRadius: 2.0, color: Colors.black26, offset: Offset(1,1))
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Club club, int eventCount, VoidCallback onTap) {
    // Club card UI
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
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                  club.name.toLowerCase().contains('code') || club.name.toLowerCase().contains('tech') ? Icons.code
                      : club.name.toLowerCase().contains('sport') ? Icons.sports_basketball
                      : club.name.toLowerCase().contains('music') ? Icons.music_note
                      : Icons.groups,
                  color: Theme.of(context).colorScheme.onPrimaryContainer
              ),
            ),
            const Spacer(),
            Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$eventCount Upcoming Event${eventCount != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, VoidCallback onTap) {
    // Event card UI
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
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context, event.name),
                  )
                      : _buildPlaceholderImage(context, event.name),
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

  // Helper for placeholder image
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

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAllTap) {
    // Section Header UI
    return Row( /* ... */ );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    // Updated BottomAppBar matching the sketch
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
            _buildBottomNavItem(context, icon: Icons.explore_outlined, label: 'Clubs', onTap: () { // Updated label
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubListScreen(currentUser: user)));
            }),
            const SizedBox(width: 48), // Space for FAB
            _buildBottomNavItem(context, icon: Icons.notifications_outlined, label: 'Notify', onTap: () {}),
            _buildBottomNavItem(context, icon: Icons.person_outline, label: 'Profile', onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context, {required IconData icon, required String label, bool isSelected = false, required VoidCallback onTap}) {
    // Bottom Nav Item UI
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

