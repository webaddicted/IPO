import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Wraps [http.Client] and logs every request/response in debug builds.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  static const String _tag = 'API';
  static const int _bodyPreviewMax = 2500;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final started = DateTime.now();
    if (kDebugMode) {
      _logRequest(request);
    }

    try {
      final response = await _inner.send(request);
      final bytes = await response.stream.toBytes();

      if (kDebugMode) {
        _logResponse(
          request: request,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          headers: response.headers,
          body: utf8.decode(bytes),
          elapsedMs: DateTime.now().difference(started).inMilliseconds,
        );
      }

      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        contentLength: bytes.length,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        request: response.request,
      );
    } catch (e, st) {
      if (kDebugMode) {
        final ms = DateTime.now().difference(started).inMilliseconds;
        debugPrint(
          '[$_tag] ✗ ${request.method} ${request.url} '
          '(${ms}ms) error: $e',
        );
        debugPrint('$st');
      }
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  void _logRequest(http.BaseRequest request) {
    final buffer = StringBuffer('[$_tag] → ${request.method} ${request.url}');
    if (request.headers.isNotEmpty) {
      buffer.write('\n  headers: ${request.headers}');
    }
    if (request is http.Request && request.body.isNotEmpty) {
      buffer.write('\n  body: ${_preview(request.body)}');
    }
    debugPrint(buffer.toString());
  }

  void _logResponse({
    required http.BaseRequest request,
    required int statusCode,
    required String? reasonPhrase,
    required Map<String, String> headers,
    required String body,
    required int elapsedMs,
  }) {
    final ok = statusCode >= 200 && statusCode < 300;
    final mark = ok ? '✓' : '✗';
    final buffer = StringBuffer(
      '[$_tag] $mark ${request.method} ${request.url} '
      '→ $statusCode ${reasonPhrase ?? ''} (${elapsedMs}ms)',
    );
    if (headers.isNotEmpty) {
      buffer.write('\n  headers: $headers');
    }
    if (body.isNotEmpty) {
      buffer.write('\n  body: ${_preview(body)}');
    }
    debugPrint(buffer.toString());
  }

  String _preview(String raw) {
    if (raw.isEmpty) return raw;
    try {
      final decoded = jsonDecode(raw);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      if (pretty.length <= _bodyPreviewMax) return pretty;
      return '${pretty.substring(0, _bodyPreviewMax)}…';
    } catch (_) {
      if (raw.length <= _bodyPreviewMax) return raw;
      return '${raw.substring(0, _bodyPreviewMax)}…';
    }
  }
}
