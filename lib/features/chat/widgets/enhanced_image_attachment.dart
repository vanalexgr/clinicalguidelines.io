import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'package:conduit/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/providers/unified_auth_providers.dart';
import '../../../core/utils/debug_logger.dart';

// Simple global cache to prevent reloading
final _globalImageCache = <String, String>{};
final _globalLoadingStates = <String, bool>{};
final _globalErrorStates = <String, String>{};
final _globalImageBytesCache = <String, Uint8List>{};
final _base64WhitespacePattern = RegExp(r'\s');

Future<Uint8List> _decodeImageDataAsync(String data) async {
  if (kIsWeb) {
    return _decodeImageData(data);
  }
  return compute(_decodeImageData, data);
}

Uint8List _decodeImageData(String data) {
  var payload = data;
  if (payload.startsWith('data:')) {
    final commaIndex = payload.indexOf(',');
    if (commaIndex == -1) {
      throw FormatException('Invalid data URI');
    }
    payload = payload.substring(commaIndex + 1);
  }
  payload = payload.replaceAll(_base64WhitespacePattern, '');
  return base64.decode(payload);
}

class EnhancedImageAttachment extends ConsumerStatefulWidget {
  final String attachmentId;
  final bool isMarkdownFormat;
  final VoidCallback? onTap;
  final BoxConstraints? constraints;
  final bool isUserMessage;
  final bool disableAnimation;

  const EnhancedImageAttachment({
    super.key,
    required this.attachmentId,
    this.isMarkdownFormat = false,
    this.onTap,
    this.constraints,
    this.isUserMessage = false,
    this.disableAnimation = false,
  });

  @override
  ConsumerState<EnhancedImageAttachment> createState() =>
      _EnhancedImageAttachmentState();
}

