part of 'event_list_bloc.dart';

abstract class EventListEvent extends Equatable {
  const EventListEvent();

  @override
  List<Object> get props => [];
}

class LoadEvents extends EventListEvent {
  final int clubId;

  const LoadEvents(this.clubId);

  @override
  List<Object> get props => [clubId];
}

// --- ADD THIS NEW EVENT ---
class FilterEvents extends EventListEvent {
  final EventFilter filter;
  const FilterEvents(this.filter);
  @override
  List<Object> get props => [filter];
}