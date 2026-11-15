import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/services/media_cache_service.dart';
import 'package:driving_exam/services/media_store.dart';
import 'package:driving_exam/services/media_store_io.dart';
import 'package:flutter_test/flutter_test.dart';

Question _makeMediaQuestion({
  required String id,
  List<String> images = const [],
  List<String> videos = const [],
}) {
  return Question.fromJson({
    'theme_number': 'Theme 1.1.',
    'theme_name': 'Basic Rules',
    'chapter_number': '1.1.01 Chapter',
    'chapter_name': 'Hazards',
    'question_id': id,
    'question_number': id,
    'points': '4 Points',
    'licenses': ['Basic material'],
    'question_text': 'Question $id',
    'options': [
      {'letter': 'A.', 'text': 'Option A'},
      {'letter': 'B.', 'text': 'Option B'},
    ],
    'correct_answers': [
      {'letter': 'A.', 'text': 'Option A'},
    ],
    'comment': 'Comment',
    'local_image_paths': images,
    'local_video_paths': videos,
  });
}

void main() {
  test('maps catalog image and video paths to GitHub raw URLs on go-maxus-go/driving_test', () {
    final cache = MediaCacheService(store: InMemoryMediaStore());
    addTearDown(cache.dispose);

    expect(
      cache.remoteUrlFor('videos/1_1_02-049.mp4'),
      'https://raw.githubusercontent.com/go-maxus-go/driving_test/main/assets/videos/1_1_02-049.mp4',
    );
    expect(
      cache.remoteUrlFor('assets/images/1_1_02-009-B.png'),
      'https://raw.githubusercontent.com/go-maxus-go/driving_test/main/assets/images/1_1_02-009-B.png',
    );
  });

  test('deduplicates concurrent requests and pauses slow background sync while urgent video downloads', () async {
    final requestedUris = <String>[];
    final completers = <String, Completer<Uint8List>>{};
    var autoCompleteRemaining = false;

    final cache = MediaCacheService(
      store: InMemoryMediaStore(),
      enableBackgroundSync: true,
      backgroundStepDelay: const Duration(milliseconds: 15),
      fetcher: (uri) {
        requestedUris.add(uri.toString());
        if (autoCompleteRemaining) {
          return Future<Uint8List>.value(Uint8List.fromList([4, 5]));
        }
        final c = completers.putIfAbsent(
          uri.toString(),
          () => Completer<Uint8List>(),
        );
        return c.future;
      },
    );
    addTearDown(cache.dispose);

    final questions = [
      _makeMediaQuestion(id: 'q1', images: ['images/img1.png']),
      _makeMediaQuestion(id: 'q2', images: ['images/img2.png']),
      _makeMediaQuestion(
        id: 'q3',
        images: ['images/vid3.png'],
        videos: ['videos/vid3.mp4'],
      ),
    ];

    await cache.initializeWithQuestions(questions);
    expect(cache.totalMediaCount, 4);
    expect(cache.cachedMediaCount, 0);

    // Background loop immediately starts the first item (img1.png) only.
    await Future<void>.delayed(Duration.zero);
    expect(requestedUris.length, 1);
    expect(requestedUris.first, endsWith('/assets/images/img1.png'));

    // User opens q3 (urgent video download!). Even while img1 is in-flight,
    // vid3.mp4 starts immediately without waiting behind img2!
    final urgentFuture1 = cache.ensureAvailable(
      'assets/videos/vid3.mp4',
      highPriority: true,
    );
    final urgentFuture2 = cache.ensureAvailable(
      'assets/videos/vid3.mp4',
      highPriority: true,
    ); // deduplicated!
    await Future<void>.delayed(Duration.zero);

    expect(
      requestedUris.where((u) => u.endsWith('/assets/videos/vid3.mp4')).length,
      1,
    );
    expect(cache.activeUrgentCount, 2);

    // Finish img1 while urgent vid3 is still downloading -> background loop MUST pause
    // and NOT start img2 until urgent downloads finish!
    completers.entries
        .firstWhere((e) => e.key.endsWith('img1.png'))
        .value
        .complete(Uint8List.fromList([1, 2, 3]));
    await Future<void>.delayed(const Duration(milliseconds: 45));
    expect(
      requestedUris.where((u) => u.endsWith('img2.png')),
      isEmpty,
      reason: 'Background trickle must yield while urgent video is downloading',
    );

    // Now complete urgent vid3 -> both urgent futures resolve true, and background resumes!
    completers.entries
        .firstWhere((e) => e.key.endsWith('vid3.mp4'))
        .value
        .complete(Uint8List.fromList([9, 8, 7, 6]));
    expect(await urgentFuture1, isTrue);
    expect(await urgentFuture2, isTrue);
    expect(cache.isCached('assets/videos/vid3.mp4'), isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(
      requestedUris.any((u) => u.endsWith('img2.png')),
      isTrue,
      reason: 'Background trickle resumes once urgent download completes',
    );

    // Allow remaining items (img2.png and vid3.png) to complete cleanly
    autoCompleteRemaining = true;
    for (final entry in completers.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(Uint8List.fromList([4, 5]));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(cache.isFullyCached, isTrue);
    expect(cache.cachedMediaCount, 4);
  });

  test('startDownloadAllOffline downloads all remaining media and IoMediaStore persists to disk atomically', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'driving_media_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final ioStore = IoMediaStore(rootDirectoryProvider: () async => tempDir);
    final cache = MediaCacheService(
      store: ioStore,
      enableBackgroundSync: false,
      bulkConcurrency: 3,
      fetcher: (uri) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return Uint8List.fromList(uri.path.codeUnits);
      },
    );
    addTearDown(cache.dispose);

    final questions = [
      _makeMediaQuestion(id: 'q1', images: ['images/a.png']),
      _makeMediaQuestion(
        id: 'q2',
        images: ['images/b.png'],
        videos: ['videos/v1.mp4'],
      ),
      _makeMediaQuestion(
        id: 'q3',
        images: ['images/c.png'],
        videos: ['videos/v2.mp4'],
      ),
    ];

    await cache.initializeWithQuestions(questions);
    expect(cache.totalMediaCount, 5);
    expect(cache.isFullyCached, isFalse);

    await cache.startDownloadAllOffline();
    expect(cache.isFullyCached, isTrue);
    expect(cache.cachedMediaCount, 5);
    expect(cache.offlineProgress, 1.0);

    // Verify a brand-new MediaCacheService instance sees all 5 files persisted on disk!
    final reloadedCache = MediaCacheService(store: ioStore);
    addTearDown(reloadedCache.dispose);
    await reloadedCache.initializeWithQuestions(questions);
    expect(reloadedCache.cachedMediaCount, 5);
    expect(reloadedCache.isFullyCached, isTrue);
  });
}
