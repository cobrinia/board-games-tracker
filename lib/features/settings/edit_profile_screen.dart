import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/avatar_picker_dialog.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/player_avatar.dart';

/// Edits the display name and profile photo stored in Firebase Auth.
///
/// The form starts with the current values; nothing is sent until the user
/// taps Save, and only fields that actually changed are updated.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late AppUser _user;
  String? _photoUrl;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _user = AppScope.of(context).auth.currentUser!;
    _nameController.text = _user.displayName ?? '';
    _photoUrl = _user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final url = await showAvatarPickerDialog(
      context,
      name: _nameController.text.isEmpty ? _user.name : _nameController.text,
      color: MockData.you.color,
      currentUrl: _photoUrl,
    );
    if (url != null) setState(() => _photoUrl = url);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving || !_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final nameChanged = name != (_user.displayName ?? '');
    final photoChanged = _photoUrl != _user.photoUrl;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!nameChanged && !photoChanged) {
      navigator.pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await AppScope.of(context).auth.updateProfile(
        displayName: nameChanged ? name : null,
        photoUrl: photoChanged ? (_photoUrl ?? '') : null,
      );
      showSuccessSnackBar(messenger, 'Profile updated');
      navigator.pop();
    } on AuthException catch (error) {
      showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Semantics(
                  button: true,
                  label: 'Change profile photo',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _saving ? null : _pickPhoto,
                    child: PlayerAvatar(
                      name: _user.name,
                      photoUrl: _photoUrl,
                      color: MockData.you.color,
                      size: 96,
                      ring: true,
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: _saving ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change Photo'),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Username',
                controller: _nameController,
                textInputAction: TextInputAction.done,
                enabled: !_saving,
                validator: Validators.name,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  helperText: 'The email address cannot be changed here.',
                  enabled: false,
                ),
                child: Text(
                  _user.email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Save Changes',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
