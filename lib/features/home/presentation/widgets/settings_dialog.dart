import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/local_storage_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _musicEnabled;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _musicEnabled = AudioService().isMusicEnabled;
    _soundEnabled = AudioService().isSoundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      title: const Text(
        'SETTINGS',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Background Music',
                style: TextStyle(fontWeight: FontWeight.bold)),
            value: _musicEnabled,
            activeThumbColor: AppColors.cyan,
            onChanged: (val) {
              setState(() {
                _musicEnabled = val;
              });
              AudioService().setMusicEnabled(val);
            },
          ),
          SwitchListTile(
            title: const Text('Sound Effects',
                style: TextStyle(fontWeight: FontWeight.bold)),
            value: _soundEnabled,
            activeThumbColor: AppColors.cyan,
            onChanged: (val) {
              setState(() {
                _soundEnabled = val;
              });
              AudioService().setSoundEnabled(val);
            },
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: AudioService.withSound(() => Navigator.pop(context)),
            child: const Text('CLOSE'),
          ),
        ),
      ],
    );
  }
}
