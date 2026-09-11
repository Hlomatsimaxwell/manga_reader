import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// [CachedNetworkImage] that automatically attaches the MangaTown referer
/// header for images hosted on MangaTown's CDNs (fmcdn.mangahere.com,
/// zjcdn.mangahere.org, etc.), which otherwise return 403.
class CachedMangaImage extends StatelessWidget {
  const CachedMangaImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.placeholderFadeInDuration,
    this.fadeInDuration = const Duration(milliseconds: 500),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration? placeholderFadeInDuration;
  final Duration fadeInDuration;

  static const Map<String, String> _mangatownHeaders = {
    'Referer': 'https://www.mangatown.com/',
  };

  bool get _isMangatownHosted {
    final host = Uri.tryParse(imageUrl)?.host ?? '';
    return host.endsWith('mangahere.com') || host.endsWith('mangahere.org');
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: _isMangatownHosted ? _mangatownHeaders : null,
      placeholder: placeholder,
      errorWidget:
          errorWidget ??
          (context, url, error) => Container(
            color: Colors.black26,
            child: const Icon(Icons.menu_book_outlined, color: Colors.white38),
          ),
      placeholderFadeInDuration: placeholderFadeInDuration,
      fadeInDuration: fadeInDuration,
    );
  }
}