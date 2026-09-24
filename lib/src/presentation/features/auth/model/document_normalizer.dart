import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// What the signup form ends up sending: a JPEG photo or a PDF document.
enum DocumentKind { image, pdf }

/// A picked identity file, already in a format the backend and Shufti
/// accept.
class PickedDocument {
  const PickedDocument({
    required this.path,
    required this.name,
    required this.kind,
  });

  final String path;
  final String name;
  final DocumentKind kind;

  bool get isPdf => kind == DocumentKind.pdf;
}

/// Turns whatever the user picked into a JPEG (or leaves a PDF alone).
///
/// iPhones shoot HEIC by default and Android phones increasingly do too;
/// Shufti only reads JPEG, PNG and PDF, and the backend's image processing
/// skips formats it cannot decode. The native compressor decodes HEIC /
/// HEIF / WebP / PNG and re-encodes as JPEG, downscaled so uploads stay
/// small. When conversion fails the original file is kept, so an unusual
/// format still gets sent rather than blocking the signup.
abstract final class DocumentNormalizer {
  static const _maxSide = 1600;
  static const _quality = 85;

  static const _pdfExtensions = {'pdf'};
  static const _passthroughExtensions = {'jpg', 'jpeg'};

  static Future<PickedDocument> normalize(String sourcePath) async {
    final extension = _extensionOf(sourcePath);
    final baseName = _baseNameOf(sourcePath);

    if (_pdfExtensions.contains(extension)) {
      return PickedDocument(
        path: sourcePath,
        name: baseName,
        kind: DocumentKind.pdf,
      );
    }

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/carryon_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        target,
        quality: _quality,
        minWidth: _maxSide,
        minHeight: _maxSide,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (result != null && await File(result.path).length() > 0) {
        return PickedDocument(
          path: result.path,
          name: '${_stripExtension(baseName)}.jpg',
          kind: DocumentKind.image,
        );
      }
    } on Object {
      // Fall through and keep the original.
    }

    return PickedDocument(
      path: sourcePath,
      name: _passthroughExtensions.contains(extension)
          ? baseName
          : '${_stripExtension(baseName)}.$extension',
      kind: DocumentKind.image,
    );
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  static String _baseNameOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }

  static String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }
}
