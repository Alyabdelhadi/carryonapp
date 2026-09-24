import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';
import '../model/document_normalizer.dart';
import 'image_source_sheet.dart';

/// One of the two identity files on the signup form (selfie, ID). Empty it
/// invites a pick; filled it previews the file with a remove button.
///
/// Every picked image is normalised to JPEG (HEIC, HEIF, WebP, PNG all
/// convert) and the ID may also be a PDF when [allowPdf] is set.
class DocumentUploadTile extends StatefulWidget {
  const DocumentUploadTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onChanged,
    this.preferFrontCamera = false,
    this.allowPdf = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final PickedDocument? file;
  final ValueChanged<PickedDocument?> onChanged;
  final bool preferFrontCamera;
  final bool allowPdf;
  final bool enabled;

  @override
  State<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends State<DocumentUploadTile> {
  static const _fileExtensions = [
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'webp',
    'bmp',
    'gif',
    'tiff',
    'pdf',
  ];

  bool _busy = false;

  Future<void> _pick() async {
    final source = await ImageSourceSheet.show(
      context,
      title: widget.title,
      allowFiles: widget.allowPdf,
    );
    if (source == null || !mounted) return;
    final l10n = context.l10n;

    String? path;
    try {
      switch (source) {
        case DocumentSource.camera:
        case DocumentSource.gallery:
          final picked = await ImagePicker().pickImage(
            source: source == DocumentSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
            preferredCameraDevice: widget.preferFrontCamera
                ? CameraDevice.front
                : CameraDevice.rear,
            requestFullMetadata: false,
          );
          path = picked?.path;
        case DocumentSource.file:
          final picked = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: _fileExtensions,
          );
          path = picked.isEmpty ? null : picked.first.path;
      }
    } on Object {
      if (mounted) {
        AppFeedback.toast(context, l10n.authCouldNotOpenFile);
      }
      return;
    }
    if (path == null || !mounted) return;

    setState(() => _busy = true);
    final normalized = await DocumentNormalizer.normalize(path);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    final picked = widget.file;
    final enabled = widget.enabled && !_busy;

    return Material(
      color: context.color.background.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: picked == null
              ? context.color.border.defaultValue
              : context.color.status.success,
          width: context.dimensions.border.xs,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? _pick : null,
        child: Padding(
          padding: EdgeInsets.all(space.s12),
          child: Row(
            children: [
              _Thumbnail(icon: widget.icon, file: picked, busy: _busy),
              Gap(space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(widget.title),
                    Gap(space.s2),
                    BodySmallText.muted(
                      _busy
                          ? context.l10n.authPreparing
                          : picked == null
                          ? widget.subtitle
                          : picked.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap(space.s8),
              if (picked == null)
                Icon(
                  Icons.arrow_forward_rounded,
                  size: context.dimensions.size.iconMedium,
                )
              else
                IconButton(
                  tooltip: context.l10n.authRemove,
                  icon: const Icon(Icons.cancel_rounded),
                  onPressed: enabled ? () => widget.onChanged(null) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.icon, required this.file, this.busy = false});

  final IconData icon;
  final PickedDocument? file;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final size = context.dimensions.size.control;
    final picked = file;
    final placeholder = ColoredBox(
      color: context.color.primary.tint,
      child: busy
          ? Padding(
              padding: EdgeInsets.all(context.dimensions.space.s12),
              child: const CircularProgressIndicator(),
            )
          : Icon(
              picked?.isPdf ?? false ? Icons.picture_as_pdf_rounded : icon,
              size: context.dimensions.size.iconLarge,
              color: context.color.primary.strong,
            ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.dimensions.radius.small),
      child: SizedBox(
        width: size,
        height: size,
        child: picked == null || picked.isPdf || busy
            ? placeholder
            : Image.file(
                File(picked.path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
