import 'package:bloc/bloc.dart';
import 'package:connectedu_app/bloc/event_detail_event.dart';
import 'package:connectedu_app/bloc/event_detail_state.dart';
import 'package:connectedu_app/dto/participant_response_dto.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:flutter/foundation.dart';

class EventDetailBloc extends Bloc<EventDetailEvent, EventDetailState> {
  final ClubRepository clubRepository;
  final EventRepository eventRepository;

  EventDetailBloc({required this.clubRepository, required this.eventRepository}) : super(EventDetailInitial()) {
    on<LoadDetails>(_onLoadDetails);
    on<RefreshDetails>(_onRefreshDetails);
  }

  Future<void> _onLoadDetails(LoadDetails event, Emitter<EventDetailState> emit) async {
    emit(EventDetailLoading());
    try {
      // Run both checks at the same time
      final results = await Future.wait([
        clubRepository.isMember(event.clubId, event.userId),
        eventRepository.getEventParticipants(event.clubId, event.eventId),
      ]);

      final bool isClubMember = results[0] as bool;
      // This is now a List<ParticipantResponseDto>
      final List<ParticipantResponseDto> participants = results[1] as List<ParticipantResponseDto>;

      // Check if the current user is in the participant list
      final bool isRegistered = participants.any((p) => p.userId == event.userId);

      emit(EventDetailLoaded(
        isClubMember: isClubMember,
        isRegistered: isRegistered,
        participants: participants,
      ));
    } catch (e) {
      debugPrint("Error loading event details: $e");
      emit(EventDetailError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRefreshDetails(RefreshDetails event, Emitter<EventDetailState> emit) async {
    // Re-emit the loaded state with isRegistered = true, without new API calls
    if (state is EventDetailLoaded) {
      final currentState = state as EventDetailLoaded;
      emit(EventDetailLoaded(
        isClubMember: currentState.isClubMember,
        isRegistered: true, // Manually set to true after successful registration
        participants: currentState.participants, // Participant list will be stale, but button is correct
      ));
    }
  }
}

