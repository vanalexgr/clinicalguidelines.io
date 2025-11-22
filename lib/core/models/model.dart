import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';

@freezed
sealed class Model with _$Model {
  const Model._();

  const factory Model({
    required String id,
    required String name,
    String? description,
    @Default(false) bool isMultimodal,
    @Default(false) bool supportsStreaming,
    @Default(false) bool supportsRAG,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? metadata,
    List<String>? supportedParameters,
    List<String>? toolIds,
  }) = _Model;

  factory Model.fromJson(Map<String, dynamic> json) {
    final cachedIsMultimodal = switch (json['isMultimodal']) {
      final bool value => value,
      _ => json['is_multimodal'] is bool ? json['is_multimodal'] as bool : null,
    };
    final cachedSupportsStreaming = switch (json['supportsStreaming']) {
      final bool value => value,
      _ =>
        json['supports_streaming'] is bool
            ? json['supports_streaming'] as bool
            : null,
    };

    // Handle different response formats from OpenWebUI

    // Extract architecture info for capabilities
    final architecture = json['architecture'] as Map<String, dynamic>?;
    final modality = architecture?['modality'] as String?;
    final inputModalities = architecture?['input_modalities'] as List?;

    // Determine if multimodal based on architecture
    final isMultimodal =
        cachedIsMultimodal ??
        (modality?.contains('image') == true ||
            inputModalities?.contains('image') == true);

    // Extract supported parameters robustly (top-level or nested under provider keys)
    List? supportedParams =
        (json['supported_parameters'] as List?) ??
        (json['supportedParameters'] as List?);

    if (supportedParams == null) {
      const providerKeys = [
        'openai',
        'anthropic',
        'google',
        'meta',
        'mistral',
        'cohere',
        'xai',
        'perplexity',
        'deepseek',
        'groq',
      ];
      for (final key in providerKeys) {
        final provider = json[key] as Map<String, dynamic>?;
        final list =
            (provider?['supported_parameters'] as List?) ??
            (provider?['supportedParameters'] as List?);
        if (list != null) {
          supportedParams = list;
          break;
        }
      }
    }

    // Determine streaming support from supported parameters if known
    final supportsStreaming =
        cachedSupportsStreaming ?? supportedParams?.contains('stream') ?? true;

    // Convert supported parameters to List<String> if present
    final supportedParamsList = supportedParams
        ?.map((e) => e.toString())
        .toList();

    final baseMetadata = Map<String, dynamic>.from(
      (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );

    final metaSection = json['meta'] as Map<String, dynamic>?;
    final infoSection = json['info'] as Map<String, dynamic>?;

    String? profileImage = json['profile_image_url'] as String?;
    profileImage ??= baseMetadata['profile_image_url'] as String?;
    profileImage ??= metaSection?['profile_image_url'] as String?;
    profileImage ??=
        (infoSection?['meta'] as Map<String, dynamic>?)?['profile_image_url']
            as String?;

    final mergedMetadata = <String, dynamic>{
      ...baseMetadata,
      if (json['canonical_slug'] != null)
        'canonical_slug':
            baseMetadata['canonical_slug'] ?? json['canonical_slug'],
      if (json['created'] != null)
        'created': baseMetadata['created'] ?? json['created'],
      if (json['connection_type'] != null)
        'connection_type':
            baseMetadata['connection_type'] ?? json['connection_type'],
    };

    if (profileImage != null && profileImage.isNotEmpty) {
      mergedMetadata['profile_image_url'] = profileImage;
    }

    if (metaSection != null) {
      final existing =
          (mergedMetadata['meta'] as Map<String, dynamic>?) ?? const {};
      mergedMetadata['meta'] = {...existing, ...metaSection};
    }

    if (infoSection != null) {
      final existingInfo =
          (mergedMetadata['info'] as Map<String, dynamic>?) ?? const {};
      mergedMetadata['info'] = {...existingInfo, ...infoSection};
    }

    // Extract toolIds from info.meta.toolIds (OpenWebUI format)
    List<String>? toolIds;
    final infoMeta =
        (infoSection?['meta'] as Map<String, dynamic>?) ??
        (metaSection) ??
        (mergedMetadata['meta'] as Map<String, dynamic>?);
    if (infoMeta != null) {
      final toolIdsData = infoMeta['toolIds'];
      if (toolIdsData is List) {
        toolIds = toolIdsData.map((e) => e.toString()).toList();
      }
    }

    final idRaw = json['id'];
    final id = idRaw?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Model JSON missing required "id" field.');
    }

    final nameRaw = json['name'];
    final name = (nameRaw == null || nameRaw.toString().trim().isEmpty)
        ? id
        : nameRaw.toString();

    return Model(
      id: id,
      name: name,
      description: json['description'] as String?,
      isMultimodal: isMultimodal,
      supportsStreaming: supportsStreaming,
      supportsRAG: json['supportsRAG'] as bool? ?? false,
      supportedParameters: supportedParamsList,
      capabilities: {
        'architecture': architecture,
        'pricing': json['pricing'],
        'context_length': json['context_length'],
        'supported_parameters': supportedParamsList ?? supportedParams,
      },
      metadata: mergedMetadata,
      toolIds: toolIds,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'isMultimodal': isMultimodal,
      'supportsStreaming': supportsStreaming,
      'supportsRAG': supportsRAG,
      'supported_parameters': supportedParameters,
      'capabilities': capabilities,
      'metadata': metadata,
      'architecture': capabilities?['architecture'],
      'toolIds': toolIds,
    };
    data.removeWhere((_, value) => value == null);
    return data;
  }
}
