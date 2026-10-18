import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/crash_reporting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/player_avatar.dart';
import 'edit_profile_screen.dart';

/// Profile tab: account info from Firebase Auth, change password, linked
/// sign-in methods, preferences (stubs), Crashlytics test and sign out.
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

  bool _changingPassword = false;
  bool _linkingGoogle = false;
  bool _sendingVerification = false;
  bool _signingOut = false;

  // Preferences are kept only in memory for now (no Firestore yet).
  bool _darkMode = false;
  bool _notifications = true;

  AuthRepository get _auth => AppScope.of(context).auth;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'edit_profile'),
        builder: (_) => const EditProfileScreen(),
      ),
    );
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    if (_changingPassword || !_passwordFormKey.currentState!.validate()) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _changingPassword = true);
    try {
      await _auth.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      _passwordFormKey.currentState?.reset();
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      showSuccessSnackBar(messenger, 'Password updated');
    } on AuthException catch (error) {
      if (error.requiresRecentLogin && mounted) {
        await _askToSignInAgain(error.message);
      } else {
        showErrorSnackBar(messenger, error.message);
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  /// Firebase asked for a fresh sign-in (`requires-recent-login`).
  Future<void> _askToSignInAgain(String message) async {
    final signOut = await showConfirmDialog(
      context,
      title: 'Please sign in again',
      message: message,
      confirmLabel: 'Sign Out',
    );
    if (signOut && mounted) await _auth.signOut();
  }

  Future<void> _linkGoogle() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _linkingGoogle = true);
    try {
      await _auth.linkGoogle();
      showSuccessSnackBar(
        messenger,
        'Google linked. You can now sign in with either method.',
      );
    } on AuthException catch (error) {
      if (!error.isCancelled) showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _linkingGoogle = false);
    }
  }

  Future<void> _sendVerification() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _auth.currentUser?.email ?? '';
    setState(() => _sendingVerification = true);
    try {
      await _auth.sendEmailVerification();
      showSuccessSnackBar(messenger, 'Confirmation link sent to $email');
    } on AuthException catch (error) {
      showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _sendTestError() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!CrashReporting.isEnabled) {
      showErrorSnackBar(messenger, 'Crashlytics is not available here.');
      return;
    }
    await CrashReporting.sendTestNonFatal();
    showSuccessSnackBar(
      messenger,
      'Test error sent. It appears in Crashlytics in a few minutes.',
    );
  }

  Future<void> _forceCrash() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!CrashReporting.isEnabled) {
      showErrorSnackBar(messenger, 'Crashlytics is not available here.');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Crash the app?',
      message:
          'The app will close immediately. Open it again so the crash report '
          'is uploaded to Firebase Crashlytics.',
      confirmLabel: 'Crash',
    );
    if (confirmed) CrashReporting.forceTestCrash();
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

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _signingOut = true);
    try {
      // AuthGate notices the signed-out user and shows the login screen.
      await _auth.signOut();
      showSuccessSnackBar(messenger, 'You have been signed out');
    } on AuthException catch (error) {
      showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<AppUser?>(
          valueListenable: _auth.user,
          builder: (context, user, _) {
            if (user == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _ProfileCard(user: user, onTap: _editProfile),
                const _SectionLabel('ACCOUNT'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _SettingsRow(
                        title: 'Email',
                        value: user.email,
                        trailing: user.emailVerified
                            ? null
                            : _SmallAction(
                                label: 'Verify',
                                loading: _sendingVerification,
                                onPressed: _sendVerification,
                              ),
                      ),
                      const Divider(),
                      if (user.hasPassword)
                        _buildChangePassword()
                      else
                        const _SettingsRow(
                          title: 'Password',
                          value: 'Not set (Google sign-in)',
                        ),
                      const Divider(),
                      _SettingsRow(
                        title: 'Google sign-in',
                        trailing: user.hasGoogle
                            ? const AppBadge.success('Linked')
                            : _SmallAction(
                                label: 'Link',
                                loading: _linkingGoogle,
                                onPressed: _linkGoogle,
                              ),
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
                      _SettingsRow(
                        title: 'Import Collection',
                        value: 'CSV / BGG',
                      ),
                      Divider(),
                      _SettingsRow(title: 'Export Data', value: 'JSON'),
                    ],
                  ),
                ),
                const _SectionLabel('CRASHLYTICS TEST'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bug_report_outlined),
                        title: const Text(
                          'Send test error',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text('Non-fatal, the app keeps working'),
                        onTap: _sendTestError,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                        ),
                        title: const Text(
                          'Force test crash',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                        subtitle: const Text('Fatal, the app closes'),
                        onTap: _forceCrash,
                      ),
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
                    onPressed: _signingOut ? null : _signOut,
                    child: _signingOut
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Sign Out'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChangePassword() {
    return ExpansionTile(
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
                  enabled: !_changingPassword,
                  validator: Validators.password,
                ),
              ),
              _LabeledField(
                label: 'New Password',
                child: CustomTextField(
                  controller: _newPassword,
                  hint: 'At least 8 characters, letters and numbers',
                  isPassword: true,
                  enabled: !_changingPassword,
                  validator: (value) {
                    final error = Validators.newPassword(value);
                    if (error != null) return error;
                    return value == _currentPassword.text
                        ? 'New password must be different'
                        : null;
                  },
                ),
              ),
              _LabeledField(
                label: 'Confirm New Password',
                child: CustomTextField(
                  controller: _confirmPassword,
                  hint: 'Match new password',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_changingPassword,
                  validator: Validators.confirmPassword(
                    () => _newPassword.text,
                  ),
                  onFieldSubmitted: (_) => _updatePassword(),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Update Password',
                isLoading: _changingPassword,
                onPressed: _updatePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Avatar, name and email; tap to edit the profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              PlayerAvatar(
                name: user.name,
                photoUrl: user.photoUrl,
                color: MockData.you.color,
                size: 52,
                ring: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small orange text button with an inline spinner.
class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return TextButton(onPressed: onPressed, child: Text(label));
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
