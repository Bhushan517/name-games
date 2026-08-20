import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/url_launcher_service.dart';

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

  Future<void> _handlePrivacyPolicyTap() async {
    AudioService().playSfx('button_tap.wav');
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    try {
      final success = await UrlLauncherService.launchUrlExternal(uri);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Privacy Policy. Please check your internet connection.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Privacy Policy. Please check your internet connection.',
            ),
          ),
        );
      }
    }
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
            title: const Text(
              'Background Music',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            title: const Text(
              'Sound Effects',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _soundEnabled,
            activeThumbColor: AppColors.cyan,
            onChanged: (val) {
              setState(() {
                _soundEnabled = val;
              });
              AudioService().setSoundEnabled(val);
            },
          ),
          const Divider(color: Colors.white24, height: 16),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.cyan,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: _handlePrivacyPolicyTap,
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
