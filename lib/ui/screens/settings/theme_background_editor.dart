import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/paths.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../services/theme/background_image.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/color_picker.dart';
import 'theme_labels.dart';
import '../../widgets/segmented_blocks.dart';
import '../../widgets/show_msg.dart';

/// The «Sfondo delle pagine» part of the theme editor: plain colour, gradient
/// or a picture, and whether Now playing keeps the tint of the cover.
class ThemeBackgroundEditor extends StatefulWidget {
  const ThemeBackgroundEditor({
    super.key,
    required this.themeId,
    required this.colors,
    required this.background,
    required this.recent,
    required this.onChanged,
    this.pickImage,
    this.imageDir,
  });

  final String themeId;
  final CcColors colors;
  final ThemeBackground background;
  final List<Color> recent;
  final ValueChanged<ThemeBackground> onChanged;

  /// Asks the user for a picture file; the file picker by default (tests give
  /// their own).
  final Future<File?> Function()? pickImage;

  /// Where pictures are kept (the app's theme folder by default).
  final Future<Directory> Function()? imageDir;

  @override
  State<ThemeBackgroundEditor> createState() => _ThemeBackgroundEditorState();
}

class _ThemeBackgroundEditorState extends State<ThemeBackgroundEditor> {
  bool _endOpen = false;
  bool _busy = false;

  ThemeBackground get _b => widget.background;

  Future<File?> _defaultPick() async {
    final res = await FilePicker.pickFiles(type: FileType.image);
    final path = res.isEmpty ? null : res.first.path;
    return path == null ? null : File(path);
  }

  Future<void> _pick() async {
    final l = context.l10n;
    final file = await (widget.pickImage ?? _defaultPick)();
    if (file == null) return;
    setState(() => _busy = true);
    final path = await importBackgroundImage(file, await (widget.imageDir ?? themeDir)(), widget.themeId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (path == null) {
      showMsg(context, l.bgImageFailed);
      return;
    }
    widget.onChanged(_b.copyWith(kind: ThemeBackgroundKind.image, imagePath: path));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final text = Theme.of(context).textTheme;
    final end = _b.gradientEnd ?? widget.colors.heroBase;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.themeBackground, style: text.titleSmall),
        const SizedBox(height: 8),
        SegmentedBlocks<ThemeBackgroundKind>(
          items: [
            BlockItem(value: ThemeBackgroundKind.solid, icon: Icons.format_color_fill, label: l.bgSolid),
            BlockItem(value: ThemeBackgroundKind.gradient, icon: Icons.gradient, label: l.bgGradient),
            BlockItem(value: ThemeBackgroundKind.image, icon: Icons.image_outlined, label: l.bgImage),
          ],
          selected: _b.kind,
          onChanged: (kind) {
            widget.onChanged(
              kind == ThemeBackgroundKind.gradient && _b.gradientEnd == null
                  ? _b.copyWith(kind: kind, gradientEnd: widget.colors.heroBase)
                  : _b.copyWith(kind: kind),
            );
          },
        ),
        if (_b.kind == ThemeBackgroundKind.gradient) ...[
          ListTile(
            key: const ValueKey('bg-gradient-end'),
            contentPadding: EdgeInsets.zero,
            onTap: () => setState(() => _endOpen = !_endOpen),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: end,
                shape: BoxShape.circle,
                border: Border.all(color: cc.textFaint),
              ),
            ),
            title: Text(l.bgGradientEnd),
            subtitle: Text(colorToHex(end)),
            trailing: Icon(_endOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
          ),
          if (_endOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: CcDims.gap8),
              child: CcColorPicker(
                color: end,
                recent: widget.recent,
                labels: pickerLabels(l),
                onChanged: (c) => widget.onChanged(_b.copyWith(gradientEnd: c)),
              ),
            ),
          _SliderRow(
            label: l.bgAngle,
            value: _b.angle,
            min: 0,
            max: 360,
            divisions: 24,
            shown: '${_b.angle.round()}°',
            onChanged: (v) => widget.onChanged(_b.copyWith(angle: v)),
          ),
        ],
        if (_b.kind == ThemeBackgroundKind.image) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pick,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(l.bgPickImage),
              ),
              if (_b.imagePath != null)
                TextButton(
                  onPressed: _busy ? null : () => widget.onChanged(_b.copyWith(clearImage: true)),
                  child: Text(l.bgRemoveImage),
                ),
            ],
          ),
          if (_b.imagePath != null) ...[
            _SliderRow(
              label: l.bgDim,
              value: _b.dim,
              min: 0,
              max: 0.8,
              divisions: 16,
              shown: '${(_b.dim * 100).round()}%',
              onChanged: (v) => widget.onChanged(_b.copyWith(dim: v)),
            ),
            _SliderRow(
              label: l.bgBlur,
              value: _b.blur,
              min: 0,
              max: 20,
              divisions: 20,
              shown: _b.blur.round().toString(),
              onChanged: (v) => widget.onChanged(_b.copyWith(blur: v)),
            ),
          ],
        ],
        if (_b.kind != ThemeBackgroundKind.solid)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.bgCoverBackdrop),
            value: _b.coverBackdrop,
            onChanged: (v) => widget.onChanged(_b.copyWith(coverBackdrop: v)),
          ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.shown,
    required this.onChanged,
  });

  final String label, shown;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            semanticFormatterCallback: (_) => shown,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 44, child: Text(shown, textAlign: TextAlign.end)),
      ],
    );
  }
}
