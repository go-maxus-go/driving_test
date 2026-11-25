import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'png_zlib.dart';

/// Detects and strips the legacy opaque dithered green chroma-key background
/// (`RGB(71, 112, 76)` quantized onto an 8-8-4 palette: `(72,108,85)`,
/// `(72,108,0)`, `(72,144,85)`, `(72,144,0)`) from traffic-sign PNGs that are
/// missing a PNG `tRNS` alpha channel.
///
/// Images that already have transparency, non-indexed PNGs, JPEGs, and normal
/// road photos return the original [Uint8List] reference untouched in O(chunks).

const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

// Packed RGB24 values of the 4 exact 8-8-4 dithered background colors.
const int _bgPrimary = (72 << 16) | (108 << 8) | 85;
const int _bgAlt1 = (72 << 16) | (108 << 8) | 0;
const int _bgAlt2 = (72 << 16) | (144 << 8) | 85;
const int _bgAlt3 = (72 << 16) | (144 << 8) | 0;

bool _isStrictBgRgb(int r, int g, int b) {
  final packed = (r << 16) | (g << 8) | b;
  return packed == _bgPrimary ||
      packed == _bgAlt1 ||
      packed == _bgAlt2 ||
      packed == _bgAlt3;
}

bool _isFloodBgRgb(int r, int g, int b) {
  if (_isStrictBgRgb(r, g, b)) return true;
  // Near-background greenish anti-aliased fringe pixels bridging tight gaps
  // between stacked signs (e.g. warning triangle + Zusatzzeichen).
  return g >= 100 &&
      g <= 155 &&
      r <= 115 &&
      b <= 95 &&
      (g - r) >= 25 &&
      (g - b) >= 15;
}

int _distSqBg(int r, int g, int b) {
  final dr = r - 71;
  final dg = g - 112;
  final db = b - 76;
  return dr * dr + dg * dg + db * db;
}

class _ParsedIndexedPng {
  const _ParsedIndexedPng({
    required this.width,
    required this.height,
    required this.palette,
    required this.idat,
  });

  final int width;
  final int height;
  final Uint8List palette;
  final Uint8List idat;
}

bool _hasPngSignature(Uint8List bytes) {
  if (bytes.length < 33) return false;
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != _pngSignature[i]) return false;
  }
  return true;
}

