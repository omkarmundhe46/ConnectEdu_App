import 'package:equatable/equatable.dart';

abstract class EventDetailEvent extends Equatable {
  const EventDetailEvent();
  @override
  List<Object> get props => [];
}

class LoadDetails extends EventDetailEvent {
  final int clubId;
  final int eventId;
  final int userId;

  const LoadDetails({required this.clubId, required this.eventId, required this.userId});
  @override
  List<Object> get props => [clubId, eventId, userId];
}

// Event to be fired after successful registration to refresh status
class RefreshDetails extends EventDetailEvent {}

