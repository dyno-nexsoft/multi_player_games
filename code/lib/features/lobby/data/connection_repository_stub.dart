import 'connection_repository.dart';

ConnectionRepository getConnectionRepository() => throw UnsupportedError(
  'Cannot create ConnectionRepository without dart:js_interop or dart:io',
);

Future<String?> getLocalIpAddress() => throw UnsupportedError('Cannot get IP');
