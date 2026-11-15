import 'dart:io';

import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return File(key).readAsString();
  }
}

void main() {
  test('AppLanguage JSON assetPaths exist on disk and match pubspec.yaml, while heavy images/videos are excluded from bundle', () async {
    final pubspecContent = File('pubspec.yaml').readAsStringSync();

    for (final lang in AppLanguage.values) {
      expect(
        File(lang.assetPath).existsSync(),
        isTrue,
        reason: 'Missing asset file on disk for $lang: ${lang.assetPath}',
      );
      expect(
        pubspecContent.contains('- ${lang.assetPath}'),
        isTrue,
        reason:
            'Asset ${lang.assetPath} is not registered in pubspec.yaml assets list',
      );
    }

    // Heavy media directories must NOT be bundled into the app binary.
    expect(pubspecContent.contains('- assets/images/'), isFalse);
    expect(pubspecContent.contains('- assets/videos/'), isFalse);

    final repo = await CatalogRepository.loadFromAssets(
      bundle: _DiskAssetBundle(),
    );
    expect(repo.questionsFor(AppLanguage.en).length, 1592);
    expect(repo.questionsFor(AppLanguage.de).length, 1592);
  });
}
