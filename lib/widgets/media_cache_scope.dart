import 'package:material_ui/material_ui.dart';

import '../services/media_cache_service.dart';

class MediaCacheScope extends InheritedWidget {
  const MediaCacheScope({super.key, required this.cache, required super.child});

  final MediaCacheService cache;

  static MediaCacheService? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MediaCacheScope>()?.cache;
  }

  @override
  bool updateShouldNotify(covariant MediaCacheScope oldWidget) =>
      oldWidget.cache != cache;
}
