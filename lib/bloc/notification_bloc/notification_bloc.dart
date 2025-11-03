import 'package:bloc/bloc.dart';
import 'package:connectedu_app/models/notification_log.dart';
import 'package:connectedu_app/repositories/notification_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event,
      Emitter<NotificationState> emit,
      ) async {
    emit(NotificationLoading());
    try {
      final notifications = await notificationRepository.getMyNotifications();
      emit(NotificationLoaded(notifications));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      emit(NotificationError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}