import 'dart:io';
import 'dart:typed_data';

import 'package:driving_exam/services/media_cache_service.dart';
import 'package:driving_exam/services/media_store.dart';
import 'package:driving_exam/services/png_background_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

const List<int> _pngSig = <int>[137, 80, 78, 71, 13, 10, 26, 10];

Uint8List _u32(int v) => Uint8List.fromList(<int>[
  (v >> 24) & 0xff,
  (v >> 16) & 0xff,
  (v >> 8) & 0xff,
  v & 0xff,
]);

final Uint32List _crcTable = () {
  final t = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    t[n] = c;
  }
  return t;
}();

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  var c = 0xffffffff;
  for (final b in typeBytes) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  }
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  }
  final crc = (c ^ 0xffffffff) & 0xffffffff;
  return Uint8List.fromList(<int>[
    ..._u32(data.length),
    ...typeBytes,
    ...data,
    ..._u32(crc),
  ]);
}

/// Builds a synthetic 12x12 indexed PNG with a dithered green background
/// surrounding a black-bordered white sign that also contains an interior
/// green pixel (to prove flood-fill preserves interior sign graphics).
Uint8List _buildGreenSignIndexedPng({bool includeTrns = false}) {
  const w = 12;
  const h = 12;
  // Palette:
  // 0: (72, 108, 85)  strict bg primary
  // 1: (72, 108, 0)   strict bg dither
  // 2: (72, 144, 85)  strict bg dither
  // 3: (0, 0, 0)      sign outline
  // 4: (255, 255, 255) sign fill
  final palette = <int>[
    72,
    108,
    85,
    72,
    108,
    0,
    72,
    144,
    85,
    0,
    0,
    0,
    255,
    255,
    255,
  ];
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filter type None
    for (var x = 0; x < w; x++) {
      if (x >= 3 && x <= 8 && y >= 3 && y <= 8) {
        if (x == 3 || x == 8 || y == 3 || y == 8) {
          raw.addByte(3); // black sign border
        } else if (x == 5 && y == 5) {
          raw.addByte(0); // interior green symbol pixel (must be preserved!)
        } else {
          raw.addByte(4); // white sign interior
        }
      } else {
        raw.addByte((x + y) % 3); // dithered green background
      }
    }
  }

  final ihdr = <int>[..._u32(w), ..._u32(h), 8, 3, 0, 0, 0];
  final out = BytesBuilder()
    ..add(_pngSig)
    ..add(_chunk('IHDR', ihdr))
    ..add(_chunk('PLTE', palette));
  if (includeTrns) {
    out.add(_chunk('tRNS', <int>[0]));
  }
  out
    ..add(_chunk('IDAT', zlib.encode(raw.takeBytes())))
    ..add(_chunk('IEND', const <int>[]));
  return out.takeBytes();
}

/// Decodes RGBA pixels from an uncompressed/Sub-filtered color_type=6 PNG.
(int width, int height, Uint8List rgba) _decodeRgbaPng(Uint8List bytes) {
  var pos = 8;
  var w = 0;
  var h = 0;
  var colorType = -1;
  final idat = BytesBuilder();
  while (pos + 12 <= bytes.length) {
    final len =
        (bytes[pos] << 24) |
        (bytes[pos + 1] << 16) |
        (bytes[pos + 2] << 8) |
        bytes[pos + 3];
    final type = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));
    final data = bytes.sublist(pos + 8, pos + 8 + len);
    pos += 12 + len;
    if (type == 'IHDR') {
      w = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
      h = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
      colorType = data[9];
    } else if (type == 'IDAT') {
      idat.add(data);
    }
  }
  expect(colorType, 6, reason: 'Expected RGBA PNG (color_type=6)');
  final raw = zlib.decode(idat.takeBytes());
  final stride = w * 4;
  final rgba = Uint8List(w * h * 4);
  var src = 0;
  for (var y = 0; y < h; y++) {
    final filter = raw[src++];
    final rowStart = y * stride;
    for (var i = 0; i < stride; i++) {
      final v = raw[src++];
      if (filter == 0) {
        rgba[rowStart + i] = v;
      } else if (filter == 1) {
        final left = i >= 4 ? rgba[rowStart + i - 4] : 0;
        rgba[rowStart + i] = (v + left) & 0xff;
      } else {
        fail('Unexpected PNG filter type $filter');
      }
    }
  }
  return (w, h, rgba);
}

