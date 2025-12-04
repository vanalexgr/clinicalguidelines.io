/// Utility class for parsing and extracting reasoning/thinking content from messages.
///
/// This parser handles:
/// - `<details type="reasoning">` blocks (server-emitted, preferred)
/// - Raw tag pairs like `<think>`, `<thinking>`, `<reasoning>`, etc.
///
/// Reference: openwebui-src/backend/open_webui/utils/middleware.py DEFAULT_REASONING_TAGS
library;

import 'html_utils.dart';

/// All reasoning tag pairs supported by Open WebUI.
/// Reference: DEFAULT_REASONING_TAGS in middleware.py
const List<(String, String)> defaultReasoningTagPairs = [
  ('<think>', '</think>'),
  ('<thinking>', '</thinking>'),
  ('<reason>', '</reason>'),
  ('<reasoning>', '</reasoning>'),
  ('<thought>', '</thought>'),
  ('<Thought>', '</Thought>'),
  ('<|begin_of_thought|>', '<|end_of_thought|>'),
  ('◁think▷', '◁/think▷'),
];

/// Lightweight reasoning block for segmented rendering.
class ReasoningEntry {
  final String reasoning;
  final String summary;
  final int duration;
  final bool isDone;

  const ReasoningEntry({
    required this.reasoning,
    required this.summary,
    required this.duration,
    required this.isDone,
  });

  String get formattedDuration => ReasoningParser.formatDuration(duration);

  /// Gets the cleaned reasoning text (removes leading '>' from blockquote format).
  String get cleanedReasoning {
    return reasoning
        .split('\n')
        .map((line) {
          // Remove leading '>' and optional space (blockquote format from server)
          if (line.startsWith('> ')) return line.substring(2);
          if (line.startsWith('>')) return line.substring(1);
          return line;
        })
        .join('\n')
        .trim();
  }
}

/// Ordered segment that is either plain text or a reasoning entry.
class ReasoningSegment {
  final String? text;
  final ReasoningEntry? entry;

  const ReasoningSegment._({this.text, this.entry});

  factory ReasoningSegment.text(String text) => ReasoningSegment._(text: text);
  factory ReasoningSegment.entry(ReasoningEntry entry) =>
      ReasoningSegment._(entry: entry);

  bool get isReasoning => entry != null;
}

/// Model class for reasoning content (legacy, kept for compatibility).
class ReasoningContent {
  final String reasoning;
  final String summary;
  final int duration;
  final bool isDone;
  final String mainContent;
  final String originalContent;

