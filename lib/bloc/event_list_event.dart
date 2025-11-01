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

// --- ADD NEW EVENTS ---
class CreateEvent extends EventListEvent {
  final int clubId;
  final Map<String, dynamic> eventData;
  const CreateEvent({required this.clubId, required this.eventData});
  @override
  List<Object> get props => [clubId, eventData];
}

class UpdateEvent extends EventListEvent {
  final int clubId;
  final int eventId;
  final Map<String, dynamic> eventData;
  const UpdateEvent({required this.clubId, required this.eventId, required this.eventData});
  @override
  List<Object> get props => [clubId, eventId, eventData];
}

class DeleteEvent extends EventListEvent {
  final int clubId;
  final int eventId;
  const DeleteEvent({required this.clubId, required this.eventId});
  @override
  List<Object> get props => [clubId, eventId];
}