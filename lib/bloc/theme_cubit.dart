import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SecureStorageService _storage;

  ThemeCubit(this._storage) : super(ThemeMode.system) {
    _loadTheme();
  }

  // Load saved theme from storage on startup
  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read('theme_mode');
    if (savedTheme == 'light') {
      emit(ThemeMode.light);
    } else if (savedTheme == 'dark') {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.system);
    }
  }

  // Update theme and save preference
  Future<void> updateTheme(ThemeMode mode) async {
    emit(mode); // Update UI immediately

    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';

    await _storage.write('theme_mode', value);
  }
}