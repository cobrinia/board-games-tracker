import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/validators.dart';
import 'player_avatar.dart';

/// Ready-made avatars with fixed HTTPS links (DiceBear PNG avatars).
/// Uploading own files to storage comes in Lab 6.
const List<String> presetAvatarUrls = [
  'https://api.dicebear.com/9.x/adventurer/png?seed=Meeple&size=256',
  'https://api.dicebear.com/9.x/adventurer/png?seed=Dice&size=256',
  'https://api.dicebear.com/9.x/bottts/png?seed=Catan&size=256',
  'https://api.dicebear.com/9.x/fun-emoji/png?seed=Pawn&size=256',
  'https://api.dicebear.com/9.x/pixel-art/png?seed=Knight&size=256',
  'https://api.dicebear.com/9.x/thumbs/png?seed=Token&size=256',
];

/// "Change profile photo" dialog: pick a preset avatar or paste your own
/// https:// image link and preview it. Returns the chosen URL, or null if
/// cancelled.
Future<String?> showAvatarPickerDialog(
  BuildContext context, {
  required String name,
  required Color color,
  String? currentUrl,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _AvatarPickerDialog(name: name, color: color, currentUrl: currentUrl),
  );
}

class _AvatarPickerDialog extends StatefulWidget {
  const _AvatarPickerDialog({
    required this.name,
    required this.color,
    this.currentUrl,
  });

  final String name;
  final Color color;
  final String? currentUrl;

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

enum _LinkStatus { none, checking, ok, failed }

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  final _linkFormKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  String? _selected;
  _LinkStatus _linkStatus = _LinkStatus.none;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUrl;
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  /// Validates the link, then tries to download the image before using it.
  Future<void> _previewLink() async {
    if (!_linkFormKey.currentState!.validate()) return;
    final url = _linkController.text.trim();
    setState(() => _linkStatus = _LinkStatus.checking);
    final loaded = await _canLoadImage(url);
    if (!mounted) return;
    setState(() {
      _linkStatus = loaded ? _LinkStatus.ok : _LinkStatus.failed;
      if (loaded) _selected = url;
    });
  }

  static Future<bool> _canLoadImage(String url) {
    final completer = Completer<bool>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!completer.isCompleted) completer.complete(true);
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete(false);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final changed = _selected != null && _selected != widget.currentUrl;

    return AlertDialog(
      title: const Text('Change profile photo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              name: widget.name,
              color: widget.color,
              photoUrl: _selected,
              size: 80,
              ring: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final (index, url) in presetAvatarUrls.indexed)
                  _PresetAvatar(
                    url: url,
                    index: index + 1,
                    selected: url == _selected,
                    onTap: () => setState(() => _selected = url),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _linkFormKey,
              child: TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                validator: Validators.httpsUrl,
                onFieldSubmitted: (_) => _previewLink(),
                onChanged: (_) {
                  if (_linkStatus != _LinkStatus.none) {
                    setState(() => _linkStatus = _LinkStatus.none);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Or paste an image link',
                  hintText: 'https://...',
                  suffixIcon: _linkStatus == _LinkStatus.checking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Preview',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: _previewLink,
                        ),
                  errorText: _linkStatus == _LinkStatus.failed
                      ? 'Could not load an image from this link'
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Disabled until a different photo is chosen.
          onPressed: changed ? () => Navigator.pop(context, _selected) : null,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

/// Round preset avatar; orange ring when selected.
class _PresetAvatar extends StatelessWidget {
  const _PresetAvatar({
    required this.url,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avatar $index',
      selected: selected,
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            foregroundImage: NetworkImage(url),
            onForegroundImageError: (_, _) {},
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