void main() {
  test(
    'strips dithered green background while preserving interior sign pixels',
    () async {
      final greenPng = _buildGreenSignIndexedPng();
      expect(hasGreenSignBackgroundCandidate(greenPng), isTrue);

      final sanitized = await sanitizeSignPngBackground(greenPng);
      expect(identical(sanitized, greenPng), isFalse);

      final (w, h, rgba) = _decodeRgbaPng(sanitized);
      expect(w, 12);
      expect(h, 12);

      // Outer corner must be fully transparent.
      expect(rgba[3], 0);
      // Bottom-right corner must be fully transparent.
      expect(rgba[((h - 1) * w + (w - 1)) * 4 + 3], 0);
      // Sign border at (3, 3) stays opaque black.
      final borderOff = (3 * w + 3) * 4;
      expect(rgba.sublist(borderOff, borderOff + 4), [0, 0, 0, 255]);
      // Sign white interior at (4, 4) stays opaque white.
      final whiteOff = (4 * w + 4) * 4;
      expect(rgba.sublist(whiteOff, whiteOff + 4), [255, 255, 255, 255]);
      // Interior green pixel at (5, 5) must NOT be punched out!
      final innerGreenOff = (5 * w + 5) * 4;
      expect(rgba.sublist(innerGreenOff, innerGreenOff + 4), [
        72,
        108,
        85,
        255,
      ]);

      // Running sanitizer again on the cleaned RGBA PNG is an instant no-op.
      expect(hasGreenSignBackgroundCandidate(sanitized), isFalse);
      final secondPass = await sanitizeSignPngBackground(sanitized);
      expect(identical(secondPass, sanitized), isTrue);
    },
  );

  test(
    'ignores already-transparent PNGs and non-PNG bytes untouched',
    () async {
      final transparentPng = _buildGreenSignIndexedPng(includeTrns: true);
      expect(hasGreenSignBackgroundCandidate(transparentPng), isFalse);
      expect(
        identical(
          await sanitizeSignPngBackground(transparentPng),
          transparentPng,
        ),
        isTrue,
      );

      final rawBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]);
      expect(hasGreenSignBackgroundCandidate(rawBytes), isFalse);
      expect(
        identical(await sanitizeSignPngBackground(rawBytes), rawBytes),
        isTrue,
      );
    },
  );

  test('MediaCacheService sanitizes both newly downloaded and previously cached green sign PNGs', () async {
    final greenPng = _buildGreenSignIndexedPng();

    // 1. Newly downloaded PNG
    final store1 = InMemoryMediaStore();
    final cache1 = MediaCacheService(
      store: store1,
      fetcher: (_) async => greenPng,
    );
    addTearDown(cache1.dispose);

    final downloaded = await cache1.getOrDownloadImageBytes(
      'assets/images/1_4_40-002.png',
    );
    expect(downloaded, isNotNull);
    expect(identical(downloaded, greenPng), isFalse);
    expect(_decodeRgbaPng(downloaded!).$3[3], 0);

    // 2. Previously cached legacy green PNG on disk self-heals on read
    final store2 = InMemoryMediaStore();
    const assetPath = 'assets/images/1_4_40-107.png';
    final cache2 = MediaCacheService(store: store2);
    addTearDown(cache2.dispose);
    final remoteUrl = cache2.remoteUrlFor(assetPath);
    await store2.writeBytes(assetPath, remoteUrl, greenPng);

    final fromCache = await cache2.getOrDownloadImageBytes(assetPath);
    expect(fromCache, isNotNull);
    expect(identical(fromCache, greenPng), isFalse);
    expect(_decodeRgbaPng(fromCache!).$3[3], 0);

    // Give fire-and-forget cache self-heal write a microtask to finish.
    await Future<void>.delayed(Duration.zero);
    final healedDisk = await store2.readBytes(assetPath, remoteUrl);
    expect(healedDisk, isNotNull);
    expect(hasGreenSignBackgroundCandidate(healedDisk!), isFalse);
  });

  test('all 15 previously green-background sign PNGs in assets/images are now transparent', () {
    const fixedFiles = <String>[
      '1_4_40-002.png',
      '1_4_40-008.png',
      '1_4_40-107.png',
      '1_4_40-133.png',
      '1_4_40-134.png',
      '1_4_40-137.png',
      '1_4_40-138.png',
      '1_4_40-139.png',
      '1_4_40-140.png',
      '1_4_40-141.png',
      '1_4_40-145.png',
      '1_4_40-146.png',
      '1_4_42-130.png',
      '2_5_01-010.png',
      '2_6_07-209.png',
    ];

    for (final name in fixedFiles) {
      final file = File('assets/images/$name');
      expect(file.existsSync(), isTrue, reason: 'Missing $name');
      final bytes = file.readAsBytesSync();
      expect(
        hasGreenSignBackgroundCandidate(bytes),
        isFalse,
        reason: '$name still appears to have an opaque green background',
      );
      final (w, h, rgba) = _decodeRgbaPng(bytes);
      // All 4 corners must be fully transparent.
      expect(rgba[3], 0, reason: '$name top-left corner not transparent');
      expect(
        rgba[(w - 1) * 4 + 3],
        0,
        reason: '$name top-right corner not transparent',
      );
      expect(
        rgba[(h - 1) * w * 4 + 3],
        0,
        reason: '$name bottom-left corner not transparent',
      );
      expect(
        rgba[((h - 1) * w + (w - 1)) * 4 + 3],
        0,
        reason: '$name bottom-right corner not transparent',
      );
    }
  });
}
