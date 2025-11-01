import 'package:connectedu_app/dto/participant_response_dto.dart';
import 'package:equatable/equatable.dart';

abstract class EventDetailState extends Equatable {
  const EventDetailState();
  @override
  List<Object> get props => [];
}

class EventDetailInitial extends EventDetailState {}

class EventDetailLoading extends EventDetailState {}

class EventDetailLoaded extends EventDetailState {
  final bool isClubMember;
  final bool isRegistered;
  final List<ParticipantResponseDto> participants;

  const EventDetailLoaded({
    required this.isClubMember,
    required this.isRegistered,
    required this.participants,
  });

  @override
  List<Object> get props => [isClubMember, isRegistered, participants];
}

class EventDetailError extends EventDetailState {
  final String message;
  const EventDetailError(this.message);
  @override
  List<Object> get props => [message];
}

