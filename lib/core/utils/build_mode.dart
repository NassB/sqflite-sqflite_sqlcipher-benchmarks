import 'package:flutter/foundation.dart';

String detectBuildMode() {
  if (kReleaseMode) return 'release';
  if (kProfileMode) return 'profile';
  return 'debug';
}
