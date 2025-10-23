import 'dart:io' show Platform;

import 'package:conduit/core/providers/app_providers.dart';
import 'package:conduit/l10n/app_localizations.dart';
import 'package:conduit/shared/theme/theme_extensions.dart';
import 'package:conduit/shared/widgets/themed_dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:conduit/features/chat/providers/chat_providers.dart' as chat;

class ConduitContextMenuAction {
  final IconData cupertinoIcon;
  final IconData materialIcon;
  final String label;
  final Future<void> Function() onSelected;
  final VoidCallback? onBeforeClose;
  final bool destructive;

  const ConduitContextMenuAction({
    required this.cupertinoIcon,
    required this.materialIcon,
    required this.label,
    required this.onSelected,
    this.onBeforeClose,
    this.destructive = false,
  });
}

Future<void> showConduitContextMenu({
  required BuildContext context,
  required List<ConduitContextMenuAction> actions,
  Offset? position,
}) async {
  if (actions.isEmpty) return;

  final theme = context.conduitTheme;
  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;

  if (overlay == null) return;

  // Determine menu position
  final Offset menuPosition = position ?? _getDefaultMenuPosition(context);

  final result = await showMenu<ConduitContextMenuAction>(
    context: context,
    position: RelativeRect.fromLTRB(
      menuPosition.dx,
      menuPosition.dy,
      overlay.size.width - menuPosition.dx,
      overlay.size.height - menuPosition.dy,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppBorderRadius.small),
    ),
    color: theme.surfaceBackground,
    elevation: 4,
    items: actions.map((action) {
      return PopupMenuItem<ConduitContextMenuAction>(
        value: action,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        height: 36,
        child: Row(
          children: [
            Icon(
              Platform.isIOS ? action.cupertinoIcon : action.materialIcon,
              color: action.destructive ? Colors.red : theme.iconPrimary,
              size: IconSize.xs,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                action.label,
                style: AppTypography.standard.copyWith(
                  color: action.destructive ? Colors.red : theme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );

  if (result != null) {
    result.onBeforeClose?.call();
    await Future.microtask(result.onSelected);
  }
}

Offset _getDefaultMenuPosition(BuildContext context) {
  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) {
    return Offset.zero;
  }
  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  return Offset(position.dx + size.width, position.dy);
}

Future<void> showConversationContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic conversation,
}) async {
  if (conversation == null) return;

  final l10n = AppLocalizations.of(context)!;
  final bool isPinned = conversation.pinned == true;
  final bool isArchived = conversation.archived == true;

  Future<void> togglePin() async {
    final errorMessage = l10n.failedToUpdatePin;
    try {
      await chat.pinConversation(ref, conversation.id, !isPinned);
    } catch (_) {
      if (!context.mounted) return;
      await _showConversationError(context, errorMessage);
    }
  }

  Future<void> toggleArchive() async {
    final errorMessage = l10n.failedToUpdateArchive;
    try {
      await chat.archiveConversation(ref, conversation.id, !isArchived);
    } catch (_) {
      if (!context.mounted) return;
      await _showConversationError(context, errorMessage);
    }
  }

  Future<void> rename() async {
    await _renameConversation(
      context,
      ref,
      conversation.id,
      conversation.title ?? '',
    );
  }

  Future<void> deleteConversation() async {
    await _confirmAndDeleteConversation(context, ref, conversation.id);
  }

  HapticFeedback.selectionClick();
  await showConduitContextMenu(
    context: context,
    actions: [
      ConduitContextMenuAction(
        cupertinoIcon: isPinned
            ? CupertinoIcons.pin_slash
            : CupertinoIcons.pin_fill,
        materialIcon: isPinned
            ? Icons.push_pin_outlined
            : Icons.push_pin_rounded,
        label: isPinned ? l10n.unpin : l10n.pin,
        onBeforeClose: () => HapticFeedback.lightImpact(),
        onSelected: togglePin,
      ),
      ConduitContextMenuAction(
        cupertinoIcon: isArchived
            ? CupertinoIcons.archivebox_fill
            : CupertinoIcons.archivebox,
        materialIcon: isArchived
            ? Icons.unarchive_rounded
            : Icons.archive_rounded,
        label: isArchived ? l10n.unarchive : l10n.archive,
        onBeforeClose: () => HapticFeedback.lightImpact(),
        onSelected: toggleArchive,
      ),
      ConduitContextMenuAction(
        cupertinoIcon: CupertinoIcons.pencil,
        materialIcon: Icons.edit_rounded,
        label: l10n.rename,
        onBeforeClose: () => HapticFeedback.selectionClick(),
        onSelected: rename,
      ),
      ConduitContextMenuAction(
        cupertinoIcon: CupertinoIcons.delete,
        materialIcon: Icons.delete_rounded,
        label: l10n.delete,
        destructive: true,
        onBeforeClose: () => HapticFeedback.mediumImpact(),
        onSelected: deleteConversation,
      ),
    ],
  );
}

Future<void> _renameConversation(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
  String currentTitle,
) async {
  final l10n = AppLocalizations.of(context)!;
  final newName = await ThemedDialogs.promptTextInput(
    context,
    title: l10n.renameChat,
    hintText: l10n.enterChatName,
    initialValue: currentTitle,
    confirmText: l10n.save,
    cancelText: l10n.cancel,
  );

  if (!context.mounted) return;
  if (newName == null) return;
  if (newName.isEmpty || newName == currentTitle) return;

  final renameError = l10n.failedToRenameChat;
  try {
    final api = ref.read(apiServiceProvider);
    if (api == null) throw Exception('No API service');
    await api.updateConversation(conversationId, title: newName);
    HapticFeedback.selectionClick();
    refreshConversationsCache(ref);
    final active = ref.read(activeConversationProvider);
    if (active?.id == conversationId) {
      ref
          .read(activeConversationProvider.notifier)
          .set(active!.copyWith(title: newName));
    }
  } catch (_) {
    if (!context.mounted) return;
    await _showConversationError(context, renameError);
  }
}

Future<void> _confirmAndDeleteConversation(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await ThemedDialogs.confirm(
    context,
    title: l10n.deleteChatTitle,
    message: l10n.deleteChatMessage,
    confirmText: l10n.delete,
    isDestructive: true,
  );

  if (!context.mounted) return;
  if (!confirmed) return;

  final deleteError = l10n.failedToDeleteChat;
  try {
    final api = ref.read(apiServiceProvider);
    if (api == null) throw Exception('No API service');
    await api.deleteConversation(conversationId);
    HapticFeedback.mediumImpact();
    final active = ref.read(activeConversationProvider);
    if (active?.id == conversationId) {
      ref.read(activeConversationProvider.notifier).clear();
      ref.read(chat.chatMessagesProvider.notifier).clearMessages();
    }
    refreshConversationsCache(ref);
  } catch (_) {
    if (!context.mounted) return;
    await _showConversationError(context, deleteError);
  }
}

Future<void> _showConversationError(
  BuildContext context,
  String message,
) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final theme = context.conduitTheme;
  await ThemedDialogs.show<void>(
    context,
    title: l10n.errorMessage,
    content: Text(message, style: TextStyle(color: theme.textSecondary)),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.ok),
      ),
    ],
  );
}
