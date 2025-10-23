part of 'event_list_bloc.dart';

enum EventFilter { upcoming, past, all }

abstract class EventListState extends Equatable {
  const EventListState();

  @override
  List<Object> get props => [];
}

class EventListInitial extends EventListState {}

class EventListLoading extends EventListState {}

class EventListLoaded extends EventListState {
  final List<Event> allEvents;
  final EventFilter currentFilter;

  const EventListLoaded({
    required this.allEvents,
    this.currentFilter = EventFilter.upcoming, // Default to upcoming
  });

  // Helper to get filtered events
  List<Event> get filteredEvents {
    if (currentFilter == EventFilter.past) {
      return allEvents.where((event) => event.status == 'COMPLETED').toList();
    } else if (currentFilter == EventFilter.upcoming) {
      return allEvents.where((event) => event.status == 'UPCOMING').toList();
    }
    return allEvents; // Default or 'all'
  }

  EventListLoaded copyWith({
    List<Event>? allEvents,
    EventFilter? currentFilter,
  }) {
    return EventListLoaded(
      allEvents: allEvents ?? this.allEvents,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }


  @override
  List<Object> get props => [allEvents, currentFilter];
}

class EventListError extends EventListState {
  final String message;

  const EventListError(this.message);

  @override
  List<Object> get props => [message];
}