  const ReasoningContent({
    required this.reasoning,
    required this.summary,
    required this.duration,
    required this.isDone,
    required this.mainContent,
    required this.originalContent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReasoningContent &&
          runtimeType == other.runtimeType &&
          reasoning == other.reasoning &&
          summary == other.summary &&
          duration == other.duration &&
          isDone == other.isDone &&
          mainContent == other.mainContent &&
          originalContent == other.originalContent;

  @override
  int get hashCode =>
      reasoning.hashCode ^
      summary.hashCode ^
      duration.hashCode ^
      isDone.hashCode ^
      mainContent.hashCode ^
      originalContent.hashCode;

  String get formattedDuration => ReasoningParser.formatDuration(duration);

  /// Gets the cleaned reasoning text (removes leading '>').
  String get cleanedReasoning {
    return reasoning
        .split('\n')
        .map((line) {
          if (line.startsWith('> ')) return line.substring(2);
          if (line.startsWith('>')) return line.substring(1);
          return line;
        })
        .join('\n')
        .trim();
  }
}

/// Utility class for parsing and extracting reasoning/thinking content.
class ReasoningParser {
  /// Splits content into ordered segments of plain text and reasoning entries.
  ///
  /// Handles:
  /// - `<details type="reasoning">` blocks with optional summary/duration/done
  /// - Raw tag pairs like `<think>`, `<thinking>`, `<reasoning>`, etc.
  /// - Incomplete/streaming cases by emitting a partial reasoning entry
  static List<ReasoningSegment>? segments(
    String content, {
    List<(String, String)>? customTagPairs,
    bool detectDefaultTags = true,
  }) {
    if (content.isEmpty) return null;

    // Build the list of raw tag pairs to detect
    final tagPairs = <(String, String)>[];
    if (customTagPairs != null) {
      tagPairs.addAll(customTagPairs);
    }
    if (detectDefaultTags) {
      tagPairs.addAll(defaultReasoningTagPairs);
    }

    final segments = <ReasoningSegment>[];
    int index = 0;

    while (index < content.length) {
      // Find the earliest match: either <details type="reasoning" or a raw tag
      int nextDetailsIdx = -1;
      int nextRawIdx = -1;
      (String, String)? matchedRawPair;

      // Check for <details type="reasoning"
      final detailsMatch = RegExp(
        r'<details\s+[^>]*type="reasoning"',
      ).firstMatch(content.substring(index));
      if (detailsMatch != null) {
        nextDetailsIdx = index + detailsMatch.start;
      }

      // Check for raw tag pairs
      for (final pair in tagPairs) {
        final startTag = pair.$1;
        final idx = content.indexOf(startTag, index);
        if (idx != -1 && (nextRawIdx == -1 || idx < nextRawIdx)) {
          nextRawIdx = idx;
          matchedRawPair = pair;
        }
      }

      // Determine which comes first
      final int nextIdx;
      final String kind;
      if (nextDetailsIdx == -1 && nextRawIdx == -1) {
        // No more reasoning blocks
        if (index < content.length) {
          final remaining = content.substring(index);
          if (remaining.trim().isNotEmpty) {
            segments.add(ReasoningSegment.text(remaining));
          }
        }
        break;
      } else if (nextDetailsIdx != -1 &&
          (nextRawIdx == -1 || nextDetailsIdx <= nextRawIdx)) {
        nextIdx = nextDetailsIdx;
        kind = 'details';
      } else {
        nextIdx = nextRawIdx;
        kind = 'raw';
      }

      // Add text before this block
      if (nextIdx > index) {
        final textBefore = content.substring(index, nextIdx);
        if (textBefore.trim().isNotEmpty) {
          segments.add(ReasoningSegment.text(textBefore));
        }
      }

      if (kind == 'details') {
        // Parse <details type="reasoning"> block and extract ReasoningEntry
        final result = _parseDetailsReasoning(content, nextIdx);
        segments.add(ReasoningSegment.entry(result.entry));

        if (!result.isComplete) {
          // Incomplete block, stop here
          break;
        }
        index = result.endIndex;
      } else if (kind == 'raw' && matchedRawPair != null) {
        // Parse raw tag pair
        final result = _parseRawReasoning(
          content,
          nextIdx,
          matchedRawPair.$1,
          matchedRawPair.$2,
        );
        segments.add(ReasoningSegment.entry(result.entry));

        if (!result.isComplete) {
          // Incomplete block, stop here
          break;
        }
        index = result.endIndex;
      }
    }

    return segments.isEmpty ? null : segments;
  }

  /// Parse a `<details type="reasoning">` block starting at the given index.
  static _ReasoningResult _parseDetailsReasoning(String content, int startIdx) {
    // Find the opening tag end
    final openTagEnd = content.indexOf('>', startIdx);
    if (openTagEnd == -1) {
      // Incomplete opening tag
      return _ReasoningResult(
        entry: ReasoningEntry(
          reasoning: '',
          summary: '',
          duration: 0,
          isDone: false,
        ),
        endIndex: content.length,
        isComplete: false,
      );
    }

    final openTag = content.substring(startIdx, openTagEnd + 1);

    // Parse attributes
    final attrs = <String, String>{};
    final attrRegex = RegExp(r'(\w+)="([^"]*)"');
    for (final m in attrRegex.allMatches(openTag)) {
      attrs[m.group(1)!] = m.group(2) ?? '';
    }

    final isDone = (attrs['done'] ?? 'true') == 'true';
    final duration = int.tryParse(attrs['duration'] ?? '0') ?? 0;

    // Find matching closing tag with nesting support
    int depth = 1;
    int i = openTagEnd + 1;
    while (i < content.length && depth > 0) {
      final nextOpen = content.indexOf('<details', i);
      final nextClose = content.indexOf('</details>', i);
      if (nextClose == -1) break;
      if (nextOpen != -1 && nextOpen < nextClose) {
        depth++;
        i = nextOpen + '<details'.length;
      } else {
        depth--;
        i = nextClose + '</details>'.length;
      }
    }

    if (depth != 0) {
      // Incomplete block (streaming)
      final innerContent = content.substring(openTagEnd + 1);
      final summaryResult = _extractSummary(innerContent);

      return _ReasoningResult(
        entry: ReasoningEntry(
          reasoning: HtmlUtils.unescapeHtml(summaryResult.remaining),
          summary: HtmlUtils.unescapeHtml(summaryResult.summary),
          duration: duration,
          isDone: false,
        ),
        endIndex: content.length,
        isComplete: false,
      );
    }

    // Complete block
    final closeIdx = i - '</details>'.length;
    final innerContent = content.substring(openTagEnd + 1, closeIdx);
    final summaryResult = _extractSummary(innerContent);

    return _ReasoningResult(
      entry: ReasoningEntry(
        reasoning: HtmlUtils.unescapeHtml(summaryResult.remaining),
        summary: HtmlUtils.unescapeHtml(summaryResult.summary),
        duration: duration,
        isDone: isDone,
      ),
      endIndex: i,
      isComplete: true,
    );
  }

  /// Parse a raw reasoning tag pair (e.g., `<think>...</think>`).
  static _ReasoningResult _parseRawReasoning(
    String content,
    int startIdx,
    String startTag,
    String endTag,
  ) {
    final endIdx = content.indexOf(endTag, startIdx + startTag.length);

    if (endIdx == -1) {
      // Incomplete block (streaming)
      final innerContent = content.substring(startIdx + startTag.length);
      return _ReasoningResult(
        entry: ReasoningEntry(
          reasoning: HtmlUtils.unescapeHtml(innerContent.trim()),
          summary: '',
          duration: 0,
          isDone: false,
        ),
        endIndex: content.length,
        isComplete: false,
      );
    }

    // Complete block
    final innerContent = content.substring(startIdx + startTag.length, endIdx);
    return _ReasoningResult(
      entry: ReasoningEntry(
        reasoning: HtmlUtils.unescapeHtml(innerContent.trim()),
        summary: '',
        duration: 0,
        isDone: true,
      ),
      endIndex: endIdx + endTag.length,
      isComplete: true,
    );
  }

  /// Extract `<summary>...</summary>` from content.
  static _SummaryResult _extractSummary(String content) {
    final summaryRegex = RegExp(
      r'^\s*<summary>(.*?)</summary>\s*',
      dotAll: true,
    );
    final match = summaryRegex.firstMatch(content);

    if (match != null) {
      return _SummaryResult(
        summary: (match.group(1) ?? '').trim(),
        remaining: content.substring(match.end).trim(),
      );
    }

    return _SummaryResult(summary: '', remaining: content.trim());
  }

  /// Parses a message and extracts the first reasoning content block.
  /// Returns null if no reasoning content is found.
  static ReasoningContent? parseReasoningContent(
    String content, {
    List<(String, String)>? customTagPairs,
    bool detectDefaultTags = true,
  }) {
    final segs = segments(
      content,
      customTagPairs: customTagPairs,
      detectDefaultTags: detectDefaultTags,
    );
    if (segs == null || segs.isEmpty) return null;

    // Find the first reasoning entry
    ReasoningEntry? firstEntry;
    final textParts = <String>[];

    for (final seg in segs) {
      if (seg.isReasoning && firstEntry == null) {
        firstEntry = seg.entry;
      } else if (seg.text != null) {
        textParts.add(seg.text!);
      }
    }

    if (firstEntry == null) return null;

    return ReasoningContent(
      reasoning: firstEntry.reasoning,
      summary: firstEntry.summary,
      duration: firstEntry.duration,
      isDone: firstEntry.isDone,
      mainContent: textParts.join().trim(),
      originalContent: content,
    );
  }

  /// Checks if a message contains reasoning content.
  static bool hasReasoningContent(String content) {
    // Check for <details type="reasoning"
    if (content.contains('type="reasoning"')) return true;

    // Check for raw tag pairs
    for (final pair in defaultReasoningTagPairs) {
      if (content.contains(pair.$1)) return true;
    }

    return false;
  }

  /// Formats the duration for display.
  static String formatDuration(int seconds) {
    if (seconds <= 0) return 'instant';
    if (seconds < 60) return '$seconds second${seconds == 1 ? '' : 's'}';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }

    return '$minutes min ${remainingSeconds}s';
  }
}

class _ReasoningResult {
  final ReasoningEntry entry;
  final int endIndex;
  final bool isComplete;

  const _ReasoningResult({
    required this.entry,
    required this.endIndex,
    required this.isComplete,
  });
}

class _SummaryResult {
  final String summary;
  final String remaining;

  const _SummaryResult({required this.summary, required this.remaining});
}