class _EnhancedImageAttachmentState
    extends ConsumerState<EnhancedImageAttachment>
    with AutomaticKeepAliveClientMixin {
  String? _cachedImageData;
  Uint8List? _cachedBytes;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDecoding = false;
  late final String _heroTag;
  // Removed unused animation and state flags

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _heroTag = 'image_${widget.attachmentId}_${identityHashCode(this)}';
    // Defer loading until after first frame to avoid accessing inherited widgets
    // (e.g., Localizations) during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadImage();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadImage() async {
    final l10n = AppLocalizations.of(context)!;
    final cachedError = _globalErrorStates[widget.attachmentId];
    if (cachedError != null) {
      if (mounted) {
        setState(() {
          _errorMessage = cachedError;
          _isLoading = false;
        });
      }
      return;
    }

    if (_globalImageCache.containsKey(widget.attachmentId)) {
      final cachedData = _globalImageCache[widget.attachmentId]!;
      final cachedBytes = _globalImageBytesCache[widget.attachmentId];
      if (mounted) {
        setState(() {
          _cachedImageData = cachedData;
          _cachedBytes = cachedBytes;
          _isLoading = cachedBytes == null && !_isRemoteContent(cachedData);
        });
      }
      if (cachedBytes == null && !_isRemoteContent(cachedData)) {
        await _decodeAndAssign(cachedData, l10n);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    _globalLoadingStates[widget.attachmentId] = true;

    final attachmentId = widget.attachmentId;

    if (attachmentId.startsWith('data:') || attachmentId.startsWith('http')) {
      _globalImageCache[attachmentId] = attachmentId;
      _globalLoadingStates[attachmentId] = false;
      final cachedBytes = _globalImageBytesCache[attachmentId];
      if (mounted) {
        setState(() {
          _cachedImageData = attachmentId;
          _cachedBytes = cachedBytes;
          _isLoading = cachedBytes == null && !_isRemoteContent(attachmentId);
        });
      }
      if (!_isRemoteContent(attachmentId) && cachedBytes == null) {
        await _decodeAndAssign(attachmentId, l10n);
      }
      return;
    }

    if (attachmentId.startsWith('/')) {
      final api = ref.read(apiServiceProvider);
      if (api != null) {
        final fullUrl = api.baseUrl + attachmentId;
        _globalImageCache[attachmentId] = fullUrl;
        _globalLoadingStates[attachmentId] = false;
        if (mounted) {
          setState(() {
            _cachedImageData = fullUrl;
            _cachedBytes = null;
            _isLoading = false;
          });
        }
        return;
      } else {
        final error = l10n.unableToLoadImage;
        _cacheError(error);
        return;
      }
    }

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      final error = l10n.apiUnavailable;
      _cacheError(error);
      return;
    }

    try {
      final fileInfo = await api.getFileInfo(attachmentId);
      final fileName = _extractFileName(fileInfo);
      final ext = fileName.toLowerCase().split('.').last;

      if (!['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) {
        final error = l10n.notAnImageFile(fileName);
        _cacheError(error);
        return;
      }

      final fileContent = await api.getFileContent(attachmentId);

      _globalImageCache[attachmentId] = fileContent;
      _globalLoadingStates[attachmentId] = false;

      if (_globalImageCache.length > 50) {
        final firstKey = _globalImageCache.keys.first;
        _globalImageCache.remove(firstKey);
        _globalLoadingStates.remove(firstKey);
        _globalErrorStates.remove(firstKey);
        _globalImageBytesCache.remove(firstKey);
      }

      if (mounted) {
        setState(() {
          _cachedImageData = fileContent;
          _cachedBytes = null;
          _isLoading = !_isRemoteContent(fileContent);
        });
      }

      if (_isRemoteContent(fileContent)) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      await _decodeAndAssign(fileContent, l10n);
    } catch (e) {
      final error = l10n.failedToLoadImage(e.toString());
      _cacheError(error);
    }
  }

  bool _isRemoteContent(String data) => data.startsWith('http');

  Future<void> _decodeAndAssign(String data, AppLocalizations l10n) async {
    if (_isDecoding) return;
    _isDecoding = true;
    try {
      final bytes = await _decodeImageDataAsync(data);
      _globalImageBytesCache[widget.attachmentId] = bytes;
      if (!mounted) return;
      setState(() {
        _cachedBytes = bytes;
        _isLoading = false;
      });
    } on FormatException {
      final error = l10n.invalidImageFormat;
      _cacheError(error);
    } catch (_) {
      final error = l10n.failedToDecodeImage;
      _cacheError(error);
    } finally {
      _isDecoding = false;
    }
  }

  void _cacheError(String error) {
    _globalErrorStates[widget.attachmentId] = error;
    _globalLoadingStates[widget.attachmentId] = false;
    _globalImageCache.remove(widget.attachmentId);
    _globalImageBytesCache.remove(widget.attachmentId);
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = error;
      _cachedBytes = null;
      _isLoading = false;
    });
  }

  String _extractFileName(Map<String, dynamic> fileInfo) {
    return fileInfo['filename'] ??
        fileInfo['meta']?['name'] ??
        fileInfo['name'] ??
        fileInfo['file_name'] ??
        fileInfo['original_name'] ??
        fileInfo['original_filename'] ??
        'unknown';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Directly return content without AnimatedSwitcher to prevent black flash during streaming
    return _buildContent();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_cachedImageData == null) {
      return const SizedBox.shrink();
    }

    // Handle different image data formats
    Widget imageWidget;
    if (_cachedImageData!.startsWith('http')) {
      imageWidget = _buildNetworkImage();
    } else {
      imageWidget = _buildBase64Image();
    }

    // Always show the image without fade transitions during streaming to prevent black display
    // The AutomaticKeepAliveClientMixin and global caching should preserve the image state
    return imageWidget;
  }

  Widget _buildLoadingState() {
    final constraints =
        widget.constraints ??
        const BoxConstraints(
          maxWidth: 300,
          maxHeight: 300,
          minHeight: 150,
          minWidth: 200,
        );

    return Container(
      key: const ValueKey('loading'),
      constraints: constraints,
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      decoration: BoxDecoration(
        color: context.conduitTheme.surfaceBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: context.conduitTheme.dividerColor.withValues(alpha: 0.3),
          width: BorderWidth.thin,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect placeholder
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.conduitTheme.shimmerBase,
                      context.conduitTheme.shimmerHighlight,
                      context.conduitTheme.shimmerBase,
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: const Duration(milliseconds: 1500),
                color: context.conduitTheme.shimmerHighlight.withValues(
                  alpha: 0.3,
                ),
              ),
          // Progress indicator overlay
          CircularProgressIndicator(
            color: context.conduitTheme.buttonPrimary,
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      key: const ValueKey('error'),
      constraints:
          widget.constraints ??
          const BoxConstraints(
            maxWidth: 300,
            maxHeight: 150,
            minHeight: 100,
            minWidth: 200,
          ),
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      decoration: BoxDecoration(
        color: context.conduitTheme.surfaceBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: context.conduitTheme.error.withValues(alpha: 0.3),
          width: BorderWidth.thin,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: context.conduitTheme.error,
            size: 32,
          ),
          const SizedBox(height: Spacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: context.conduitTheme.error,
                fontSize: AppTypography.bodySmall,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildNetworkImage() {
    // Get authentication headers if available
    final api = ref.read(apiServiceProvider);
    final authToken = ref.read(authTokenProvider3);
    final headers = <String, String>{};

    // Add auth token from unified auth provider
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    } else if (api?.serverConfig.apiKey != null &&
        api!.serverConfig.apiKey!.isNotEmpty) {
      // Fallback to API key from server config
      headers['Authorization'] = 'Bearer ${api.serverConfig.apiKey}';
    }

    // Add any custom headers from server config
    if (api != null && api.serverConfig.customHeaders.isNotEmpty) {
      headers.addAll(api.serverConfig.customHeaders);
    }

    final imageWidget = CachedNetworkImage(
      key: ValueKey('image_${widget.attachmentId}'),
      imageUrl: _cachedImageData!,
      fit: BoxFit.cover,
      httpHeaders: headers.isNotEmpty ? headers : null,
      fadeInDuration: widget.disableAnimation
          ? Duration.zero
          : const Duration(milliseconds: 200),
      fadeOutDuration: widget.disableAnimation
          ? Duration.zero
          : const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        constraints: widget.constraints,
        decoration: BoxDecoration(
          color: context.conduitTheme.shimmerBase,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
      errorWidget: (context, url, error) {
        _errorMessage = error.toString();
        return _buildErrorState();
      },
    );

    return _wrapImage(imageWidget);
  }

  Widget _buildBase64Image() {
    final bytes = _cachedBytes;
    if (bytes == null) {
      return _buildLoadingState();
    }

    final imageWidget = Image.memory(
      key: ValueKey('image_${widget.attachmentId}'),
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true, // Prevents flashing during rebuilds
      errorBuilder: (context, error, stackTrace) {
        _errorMessage = AppLocalizations.of(context)!.failedToDecodeImage;
        return _buildErrorState();
      },
    );

    return _wrapImage(imageWidget);
  }

  Widget _wrapImage(Widget imageWidget) {
    final wrappedImage = Container(
      constraints:
          widget.constraints ??
          const BoxConstraints(maxWidth: 400, maxHeight: 400),
      margin: widget.isMarkdownFormat
          ? const EdgeInsets.symmetric(vertical: Spacing.sm)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        // Add subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: context.conduitTheme.cardShadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap ?? () => _showFullScreenImage(context),
            child: Hero(
              tag: _heroTag,
              flightShuttleBuilder:
                  (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    final hero = flightDirection == HeroFlightDirection.push
                        ? fromHeroContext.widget as Hero
                        : toHeroContext.widget as Hero;
                    return FadeTransition(
                      opacity: animation,
                      child: hero.child,
                    );
                  },
              child: imageWidget,
            ),
          ),
        ),
      ),
    );

    return wrappedImage;
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            FullScreenImageViewer(imageData: _cachedImageData!, tag: _heroTag),
      ),
    );
  }
}

