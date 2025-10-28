import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/debug_logger.dart';

/// Parser for Server-Sent Events (SSE) streaming responses.
/// 
/// This matches the web client's EventSourceParserStream behavior,
/// parsing SSE data chunks and extracting OpenAI-compatible deltas.
class SSEStreamParser {
  /// Parse an SSE response stream from Dio into text chunks.
  /// 
  /// Returns a stream of content strings extracted from OpenAI-style
  /// completion chunks.
  /// 
  /// [heartbeatTimeout] - Maximum time without data before considering
  /// the connection stale (default: 2 minutes)
  /// [onHeartbeat] - Callback invoked when any data is received
  static Stream<String> parseResponseStream(
    ResponseBody responseBody, {
    bool splitLargeDeltas = false,
    Duration heartbeatTimeout = const Duration(minutes: 2),
    void Function()? onHeartbeat,
  }) async* {
    DateTime lastDataReceived = DateTime.now();
    Timer? heartbeatTimer;
    
    // Set up heartbeat monitoring
    if (heartbeatTimeout.inMilliseconds > 0) {
      heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) {
          final timeSinceLastData = DateTime.now().difference(lastDataReceived);
          if (timeSinceLastData > heartbeatTimeout) {
            DebugLogger.warning(
              'SSE stream heartbeat timeout: No data received for ${timeSinceLastData.inSeconds}s',
              data: {'timeout': heartbeatTimeout.inSeconds},
            );
            timer.cancel();
          }
        },
      );
    }
    
    try {
      // Buffer for accumulating incomplete SSE messages
      String buffer = '';
      
      await for (final chunk in responseBody.stream) {
        // Update last data timestamp and invoke heartbeat callback
        lastDataReceived = DateTime.now();
        onHeartbeat?.call();
        
        // Convert bytes to string (Dio ResponseBody.stream always emits Uint8List)
        final text = utf8.decode(chunk as List<int>, allowMalformed: true);
        buffer += text;
        
        // Process complete SSE messages (delimited by double newline)
        final messages = buffer.split('\n\n');
        
        // Keep the last (potentially incomplete) message in the buffer
        buffer = messages.removeLast();
        
        for (final message in messages) {
          if (message.trim().isEmpty) continue;
          
          // Parse SSE message
          final content = _parseSSEMessage(message);
          if (content != null) {
            if (content == '[DONE]') {
              // Stream completion signal
              DebugLogger.stream('SSE stream completed with [DONE] signal');
              return;
            }
            
            // Split large deltas into smaller chunks for smoother UI updates
            if (splitLargeDeltas && content.length > 5) {
              yield* _splitIntoChunks(content);
            } else {
              yield content;
            }
          }
        }
      }
      
      // Process any remaining buffered data
      if (buffer.trim().isNotEmpty) {
        final content = _parseSSEMessage(buffer);
        if (content != null && content != '[DONE]') {
          yield content;
        }
      }
    } catch (e, stackTrace) {
      DebugLogger.error(
        'sse-parse-error',
        scope: 'streaming/sse',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      // Clean up heartbeat timer
      heartbeatTimer?.cancel();
    }
  }
  
  /// Parse a single SSE message and extract content.
  static String? _parseSSEMessage(String message) {
    try {
      // SSE format: "data: <json>\n" or just the JSON
      String dataLine = message.trim();
      
      // Remove "data: " prefix if present
      if (dataLine.startsWith('data: ')) {
        dataLine = dataLine.substring(6).trim();
      } else if (dataLine.startsWith('data:')) {
        dataLine = dataLine.substring(5).trim();
      }
      
      // Handle [DONE] signal
      if (dataLine == '[DONE]' || dataLine == 'DONE') {
        return '[DONE]';
      }
      
      // Skip empty data
      if (dataLine.isEmpty) {
        return null;
      }
      
      // Parse JSON
      try {
        final json = jsonDecode(dataLine) as Map<String, dynamic>;
        
        // Handle errors
        if (json['error'] != null) {
          DebugLogger.error(
            'sse-error-response',
            scope: 'streaming/sse',
            error: json['error'],
          );
          return null;
        }
        
        // Extract content from OpenAI-style response
        // Format: { choices: [{ delta: { content: "..." } }] }
        final choices = json['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = choices.first as Map<String, dynamic>?;
          if (choice != null) {
            final delta = choice['delta'] as Map<String, dynamic>?;
            if (delta != null) {
              final content = delta['content'];
              if (content is String && content.isNotEmpty) {
                return content;
              }
            }
          }
        }
        
        // Alternative format: { content: "..." }
        final directContent = json['content'];
        if (directContent is String && directContent.isNotEmpty) {
          return directContent;
        }
        
        return null;
      } on FormatException catch (e) {
        DebugLogger.warning(
          'Failed to parse SSE JSON: $dataLine',
          data: {'error': e.toString()},
        );
        return null;
      }
    } catch (e) {
      DebugLogger.error(
        'sse-message-parse-error',
        scope: 'streaming/sse',
        error: e,
        data: {'message': message},
      );
      return null;
    }
  }
  
  /// Split large content into smaller chunks for smoother streaming.
  /// This matches the web client's streamLargeDeltasAsRandomChunks behavior.
  static Stream<String> _splitIntoChunks(String content) async* {
    var remaining = content;
    
    while (remaining.isNotEmpty) {
      // Random chunk size between 1-3 characters
      final chunkSize = (remaining.length < 3)
          ? remaining.length
          : 1 + (DateTime.now().millisecond % 3);
      
      final chunk = remaining.substring(0, chunkSize);
      yield chunk;
      
      // Small delay for smoother visual effect (matching web client)
      await Future.delayed(const Duration(milliseconds: 5));
      
      remaining = remaining.substring(chunkSize);
    }
  }
}
