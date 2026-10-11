import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';

/// Opens the "Add New Game" sheet; with [initial] it edits that game.
/// Returns the saved game, or null if cancelled.
Future<BoardGame?> showAddGameSheet(
  BuildContext context, {
  BoardGame? initial,
}) {
  return showModalBottomSheet<BoardGame>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => AddGameSheet(initial: initial),
  );
}

class AddGameSheet extends StatefulWidget {
  const AddGameSheet({super.key, this.initial});

  final BoardGame? initial;

  @override
  State<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends State<AddGameSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _genre;
  late final TextEditingController _minPlayers;
  late final TextEditingController _maxPlayers;
  late final TextEditingController _playTime;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final game = widget.initial;
    _title = TextEditingController(text: game?.title);
    _genre = TextEditingController(text: game?.category);
    _minPlayers = TextEditingController(text: '${game?.minPlayers ?? 1}');
    _maxPlayers = TextEditingController(text: '${game?.maxPlayers ?? 5}');
    _playTime = TextEditingController(text: game?.playTimeMinutes.toString());
    _description = TextEditingController(text: game?.description);
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _genre,
      _minPlayers,
      _maxPlayers,
      _playTime,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initial;
    final game = BoardGame(
      title: _title.text.trim(),
      category: _genre.text.trim(),
      minPlayers: int.parse(_minPlayers.text),
      maxPlayers: int.parse(_maxPlayers.text),
      playTimeMinutes: int.parse(_playTime.text),
      rating: initial?.rating ?? 0,
      color:
          initial?.color ??
          MockData.palette[MockData.games.value.length %
              MockData.palette.length],
      description: _description.text.trim(),
    );
    initial == null
        ? MockData.addGame(game)
        : MockData.replaceGame(initial, game);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, game);
    showSuccessSnackBar(
      messenger,
      initial == null ? 'Game added' : 'Game updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null ? 'Add New Game' : 'Edit Game',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _CoverPhotoPlaceholder(),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Game Title',
                controller: _title,
                hint: 'e.g. Terraforming Mars',
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Genre',
                controller: _genre,
                hint: 'e.g. Strategy',
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Min Players',
                      controller: _minPlayers,
                      keyboardType: TextInputType.number,
                      validator: Validators.positiveInt,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Max Players',
                      controller: _maxPlayers,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final error = Validators.positiveInt(value);
                        if (error != null) return error;
                        final min = int.tryParse(_minPlayers.text) ?? 0;
                        return int.parse(value!) < min ? 'Less than min' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Play Time (minutes)',
                controller: _playTime,
                hint: 'e.g. 120',
                keyboardType: TextInputType.number,
                validator: Validators.positiveInt,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _description,
                hint: 'Enter game overview, rules summary, etc.',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'SAVE GAME', onPressed: _save),
              const SizedBox(height: 16),
              SecondaryButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed "Upload Cover Photo" box. Picking an image needs the
/// image_picker package, which is not added yet.
class _CoverPhotoPlaceholder extends StatelessWidget {
  const _CoverPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(color: AppColors.inputBorder),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'Upload Cover Photo',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
