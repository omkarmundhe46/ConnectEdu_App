import 'package:bloc/bloc.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'event_list_event.dart';
part 'event_list_state.dart';

class EventListBloc extends Bloc<EventListEvent, EventListState> {
  final EventRepository eventRepository;

  EventListBloc({required this.eventRepository}) : super(EventListInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<FilterEvents>(_onFilterEvents);
    // Register new event handlers
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<UpdateMeetingLink>(_onUpdateMeetingLink);
  }

  List<Event> _filterEvents(List<Event> allEvents, EventFilter filter) {
    if (filter == EventFilter.upcoming) {
      return allEvents.where((event) => event.status == 'UPCOMING').toList();
    } else {
      return allEvents.where((event) => event.status == 'COMPLETED').toList();
    }
  }

  Future<void> _onUpdateMeetingLink(UpdateMeetingLink event, Emitter<EventListState> emit) async {
    final currentState = state is EventListLoaded ? (state as EventListLoaded) : null;
    emit(EventActionInProgress(previousState: currentState));
    try {
      await eventRepository.updateMeetingLink(event.clubId, event.eventId, event.meetingLink);
      emit(const EventActionSuccess('Meeting link updated!'));
      add(LoadEvents(event.clubId)); // Refresh the list
    } catch (e) {
      debugPrint("Error updating meeting link: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);
      emit(EventActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventListState> emit) async {
    EventListLoaded? previousState = state is EventListLoaded ? (state as EventListLoaded) : null;
    if (previousState == null) {
      emit(EventListLoading());
    }
    try {
      final allEvents = await eventRepository.getEventsByClub(event.clubId);
      // Sort events by date, newest first
      allEvents.sort((a, b) => b.date.compareTo(a.date));
      final currentFilter = previousState?.currentFilter ?? EventFilter.upcoming;
      final filteredEvents = _filterEvents(allEvents, currentFilter);

      emit(EventListLoaded(
        allEvents: allEvents,
        filteredEvents: filteredEvents,
        currentFilter: currentFilter,
      ));
    } catch (e) {
      debugPrint("Error loading events: $e");
      emit(EventListError(e.toString().replaceFirst('Exception: ', '')));
      if (previousState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(previousState);
      }
    }
  }

  void _onFilterEvents(FilterEvents event, Emitter<EventListState> emit) {
    if (state is EventListLoaded) {
      final currentState = state as EventListLoaded;
      final filtered = _filterEvents(currentState.allEvents, event.filter);
      emit(currentState.copyWith(
        filteredEvents: filtered,
        currentFilter: event.filter,
      ));
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['validationErrors'] != null && data['validationErrors'] is Map) {
        final errors = data['validationErrors'] as Map<String, dynamic>;
        return errors.values.first ?? 'Validation failed.';
      }
      return data['message'] ?? e.message ?? "An unknown error occurred.";
    } else if (e.response?.statusCode == 403) {
      return "Forbidden: You do not have permission for this action.";
    }
    return e.message ?? "An unknown network error occurred.";
  }

  // --- HANDLERS FOR CRUD ---

  Future<void> _onCreateEvent(CreateEvent event, Emitter<EventListState> emit) async {
    final currentState = state is EventListLoaded ? (state as EventListLoaded) : null;
    emit(EventActionInProgress(previousState: currentState));
    try {
      await eventRepository.createEvent(event.clubId, event.eventData);
      emit(const EventActionSuccess('Event created successfully!'));
      add(LoadEvents(event.clubId)); // Refresh the list
    } catch (e) {
      debugPrint("Error creating event: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);
      emit(EventActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateEvent(UpdateEvent event, Emitter<EventListState> emit) async {
    final currentState = state is EventListLoaded ? (state as EventListLoaded) : null;
    emit(EventActionInProgress(previousState: currentState));
    try {
      await eventRepository.updateEvent(event.clubId, event.eventId, event.eventData);
      emit(const EventActionSuccess('Event updated successfully!'));
      add(LoadEvents(event.clubId));
    } catch (e) {
      debugPrint("Error updating event: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);
      emit(EventActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteEvent(DeleteEvent event, Emitter<EventListState> emit) async {
    final currentState = state is EventListLoaded ? (state as EventListLoaded) : null;
    emit(EventActionInProgress(previousState: currentState));
    try {
      await eventRepository.deleteEvent(event.clubId, event.eventId);
      emit(const EventActionSuccess('Event deleted successfully!'));
      add(LoadEvents(event.clubId));
    } catch (e) {
      debugPrint("Error deleting event: $e");
      String errorMessage = e.toString();
      if (e is DioException) errorMessage = _parseDioError(e);
      emit(EventActionFailure(errorMessage.replaceFirst('Exception: ', '')));
      if (currentState != null) {
        await Future.delayed(const Duration(milliseconds: 50));
        emit(currentState);
      }
    }
  }
}