int _readUint32BE(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

void _writeUint32BE(Uint8List out, int offset, int value) {
  out[offset] = (value >> 24) & 0xff;
  out[offset + 1] = (value >> 16) & 0xff;
  out[offset + 2] = (value >> 8) & 0xff;
  out[offset + 3] = value & 0xff;
}

_ParsedIndexedPng? _parseCandidateIndexedPng(Uint8List bytes) {
  if (!_hasPngSignature(bytes)) return null;

  var pos = 8;
  int? width;
  int? height;
  Uint8List? palette;
  final idatBuilder = BytesBuilder(copy: false);

  while (pos + 12 <= bytes.length) {
    final length = _readUint32BE(bytes, pos);
    final typeOffset = pos + 4;
    final dataStart = pos + 8;
    final dataEnd = dataStart + length;
    if (length < 0 || dataEnd + 4 > bytes.length) return null;

    final t0 = bytes[typeOffset];
    final t1 = bytes[typeOffset + 1];
    final t2 = bytes[typeOffset + 2];
    final t3 = bytes[typeOffset + 3];

    // IHDR
    if (t0 == 0x49 && t1 == 0x48 && t2 == 0x44 && t3 == 0x52) {
      if (length != 13) return null;
      width = _readUint32BE(bytes, dataStart);
      height = _readUint32BE(bytes, dataStart + 4);
      final bitDepth = bytes[dataStart + 8];
      final colorType = bytes[dataStart + 9];
      final compression = bytes[dataStart + 10];
      final filter = bytes[dataStart + 11];
      final interlace = bytes[dataStart + 12];
      // Only 8-bit non-interlaced indexed PNGs can have this bug.
      if (width <= 0 ||
          height <= 0 ||
          bitDepth != 8 ||
          colorType != 3 ||
          compression != 0 ||
          filter != 0 ||
          interlace != 0) {
        return null;
      }
    }
    // tRNS -> already has alpha transparency, skip immediately.
    else if (t0 == 0x74 && t1 == 0x52 && t2 == 0x4E && t3 == 0x53) {
      return null;
    }
    // PLTE
    else if (t0 == 0x50 && t1 == 0x4C && t2 == 0x54 && t3 == 0x45) {
      if (length == 0 || length % 3 != 0) return null;
      palette = Uint8List.sublistView(bytes, dataStart, dataEnd);
    }
    // IDAT
    else if (t0 == 0x49 && t1 == 0x44 && t2 == 0x41 && t3 == 0x54) {
      idatBuilder.add(Uint8List.sublistView(bytes, dataStart, dataEnd));
    }
    // IEND
    else if (t0 == 0x49 && t1 == 0x45 && t2 == 0x4E && t3 == 0x44) {
      break;
    }

    pos = dataEnd + 4;
  }

  if (width == null || height == null || palette == null) return null;

  // Verify the palette contains the primary green chroma-key color and at least
  // one of its dither companions.
  var hasPrimary = false;
  var hasCompanion = false;
  for (var i = 0; i < palette.length; i += 3) {
    final packed = (palette[i] << 16) | (palette[i + 1] << 8) | palette[i + 2];
    if (packed == _bgPrimary) {
      hasPrimary = true;
    } else if (packed == _bgAlt1 || packed == _bgAlt2 || packed == _bgAlt3) {
      hasCompanion = true;
    }
  }
  if (!hasPrimary || !hasCompanion) return null;

  final idat = idatBuilder.takeBytes();
  if (idat.isEmpty) return null;

  return _ParsedIndexedPng(
    width: width,
    height: height,
    palette: palette,
    idat: idat,
  );
}

/// Fast zero-decompression check for whether [bytes] might be an opaque
/// green-background sign PNG.
bool hasGreenSignBackgroundCandidate(Uint8List bytes) =>
    _parseCandidateIndexedPng(bytes) != null;

/// Processes [rgba] (length `width * height * 4`) in place if >= 85% of outer
/// border pixels match the dithered green chroma-key background. Returns `true`
/// if [rgba] was modified.
bool removeGreenSignBackgroundFromRgba(Uint8List rgba, int width, int height) {
  if (width <= 2 || height <= 2 || rgba.length != width * height * 4) {
    return false;
  }

  // Verify outer 1px border is overwhelmingly the dithered green background.
  var borderTotal = 0;
  var borderGreen = 0;
  for (var x = 0; x < width; x++) {
    for (final y in <int>[0, height - 1]) {
      final off = (y * width + x) * 4;
      borderTotal++;
      if (rgba[off + 3] > 200 &&
          _isStrictBgRgb(rgba[off], rgba[off + 1], rgba[off + 2])) {
        borderGreen++;
      }
    }
  }
  for (var y = 1; y < height - 1; y++) {
    for (final x in <int>[0, width - 1]) {
      final off = (y * width + x) * 4;
      borderTotal++;
      if (rgba[off + 3] > 200 &&
          _isStrictBgRgb(rgba[off], rgba[off + 1], rgba[off + 2])) {
        borderGreen++;
      }
    }
  }
  if (borderTotal == 0 || borderGreen * 100 < borderTotal * 85) {
    return false;
  }

  final pixelCount = width * height;
  final bg = Uint8List(pixelCount);
  final queue = Queue<int>();

  void trySeed(int x, int y) {
    final pos = y * width + x;
    if (bg[pos] != 0) return;
    final off = pos * 4;
    if (_isFloodBgRgb(rgba[off], rgba[off + 1], rgba[off + 2])) {
      bg[pos] = 1;
      queue.addLast(pos);
    }
  }

  for (var x = 0; x < width; x++) {
    trySeed(x, 0);
    trySeed(x, height - 1);
  }
  for (var y = 1; y < height - 1; y++) {
    trySeed(0, y);
    trySeed(width - 1, y);
  }

  // Pass 1: 8-connected BFS flood fill from edges across background pixels.
  while (queue.isNotEmpty) {
    final pos = queue.removeFirst();
    final x = pos % width;
    final y = pos ~/ width;
    for (var dy = -1; dy <= 1; dy++) {
      final ny = y + dy;
      if (ny < 0 || ny >= height) continue;
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        if (nx < 0 || nx >= width) continue;
        final npos = ny * width + nx;
        if (bg[npos] != 0) continue;
        final off = npos * 4;
        if (_isFloodBgRgb(rgba[off], rgba[off + 1], rgba[off + 2])) {
          bg[npos] = 1;
          queue.addLast(npos);
        }
      }
    }
  }

  // Pass 1b: Remove protruding 1px dither speckles (>=3 cardinal bg neighbors).
  for (var pass = 0; pass < 2; pass++) {
    final toMark = <int>[];
    for (var y = 0; y < height; y++) {
      final rowOff = y * width;
      for (var x = 0; x < width; x++) {
        final pos = rowOff + x;
        if (bg[pos] != 0) continue;
        var bgN = 0;
        if (x > 0 && bg[pos - 1] != 0) bgN++;
        if (x + 1 < width && bg[pos + 1] != 0) bgN++;
        if (y > 0 && bg[pos - width] != 0) bgN++;
        if (y + 1 < height && bg[pos + width] != 0) bgN++;
        if (bgN >= 3) {
          final off = pos * 4;
          final r = rgba[off];
          final g = rgba[off + 1];
          final b = rgba[off + 2];
          if (_distSqBg(r, g, b) <= 65 * 65 ||
              (r <= 115 && g <= 150 && b <= 110 && g >= r)) {
            toMark.add(pos);
          }
        }
      }
    }
    if (toMark.isEmpty) break;
    for (final pos in toMark) {
      bg[pos] = 1;
    }
  }

  // Apply transparent alpha to all background pixels.
  for (var pos = 0; pos < pixelCount; pos++) {
    if (bg[pos] != 0) {
      final off = pos * 4;
      rgba[off] = 0;
      rgba[off + 1] = 0;
      rgba[off + 2] = 0;
      rgba[off + 3] = 0;
    }
  }

  // Pass 2: De-fringe 1px anti-aliased boundary touching transparent background.
  for (var y = 0; y < height; y++) {
    final rowOff = y * width;
    for (var x = 0; x < width; x++) {
      final pos = rowOff + x;
      if (bg[pos] != 0) continue;
      final touchesBg =
          (x > 0 && bg[pos - 1] != 0) ||
          (x + 1 < width && bg[pos + 1] != 0) ||
          (y > 0 && bg[pos - width] != 0) ||
          (y + 1 < height && bg[pos + width] != 0);
      if (!touchesBg) continue;

      final off = pos * 4;
      final r = rgba[off];
      final g = rgba[off + 1];
      final b = rgba[off + 2];
      final isGreenOrDarkFringe =
          r <= 115 &&
          g <= 150 &&
          b <= 110 &&
          ((g - r) >= 10 ||
              (r <= 110 &&
                  g <= 110 &&
                  (r - g).abs() <= 10 &&
                  (r > 0 || g > 0 || b > 0)));
      if (!isGreenOrDarkFringe) continue;

      if (_distSqBg(r, g, b) <= 45 * 45) {
        rgba[off] = 0;
        rgba[off + 1] = 0;
        rgba[off + 2] = 0;
        rgba[off + 3] = 0;
      } else {
        final rf = r / 71.0;
        final gf = g / 112.0;
        final bgFrac = rf > gf ? rf : gf;
        final alpha = ((1.0 - bgFrac).clamp(0.0, 1.0) * 255.0).round();
        rgba[off] = 0;
        rgba[off + 1] = 0;
        rgba[off + 2] = 0;
        rgba[off + 3] = alpha;
      }
    }
  }

  return true;
}

