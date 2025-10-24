
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Dio to handle DioExceptions

part 'club_list_event.dart';
part 'club_list_state.dart';

class ClubListBloc extends Bloc<ClubListEvent, ClubListState> {
  final ClubRepository clubRepository;
  final EventRepository eventRepository;

  ClubListBloc({required this.clubRepository, required this.eventRepository}) : super(ClubListInitial()) {
    // Register handlers for each event type
    on<LoadClubsAndEvents>(_onLoadClubsAndEvents);
    on<CreateClub>(_onCreateClub);
    on<UpdateClub>(_onUpdateClub);
    on<DeleteClub>(_onDeleteClub);
  }

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

  // Handler for loading/refreshing clubs and event counts
  Future<void> _onLoadClubsAndEvents(LoadClubsAndEvents event, Emitter<ClubListState> emit) async {
    final bool isRefresh = state is ClubListLoaded;
    if (!isRefresh) {
      emit(ClubListLoading());
    }

    try {
      // Fetch clubs and upcoming events concurrently for efficiency
      final results = await Future.wait([
        clubRepository.getAllClubs(),
        eventRepository.getAllUpcomingEvents(), // Fetch only upcoming for count display
      ]);

      final List<Club> clubs = results[0] as List<Club>;
      final List<Event> upcomingEvents = results[1] as List<Event>;

      // Calculate counts based on fetched upcoming events
      final eventCounts = _countUpcomingEventsPerClub(upcomingEvents);

      emit(ClubListLoaded(clubs: clubs, eventCounts: eventCounts));
    } catch (e) {
      debugPrint("Error loading clubs/events: $e");
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      // If data was already loaded (refresh error), emit special error state
      if (isRefresh) {
        emit(ClubListError(errorMessage, isRefreshError: true));
        // Re-emit the previous loaded state so the UI doesn't disappear
        await Future.delayed(const Duration(milliseconds: 50)); // Allow listener to process
        emit(state);
      } else {
        // If initial load failed, just emit the standard error state
        emit(ClubListError(errorMessage));
      }
    }
  }

  // Helper to parse Dio errors into readable messages
  String _parseDioError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['validationErrors'] != null && data['validationErrors'] is Map) {
        final errors = data['validationErrors'] as Map<String, dynamic>;
        return errors.values.first ?? 'Validation failed.';
      } else {
        return data['message'] ?? e.message ?? "An unknown error occurred.";
      }
    } else if (e.response?.statusCode == 403) {
      return "Forbidden: You do not have permission for this action.";
    }
    return e.message ?? "An unknown network error occurred.";
  }

  // Handler for creating a club
  Future<void> _onCreateClub(CreateClub event, Emitter<ClubListState> emit) async {
    final currentState = state is ClubListLoaded ? (state as ClubListLoaded) : null;
    emit(ClubActionInProgress(previousState: currentState));
    try {
      await clubRepository.createClub(event.name, event.description, event.adminEmail, event.logoUrl);
      emit(const ClubActionSuccess('Club created successfully!'));
      add(LoadClubsAndEvents()); // Trigger refresh
    } catch (e) {
      debugPrint("Error creating club: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);

      emit(ClubActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState); // Return to previous loaded state
      }
    }
  }

  // Handler for updating a club
  Future<void> _onUpdateClub(UpdateClub event, Emitter<ClubListState> emit) async {
    final currentState = state is ClubListLoaded ? (state as ClubListLoaded) : null;
    emit(ClubActionInProgress(previousState: currentState));
    try {
      await clubRepository.updateClub(
          event.clubId, event.name, event.description, event.adminEmail, event.logoUrl);
      emit(const ClubActionSuccess('Club updated successfully!'));
      add(LoadClubsAndEvents());
    } catch (e) {
      debugPrint("Error updating club: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);

      emit(ClubActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }

  // Handler for deleting a club
  Future<void> _onDeleteClub(DeleteClub event, Emitter<ClubListState> emit) async {
    final currentState = state is ClubListLoaded ? (state as ClubListLoaded) : null;
    emit(ClubActionInProgress(previousState: currentState));
    try {
      await clubRepository.deleteClub(event.clubId);
      emit(const ClubActionSuccess('Club deleted successfully!'));
      add(LoadClubsAndEvents()); // Trigger refresh
    } catch (e) {
      debugPrint("Error deleting club: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);

      emit(ClubActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }
}

