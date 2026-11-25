import 'dart:io';

List<int>? zlibDecodeBytes(List<int> data) => zlib.decode(data);

List<int>? zlibEncodeBytes(List<int> data) => zlib.encode(data);
