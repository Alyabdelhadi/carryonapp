import 'package:flutter/material.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// Where an identity file comes from.
enum DocumentSource { camera, gallery, file }

/// Chooser for the identity photos: camera, photo library and — when
/// [allowFiles] — any image or PDF from the Files app. Pops with the chosen
/// [DocumentSource], or null when dismissed.
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({
    super.key,
    required this.title,
    this.allowFiles = false,
  });

  final String title;
  final bool allowFiles;

  static Future<DocumentSource?> show(
    BuildContext context, {
    required String title,
    bool allowFiles = false,
  }) {
    return showModalBottomSheet<DocumentSource>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: context.color.background.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.radius.extraLarge),
        ),
      ),
      builder: (_) => ImageSourceSheet(title: title, allowFiles: allowFiles),
    );
  }

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.s16),
            child: HeadingLevel3Text(title, textAlign: TextAlign.center),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.authTakePhoto),
            onTap: () => Navigator.of(context).pop(DocumentSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.authChooseFromGallery),
            onTap: () => Navigator.of(context).pop(DocumentSource.gallery),
          ),
          if (allowFiles)
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: Text(l10n.authChooseFile),
              subtitle: Text(l10n.authAnyImageOrPdf),
              onTap: () => Navigator.of(context).pop(DocumentSource.file),
            ),
        ],
      ),
    );
  }
}