final Uint32List _crcTable = _buildCrcTable();

Uint32List _buildCrcTable() {
  final table = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      if ((c & 1) != 0) {
        c = 0xedb88320 ^ (c >>> 1);
      } else {
        c = c >>> 1;
      }
    }
    table[n] = c;
  }
  return table;
}

int _crc32(List<int> typeBytes, List<int> dataBytes) {
  var c = 0xffffffff;
  for (var i = 0; i < typeBytes.length; i++) {
    c = _crcTable[(c ^ typeBytes[i]) & 0xff] ^ (c >>> 8);
  }
  for (var i = 0; i < dataBytes.length; i++) {
    c = _crcTable[(c ^ dataBytes[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) & 0xffffffff;
}

Uint8List _buildPngChunk(List<int> typeBytes, List<int> dataBytes) {
  final out = Uint8List(12 + dataBytes.length);
  _writeUint32BE(out, 0, dataBytes.length);
  out.setRange(4, 8, typeBytes);
  out.setRange(8, 8 + dataBytes.length, dataBytes);
  _writeUint32BE(out, 8 + dataBytes.length, _crc32(typeBytes, dataBytes));
  return out;
}

Uint8List? _encodeRgbaPngSync(int width, int height, Uint8List rgba) {
  final stride = width * 4;
  final raw = Uint8List(height * (stride + 1));
  for (var y = 0; y < height; y++) {
    final dstRow = y * (stride + 1);
    final srcRow = y * stride;
    raw[dstRow] = 1; // Sub filter
    for (var i = 0; i < 4; i++) {
      raw[dstRow + 1 + i] = rgba[srcRow + i];
    }
    for (var i = 4; i < stride; i++) {
      raw[dstRow + 1 + i] = (rgba[srcRow + i] - rgba[srcRow + i - 4]) & 0xff;
    }
  }

  final compressed = zlibEncodeBytes(raw);
  if (compressed == null) return null;

  final ihdr = Uint8List(13);
  _writeUint32BE(ihdr, 0, width);
  _writeUint32BE(ihdr, 4, height);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  final builder = BytesBuilder(copy: false)
    ..add(_pngSignature)
    ..add(_buildPngChunk(const <int>[0x49, 0x48, 0x44, 0x52], ihdr))
    ..add(_buildPngChunk(const <int>[0x49, 0x44, 0x41, 0x54], compressed))
    ..add(_buildPngChunk(const <int>[0x49, 0x45, 0x4E, 0x44], const <int>[]));
  return builder.takeBytes();
}

/// Synchronous pure-Dart PNG green-background sanitizer (works on all `dart:io`
/// platforms). Returns the original [bytes] if no change is needed or if `zlib`
/// is unavailable (e.g., on Web).
Uint8List? sanitizeSignPngBackgroundSync(Uint8List bytes) {
  final parsed = _parseCandidateIndexedPng(bytes);
  if (parsed == null) return bytes;

  final decoded = zlibDecodeBytes(parsed.idat);
  if (decoded == null) return null; // Signal caller to try async dart:ui path.

  final width = parsed.width;
  final height = parsed.height;
  final expectedLen = height * (width + 1);
  if (decoded.length < expectedLen) return bytes;

  final palette = parsed.palette;
  final paletteEntries = palette.length ~/ 3;
  final rgba = Uint8List(width * height * 4);
  final prevRow = Uint8List(width);
  final curRow = Uint8List(width);

  var srcIdx = 0;
  for (var y = 0; y < height; y++) {
    final filterType = decoded[srcIdx++];
    for (var x = 0; x < width; x++) {
      final rawVal = decoded[srcIdx++];
      int recon;
      switch (filterType) {
        case 0:
          recon = rawVal;
          break;
        case 1:
          final a = x > 0 ? curRow[x - 1] : 0;
          recon = (rawVal + a) & 0xff;
          break;
        case 2:
          recon = (rawVal + prevRow[x]) & 0xff;
          break;
        case 3:
          final a = x > 0 ? curRow[x - 1] : 0;
          recon = (rawVal + ((a + prevRow[x]) >> 1)) & 0xff;
          break;
        case 4:
          final a = x > 0 ? curRow[x - 1] : 0;
          final b = prevRow[x];
          final c = x > 0 ? prevRow[x - 1] : 0;
          final p = a + b - c;
          final pa = (p - a).abs();
          final pb = (p - b).abs();
          final pc = (p - c).abs();
          final pr = pa <= pb && pa <= pc ? a : (pb <= pc ? b : c);
          recon = (rawVal + pr) & 0xff;
          break;
        default:
          return bytes;
      }
      curRow[x] = recon;
      final outOff = (y * width + x) * 4;
      if (recon < paletteEntries) {
        final pOff = recon * 3;
        rgba[outOff] = palette[pOff];
        rgba[outOff + 1] = palette[pOff + 1];
        rgba[outOff + 2] = palette[pOff + 2];
        rgba[outOff + 3] = 255;
      } else {
        rgba[outOff + 3] = 255;
      }
    }
    prevRow.setAll(0, curRow);
  }

  final modified = removeGreenSignBackgroundFromRgba(rgba, width, height);
  if (!modified) return bytes;

  return _encodeRgbaPngSync(width, height, rgba) ?? bytes;
}

/// Cross-platform PNG green-background sanitizer.
///
/// Uses the fast synchronous `dart:io` `zlib` path on mobile/desktop and falls
/// back to `dart:ui` image decoding/encoding on Web. Returns the original
/// [bytes] instance if no sanitization is needed or if decoding fails.
Future<Uint8List> sanitizeSignPngBackground(Uint8List bytes) async {
  if (!hasGreenSignBackgroundCandidate(bytes)) return bytes;

  try {
    final syncResult = sanitizeSignPngBackgroundSync(bytes);
    if (syncResult != null) return syncResult;
  } catch (_) {
    return bytes;
  }

  // Web fallback using dart:ui codec.
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;
      try {
        final byteData = await decodedImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData == null) return bytes;
        final rgba = Uint8List.fromList(byteData.buffer.asUint8List());
        final width = decodedImage.width;
        final height = decodedImage.height;
        final modified = removeGreenSignBackgroundFromRgba(rgba, width, height);
        if (!modified) return bytes;

        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          rgba,
          width,
          height,
          ui.PixelFormat.rgba8888,
          completer.complete,
        );
        final outImage = await completer.future;
        try {
          final pngData = await outImage.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (pngData == null) return bytes;
          return pngData.buffer.asUint8List();
        } finally {
          outImage.dispose();
        }
      } finally {
        decodedImage.dispose();
      }
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return bytes;
  }
}
