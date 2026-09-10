import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';

/// LocalStorageService wraps SharedPreferences, which requires an async
/// `getInstance()` call. Rather than threading Future/AsyncValue handling
/// through every controller that needs it (auth already reads secure
/// storage synchronously via awaits inside methods, so this stays
/// consistent), it's constructed once in main() before runApp and supplied
/// here via ProviderScope override. This provider's build function is never
/// actually called in a running app -- overriding it is mandatory.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in main() with a '
    'LocalStorageService created via LocalStorageService.create().',
  );
});
