import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/change_photo_dialog.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/player_avatar.dart';
import '../auth/login_screen.dart';

/// Profile tab: account info, change password, preferences, data, sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Preferences are kept only in memory for now.
  bool _darkMode = false;
  bool _notifications = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _editProfile() async {
    final you = MockData.you;
    final source = await showChangePhotoDialog(
      context,
      name: you.name,
      color: you.color,
    );
    if (source != null && mounted) {
      showSuccessSnackBar(ScaffoldMessenger.of(context), 'Profile updated');
    }
  }

  void _updatePassword() {
    if (!_passwordFormKey.currentState!.validate()) return;
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    FocusScope.of(context).unfocus();
    showSuccessSnackBar(ScaffoldMessenger.of(context), 'Password updated');
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign Out?',
      message:
          'Are you sure you want to sign out of GameShelf? Your synced '
          'collection will remain safe in the cloud.',
      confirmLabel: 'Sign Out',
    );
    if (!confirmed || !mounted) return;
    // Clear the whole stack so Back cannot return into the signed-in app.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final you = MockData.you;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _editProfile,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        name: you.name,
                        color: you.color,
                        size: 52,
                        ring: true,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            you.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _SectionLabel('ACCOUNT'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const _SettingsRow(title: 'Email', value: MockData.userEmail),
                  const Divider(),
                  ExpansionTile(
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Form(
                        key: _passwordFormKey,
                        child: Column(
                          children: [
                            _LabeledField(
                              label: 'Current Password',
                              child: CustomTextField(
                                controller: _currentPassword,
                                hint: 'Current password',
                                isPassword: true,
                                validator: Validators.password,
                              ),
                            ),
                            _LabeledField(
                              label: 'New Password',
                              child: CustomTextField(
                                controller: _newPassword,
                                hint: 'At least 8 characters',
                                isPassword: true,
                                validator: Validators.password,
                              ),
                            ),
                            _LabeledField(
                              label: 'Confirm New Password',
                              child: CustomTextField(
                                controller: _confirmPassword,
                                hint: 'Match new password',
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                validator: (value) => value == _newPassword.text
                                    ? null
                                    : 'Passwords do not match',
                              ),
                            ),
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: 'Update Password',
                              onPressed: _updatePassword,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const _SettingsRow(
                    title: 'Linked Accounts',
                    value: 'BoardGameGeek',
                  ),
                ],
              ),
            ),
            const _SectionLabel('PREFERENCES'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                  const Divider(),
                  const _SettingsRow(title: 'Language', value: 'English'),
                ],
              ),
            ),
            const _SectionLabel('DATA'),
            const Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _SettingsRow(
                    title: 'Sync Status',
                    trailing: AppBadge.success('Synced'),
                  ),
                  Divider(),
                  _SettingsRow(title: 'Import Collection', value: 'CSV / BGG'),
                  Divider(),
                  _SettingsRow(title: 'Export Data', value: 'JSON'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dangerLight,
                  foregroundColor: AppColors.danger,
                ),
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// "Title ........ value" row inside a settings card.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, this.value, this.trailing});

  final String title;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    Text(
                      value ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orange label above a field (Settings style).
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
