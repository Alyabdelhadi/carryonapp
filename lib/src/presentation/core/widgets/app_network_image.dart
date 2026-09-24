import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/services/network/endpoints.dart';
import '../theme/theme.dart';

/// Which upload folder a backend file name lives in.
enum UploadKind {
  categories('categories'),
  services('services'),
  sliders('sliders'),
  selfies('selfies'),
  identities('identities'),
  cities('cities'),
  statuses('statuses');

  const UploadKind(this.folder);

  final String folder;

  String url(String file) => Endpoints.upload(folder, file);
}

/// A cached network image with the app's placeholder and error states.
/// Pass either a full [url] or a backend [file] + [kind].
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    this.url,
    this.file,
    this.kind,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  }) : assert(url != null || (file != null && kind != null));

  final String? url;
  final String? file;
  final UploadKind? kind;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  String get _resolved => url ?? kind!.url(file!);

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: context.color.background.canvas,
      child: Icon(
        fallbackIcon,
        color: context.color.text.muted,
        size: context.dimensions.size.iconLarge,
      ),
    );

    Widget image = CachedNetworkImage(
      imageUrl: _resolved,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) =>
          SizedBox(width: width, height: height, child: placeholder),
      errorWidget: (_, _, _) =>
          SizedBox(width: width, height: height, child: placeholder),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// A round avatar from a selfie file name, falling back to initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.selfie, this.size});

  final String initials;
  final String? selfie;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? context.dimensions.size.touch;
    final radius = BorderRadius.circular(context.dimensions.radius.full);

    if (selfie != null && selfie!.trim().isNotEmpty) {
      return AppNetworkImage(
        file: selfie,
        kind: UploadKind.selfies,
        width: resolvedSize,
        height: resolvedSize,
        borderRadius: radius,
        fallbackIcon: Icons.person_outline_rounded,
      );
    }

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.color.primary.tint,
        borderRadius: radius,
      ),
      child: Text(
        initials,
        style: context.textStyle.label.strong.copyWith(
          color: context.color.primary.strong,
        ),
      ),
    );
  }
}
