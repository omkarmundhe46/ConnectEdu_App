part of 'event_list_bloc.dart';

// Enum for filtering events
enum EventFilter { upcoming, past }

abstract class EventListState extends Equatable {
  const EventListState();
  @override
  List<Object?> get props => [];
}

class EventListInitial extends EventListState {}
class EventListLoading extends EventListState {}

class EventListLoaded extends EventListState {
  final List<Event> allEvents;
  final List<Event> filteredEvents;
  final EventFilter currentFilter;

  const EventListLoaded({
    required this.allEvents,
    required this.filteredEvents,
    this.currentFilter = EventFilter.upcoming,
  });

  @override
  List<Object> get props => [allEvents, filteredEvents, currentFilter];

  EventListLoaded copyWith({
    List<Event>? allEvents,
    List<Event>? filteredEvents,
    EventFilter? currentFilter,
  }) {
    return EventListLoaded(
      allEvents: allEvents ?? this.allEvents,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class EventListError extends EventListState {
  final String message;
  const EventListError(this.message);
  @override
  List<Object> get props => [message];
}

// --- ADD NEW STATES FOR ACTIONS ---
class EventActionInProgress extends EventListState {
  final EventListLoaded? previousState;
  const EventActionInProgress({this.previousState});
  @override
  List<Object?> get props => [previousState];
}

class EventActionSuccess extends EventListState {
  final String message;
  const EventActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class EventActionFailure extends EventListState {
  final String error;
  const EventActionFailure(this.error);
  @override
  List<Object> get props => [error];
}