class FullScreenImageViewer extends ConsumerWidget {
  final String imageData;
  final String tag;

  const FullScreenImageViewer({
    super.key,
    required this.imageData,
    required this.tag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget imageWidget;

    if (imageData.startsWith('http')) {
      // Get authentication headers if available
      final api = ref.read(apiServiceProvider);
      final authToken = ref.read(authTokenProvider3);
      final headers = <String, String>{};

      // Add auth token from unified auth provider
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      } else if (api?.serverConfig.apiKey != null &&
          api!.serverConfig.apiKey!.isNotEmpty) {
        // Fallback to API key from server config
        headers['Authorization'] = 'Bearer ${api.serverConfig.apiKey}';
      }

      // Add any custom headers from server config
      if (api != null && api.serverConfig.customHeaders.isNotEmpty) {
        headers.addAll(api.serverConfig.customHeaders);
      }

      imageWidget = CachedNetworkImage(
        imageUrl: imageData,
        fit: BoxFit.contain,
        httpHeaders: headers.isNotEmpty ? headers : null,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: context.conduitTheme.buttonPrimary,
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            Icons.error_outline,
            color: context.conduitTheme.error,
            size: 48,
          ),
        ),
      );
    } else {
      try {
        String actualBase64;
        if (imageData.startsWith('data:')) {
          final commaIndex = imageData.indexOf(',');
          actualBase64 = imageData.substring(commaIndex + 1);
        } else {
          actualBase64 = imageData;
        }
        final imageBytes = base64.decode(actualBase64);
        imageWidget = Image.memory(imageBytes, fit: BoxFit.contain);
      } catch (e) {
        imageWidget = Center(
          child: Icon(
            Icons.error_outline,
            color: context.conduitTheme.error,
            size: 48,
          ),
        );
      }
    }

    final tokens = context.colorTokens;
    final background = tokens.neutralTone10;
    final iconColor = tokens.neutralOnSurface;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: imageWidget,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Platform.isIOS ? Icons.ios_share : Icons.share_outlined,
                    color: iconColor,
                    size: 26,
                  ),
                  onPressed: () => _shareImage(context, ref),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: iconColor, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      Uint8List bytes;
      String? fileExtension;

      if (imageData.startsWith('http')) {
        final api = ref.read(apiServiceProvider);
        final authToken = ref.read(authTokenProvider3);
        final headers = <String, String>{};

        if (authToken != null && authToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $authToken';
        } else if (api?.serverConfig.apiKey != null &&
            api!.serverConfig.apiKey!.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${api.serverConfig.apiKey}';
        }
        if (api != null && api.serverConfig.customHeaders.isNotEmpty) {
          headers.addAll(api.serverConfig.customHeaders);
        }

        final client = api?.dio ?? dio.Dio();
        final response = await client.get<List<int>>(
          imageData,
          options: dio.Options(
            responseType: dio.ResponseType.bytes,
            headers: headers.isNotEmpty ? headers : null,
          ),
        );
        final data = response.data;
        if (data == null || data.isEmpty) {
          throw Exception(l10n.emptyImageData);
        }
        bytes = Uint8List.fromList(data);

        final contentType = response.headers.map['content-type']?.first;
        if (contentType != null && contentType.startsWith('image/')) {
          fileExtension = contentType.split('/').last;
          if (fileExtension == 'jpeg') fileExtension = 'jpg';
        } else {
          final uri = Uri.tryParse(imageData);
          final lastSegment = uri?.pathSegments.isNotEmpty == true
              ? uri!.pathSegments.last
              : '';
          final dotIndex = lastSegment.lastIndexOf('.');
          if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
            final ext = lastSegment.substring(dotIndex + 1).toLowerCase();
            if (ext.length <= 5) {
              fileExtension = ext;
            }
          }
        }
      } else {
        String actualBase64 = imageData;
        if (imageData.startsWith('data:')) {
          final commaIndex = imageData.indexOf(',');
          final meta = imageData.substring(5, commaIndex); // image/png;base64
          final slashIdx = meta.indexOf('/');
          final semicolonIdx = meta.indexOf(';');
          if (slashIdx != -1 && semicolonIdx != -1 && slashIdx < semicolonIdx) {
            final subtype = meta.substring(slashIdx + 1, semicolonIdx);
            fileExtension = subtype == 'jpeg' ? 'jpg' : subtype;
          }
          actualBase64 = imageData.substring(commaIndex + 1);
        }
        bytes = base64.decode(actualBase64);
      }

      fileExtension ??= 'png';
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/conduit_shared_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      // Swallowing UI feedback per requirements; keep a log for debugging
      DebugLogger.log(
        'Failed to share image: $e',
        scope: 'chat/image-attachment',
      );
    }
  }
}
