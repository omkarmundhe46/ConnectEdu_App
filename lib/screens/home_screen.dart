import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/bloc/event_list_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/bloc/notification_bloc/notification_bloc.dart';
import 'package:connectedu_app/models/banner_model.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/banner_repository.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/repositories/notification_repository.dart';
import 'package:connectedu_app/screens/AllUpcomingEventsScreen.dart';
import 'package:connectedu_app/screens/ManageBannersScreen.dart';
import 'package:connectedu_app/screens/club_edit_screen.dart';
import 'package:connectedu_app/screens/club_list_screen.dart';
import 'package:connectedu_app/screens/event_details_screen.dart';
import 'package:connectedu_app/screens/event_edit_screen.dart';
import 'package:connectedu_app/screens/event_list_screen.dart';
import 'package:connectedu_app/screens/global_search_delegate.dart';
import 'package:connectedu_app/screens/my_registrations.dart';
import 'package:connectedu_app/screens/notification_screen.dart';
import 'package:connectedu_app/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

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
    // Logic to determine user roles
    final bool isCollegeAdmin = user.role == 'COLLEGE_ADMIN';
    final bool isClubAdmin = user.role == 'CLUB_ADMIN';
    final bool isStudent = user.role == 'USER' || user.role == 'CLUB_MEMBER';

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
          if (isCollegeAdmin)
            IconButton(
              icon: const Icon(Icons.campaign),
              tooltip: 'Manage Banners',
              onPressed: () {
                // Navigate to ManageBannersScreen in College Admin mode (clubId: null)
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBannersScreen(clubId: null)));
              },
            ),

          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  clubRepository: context.read<ClubRepository>(),
                  eventRepository: context.read<EventRepository>(),
                  currentUser: user,
                ),
              );
            },
          ),

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
                        return _buildClubCard(context, club, count, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventListScreen(club: club, currentUser: user)));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(context, 'Upcoming Events', () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllUpcomingEventsScreen())
                      );
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
                        final club = state.clubs.firstWhere(
                              (c) => c.id == event.clubId,
                          orElse: () => Club(id: event.clubId ?? 0, name: "Unknown Club", description: "", adminId: 0, logoUrl: null, category: 'ALL'),
                        );
                        return _buildEventCard(context, event, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                club: club,
                                event: event,
                                currentUser: user,
                              ),
                            ),
                          );
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
            return Center(
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

      // --- UPDATED FLOATING ACTION BUTTON LOGIC ---
      floatingActionButton: _buildFloatingActionButton(context, isCollegeAdmin, isClubAdmin, isStudent),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- NEW HELPER METHOD FOR FAB ---
  Widget? _buildFloatingActionButton(BuildContext context, bool isCollegeAdmin, bool isClubAdmin, bool isStudent) {
    if (isCollegeAdmin) {
      // College Admin: Create Club
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (ctx) => ClubListBloc(
                  clubRepository: context.read<ClubRepository>(),
                  eventRepository: context.read<EventRepository>(),
                ),
                child: const ClubEditScreen(),
              ),
            ),
          );
          if (result == true && context.mounted) {
            context.read<HomeBloc>().add(LoadHomeData());
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        tooltip: 'Create Club',
        child: const Icon(Icons.add),
      );
    } else if (isClubAdmin) {
      // Club Admin: Create Event
      return FloatingActionButton(
        onPressed: () async {
          final homeState = context.read<HomeBloc>().state;
          Club? managedClub;
          if (homeState is HomeLoaded && user.managedClubId != null) {
            try {
              managedClub = homeState.clubs.firstWhere((c) => c.id == user.managedClubId);
            } catch (e) {
              debugPrint("Managed club not found in HomeBloc state");
            }
          }

          if (managedClub != null && context.mounted) {
            final Club club = managedClub;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (ctx) => EventListBloc(
                    eventRepository: context.read<EventRepository>(),
                  ),
                  child: EventEditScreen(club: club),
                ),
              ),
            );

            if (result == true && context.mounted) {
              context.read<HomeBloc>().add(LoadHomeData());
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not find your managed club to create an event.'), backgroundColor: Colors.orange)
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      );
    } else if (isStudent) {
      // Student: My Registrations Shortcut
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRegistrationsScreen())
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'My Registrations',
        child: const Icon(Icons.confirmation_number_outlined),
      );
    }
    return null;
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
            onTap: () {
              Navigator.pop(context);
              // Already on Home, maybe refresh?
            },
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
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  BlocProvider(
                    create: (ctx) => NotificationBloc(
                        notificationRepository: ctx.read<NotificationRepository>()
                    )..add(LoadNotifications()),
                    child: const NotificationScreen(),
                  )
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: user)));
            },
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
    return FutureBuilder<List<BannerModel>>(
      future: context.read<BannerRepository>().getActiveBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          // Show a default placeholder if no banners exist
          return _buildBannerCard(context, 'Welcome to ConnectEdu', Colors.purpleAccent.withOpacity(0.7));
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
          ),
          items: banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return InkWell(
                  onTap: () async {
                    if (banner.linkUrl != null) {
                      final Uri url = Uri.parse(banner.linkUrl!);
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(banner.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container( // Gradient overlay for text readability
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        banner.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
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
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
              child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                  ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: club.logoUrl!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                  errorWidget: (context, url, error) {
                    debugPrint("Error loading club logo ${club.name}: $error");
                    return _buildPlaceholderIcon(context, club.name);
                  },
                ),
              )
                  : _buildPlaceholderIcon(context, club.name),
            ),
            const Spacer(),
            Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$eventCount Upcoming Event${eventCount != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
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
      size: 20,
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }

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
            _buildBottomNavItem(context, icon: Icons.notifications_outlined, label: 'Notify', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  BlocProvider(
                    create: (ctx) => NotificationBloc(
                        notificationRepository: ctx.read<NotificationRepository>()
                    )..add(LoadNotifications()),
                    child: const NotificationScreen(),
                  )
              ));
            }),
            _buildBottomNavItem(context, icon: Icons.person_outline, label: 'Profile', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: user)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onTap,
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