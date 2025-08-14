import 'dart:typed_data';

class PlatformFileWrapper {
  final String name;
  final Uint8List? bytes;
  final String? path;

  PlatformFileWrapper({
    required this.name,
    this.bytes,
    this.path,
  }) : assert(bytes != null || path != null, "A file must have either bytes or a path.");
}