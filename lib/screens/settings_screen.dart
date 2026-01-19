import 'package:connectedu_app/bloc/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<ThemeCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildSectionHeader(context, "Appearance"),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text("App Theme"),
            subtitle: Text(_getThemeText(currentTheme)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeDialog(context, currentTheme),
          ),

          const Divider(),
          _buildSectionHeader(context, "About"),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version"),
            subtitle: Text("1.0.0"),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "System Default";
      case ThemeMode.light: return "Light Mode";
      case ThemeMode.dark: return "Dark Mode";
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Theme"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(context, "System Default", ThemeMode.system, currentMode),
            _buildRadioOption(context, "Light Mode", ThemeMode.light, currentMode),
            _buildRadioOption(context, "Dark Mode", ThemeMode.dark, currentMode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(BuildContext context, String title, ThemeMode value, ThemeMode groupValue) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (ThemeMode? newValue) {
        if (newValue != null) {
          context.read<ThemeCubit>().updateTheme(newValue);
          Navigator.pop(context); // Close dialog after selection
        }
      },
    );
  }
}