import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/widgets/anchored_popover.dart';
import '../../reflections/presentation/widgets/apple_morph_route.dart';
import '../../settings/presentation/widgets/settings_ui_components.dart';
import '../application/ai_providers.dart';
import '../domain/ai_local_model_spec.dart';
import '../domain/ai_message.dart';
import '../domain/ai_provider_config.dart';
import '../domain/ai_tool_call.dart';
import 'ai_settings_page.dart';
import 'widgets/ai_setup_and_review.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.initialPrompt});

  final String? initialPrompt;

  static Future<void> open(
    BuildContext context, {
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 12,
    String? initialPrompt,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push<void>(
      AppleMorphRoute<void>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => AiChatScreen(initialPrompt: initialPrompt),
      ),
    );
  }

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _menuKey = GlobalKey();
  bool _sentInitialPrompt = false;

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _sentInitialPrompt) return;
        if (!ref.read(aiConfigProvider).isConfigured) return;
        _sentInitialPrompt = true;
        _handleSend(prompt);
      });
    }
  }

  static const _starterPrompts = [
    'قيّم توزيع مهامي بين الصلوات اليوم',
    'هل لدي تعارض أو ضغط بين المغرب والعشاء؟',
    'اقترح لي خطة بسيطة لتحسين التزامي هذا الأسبوع',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty) return;

    final perms = ref.read(aiPermissionsProvider);
    final alreadyApproved = ref.read(aiReflectionSummaryApprovedProvider);
    if (!perms.allowReflections &&
        perms.allowReflectionSummary &&
        !alreadyApproved) {
      final summary =
          ref.read(aiChatProvider.notifier).previewReflectionSummary();
      if (summary.count > 0 && mounted) {
        final approved =
            await showReflectionSummaryReviewSheet(context, summary);
        if (!mounted) return;
        ref.read(aiReflectionSummaryApprovedProvider.notifier).state =
            approved == true;
      }
    }

    if (preset == null) _inputController.clear();
    HapticFeedback.lightImpact();
    _scrollToBottom();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  String _activeModelSubtitle(AiProviderConfig config) {
    if (config.type == AiProviderType.groqCloud) {
      return config.groqModel == AiProviderConfig.fastGroqModel
          ? 'سحابي · GPT-OSS 20B'
          : 'سحابي · Qwen 3.8 27B';
    }
    final spec = LocalModelSpec.catalog
        .where((m) => m.id == config.localModelId)
        .firstOrNull;
    return spec != null ? 'محلي · ${spec.displayName}' : 'محلي · غير محدد';
  }

  void _openModelSwitcher(BuildContext anchorContext) {
    HapticFeedback.selectionClick();
    final config = ref.read(aiConfigProvider);
    final downloaded =
        ref.read(downloadedModelsProvider).valueOrNull ?? const {};
    final hasCloudKey =
        config.groqApiKey != null && config.groqApiKey!.trim().isNotEmpty;

    showAnchoredPopover<void>(
      anchorContext,
      width: 265,
      preferAbove: false,
      builder: (popCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCloudKey) ...[
            PopoverActionRow(
              icon: config.type == AiProviderType.groqCloud &&
                      config.groqModel == AiProviderConfig.defaultGroqModel
                  ? Icons.check_circle_rounded
                  : Icons.cloud_outlined,
              color: const Color(0xFF007AFF),
              label: 'سحابي · Qwen 3.8 27B',
              onTap: () {
                Navigator.of(popCtx).pop();
                ref.read(aiConfigProvider.notifier).updateConfig(
                      config.copyWith(
                        type: AiProviderType.groqCloud,
                        groqModel: AiProviderConfig.defaultGroqModel,
                      ),
                    );
              },
            ),
            PopoverActionRow(
              icon: config.type == AiProviderType.groqCloud &&
                      config.groqModel == AiProviderConfig.fastGroqModel
                  ? Icons.check_circle_rounded
                  : Icons.cloud_outlined,
              color: const Color(0xFF007AFF),
              label: 'سحابي · GPT-OSS 20B',
              onTap: () {
                Navigator.of(popCtx).pop();
                ref.read(aiConfigProvider.notifier).updateConfig(
                      config.copyWith(
                        type: AiProviderType.groqCloud,
                        groqModel: AiProviderConfig.fastGroqModel,
                      ),
                    );
              },
            ),
          ],
          for (final spec in LocalModelSpec.catalog)
            if (downloaded.containsKey(spec.id))
              PopoverActionRow(
                icon: config.type == AiProviderType.localLlm &&
                        config.localModelId == spec.id
                    ? Icons.check_circle_rounded
                    : Icons.smartphone_rounded,
                color: const Color(0xFF5856D6),
                label: 'محلي · ${spec.displayName}',
                onTap: () {
                  Navigator.of(popCtx).pop();
                  ref.read(aiConfigProvider.notifier).updateConfig(
                        config.copyWith(
                          type: AiProviderType.localLlm,
                          localModelId: spec.id,
                          localModelPath: downloaded[spec.id],
                        ),
                      );
                },
              ),
          PopoverActionRow(
            icon: Icons.tune_rounded,
            color: const Color(0xFF34C759),
            label: 'إدارة النماذج والإعدادات',
            onTap: () {
              Navigator.of(popCtx).pop();
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const AiSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext anchorContext) {
    HapticFeedback.selectionClick();
    final sessions = ref.read(aiSessionsProvider);
    final activeId = ref.read(aiActiveSessionIdProvider);
    showAnchoredPopover<void>(
      anchorContext,
      width: 245,
      preferAbove: false,
      builder: (popCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopoverActionRow(
            icon: Icons.add_comment_outlined,
            color: const Color(0xFF5856D6),
            label: 'محادثة جديدة',
            onTap: () {
              Navigator.of(popCtx).pop();
              ref.read(aiChatProvider.notifier).startNewSession();
            },
          ),
          if (sessions.isNotEmpty)
            PopoverActionRow(
              icon: Icons.history_rounded,
              color: const Color(0xFFFF9500),
              label: 'المحادثات السابقة (${sessions.length})',
              onTap: () {
                Navigator.of(popCtx).pop();
                _showSessionsSheet(sessions, activeId);
              },
            ),
          PopoverActionRow(
            icon: Icons.tune_rounded,
            color: const Color(0xFF007AFF),
            label: 'الإعدادات والصلاحيات',
            onTap: () {
              Navigator.of(popCtx).pop();
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const AiSettingsPage(),
                ),
              );
            },
          ),
          PopoverActionRow(
            icon: Icons.shield_outlined,
            color: const Color(0xFF34C759),
            label: 'معاينة ملخص التأملات',
            onTap: () async {
              Navigator.of(popCtx).pop();
              final summary =
                  ref.read(aiChatProvider.notifier).previewReflectionSummary();
              final approved =
                  await showReflectionSummaryReviewSheet(context, summary);
              if (approved != null) {
                ref.read(aiReflectionSummaryApprovedProvider.notifier).state =
                    approved;
              }
            },
          ),
          PopoverActionRow(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFFF3B30),
            label: 'حذف المحادثة الحالية',
            isDestructive: true,
            onTap: () {
              Navigator.of(popCtx).pop();
              ref.read(aiChatProvider.notifier).clearHistory();
            },
          ),
        ],
      ),
    );
  }

  void _showSessionsSheet(List<dynamic> sessions, String? activeId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المحادثات السابقة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    final isActive = s.id == activeId;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isActive
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.55),
                        size: 19,
                      ),
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text('${s.messages.length} رسالة'),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(aiChatProvider.notifier).switchSession(s.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);
    final chatAsync = ref.watch(aiChatProvider);
    final isStreaming = ref.watch(aiIsStreamingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Builder(
          builder: (titleCtx) => PressableScale(
            onTap: () => _openModelSwitcher(titleCtx),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SettingsIconBadge(
                  icon: Icons.auto_awesome_rounded,
                  color: Color(0xFF5856D6),
                  size: 32,
                  iconSize: 18,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RibatAI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeModelSubtitle(config),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          Builder(
            key: _menuKey,
            builder: (btnCtx) => IconButton(
              onPressed: () => _openMenu(btnCtx),
              icon: const Icon(Icons.more_horiz_rounded),
              tooltip: 'خيارات',
            ),
          ),
        ],
      ),
      body: !config.isConfigured
          ? const AiSetupView()
          : Column(
              children: [
                Expanded(
                  child: chatAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Center(
                      child: Text('تعذر تحميل المحادثات السابقة.'),
                    ),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return _buildEmptyState(theme, colorScheme);
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        itemCount: messages.length,
                        itemBuilder: (_, index) {
                          final msg = messages[index];
                          final isLast = index == messages.length - 1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AiChatBubble(
                                message: msg,
                                isStreaming: isStreaming &&
                                    isLast &&
                                    msg.role == AiRole.assistant,
                              ),
                              for (final action in msg.proposedActions)
                                _ToolActionCard(
                                  messageId: msg.id,
                                  action: action,
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputBar(theme, colorScheme, isStreaming),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Center(
          child: Text(
            'كيف أساعدك اليوم في تنظيم وقتك؟',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final prompt in _starterPrompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PressableScale(
              onTap: () => _handleSend(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined,
                        size: 17, color: Color(0xFF5856D6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isStreaming,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك لـ RibatAI…',
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PressableScale(
              onTap: isStreaming
                  ? () {
                      HapticFeedback.selectionClick();
                      ref.read(aiChatProvider.notifier).stopGeneration();
                    }
                  : () => _handleSend(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isStreaming
                      ? const Color(0xFFFF3B30)
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStreaming ? Icons.stop_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({
    required this.message,
    required this.isStreaming,
  });

  final AiMessage message;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == AiRole.user;

    final bgColor = message.isError
        ? const Color(0xFFFF3B30).withValues(alpha: 0.11)
        : (isUser ? colorScheme.primary : theme.cardColor);
    final textColor = message.isError
        ? const Color(0xFFFF3B30)
        : (isUser ? Colors.white : colorScheme.onSurface);

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: isUser || message.isError
              ? null
              : Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
        ),
        child: message.content.isEmpty && isStreaming
            ? Text(
                'يكتب…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            : isUser || message.isError
                ? SelectableText(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.55,
                          ),
                          h1: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                          h2: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                          h3: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                          listBullet: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                      if (!isStreaming) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Clipboard.setData(
                                ClipboardData(text: message.content),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الرد'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.48),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _ToolActionCard extends ConsumerWidget {
  const _ToolActionCard({
    required this.messageId,
    required this.action,
  });

  final String messageId;
  final ProposedToolAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final call = action.call;

    final (icon, color, title, subtitle) = switch (call) {
      AddActivityToolCall() => (
          Icons.add_task_rounded,
          const Color(0xFF34C759),
          'إضافة نشاط: ${call.title}',
          call.projectName != null
              ? 'ضمن مشروع: ${call.projectName}'
              : 'مقترح من المساعد',
        ),
      EditActivityToolCall() => (
          Icons.edit_calendar_rounded,
          const Color(0xFF007AFF),
          'تعديل نشاط: ${call.targetTitle}',
          call.newTitle != null
              ? 'الاسم الجديد: ${call.newTitle}'
              : 'تحديث التوقيت أو التكرار',
        ),
      DeleteActivityToolCall() => (
          Icons.delete_outline_rounded,
          const Color(0xFFFF3B30),
          'حذف نشاط: ${call.targetTitle}',
          'يتطلب تأكيدك قبل الحذف النهائي',
        ),
      CreateProjectToolCall() => (
          Icons.create_new_folder_rounded,
          const Color(0xFFFF9500),
          'إنشاء مشروع: ${call.name}',
          call.tasks.isEmpty
              ? (call.description ?? 'مشروع جديد')
              : 'يتضمن ${call.tasks.length} مهام',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SettingsIconBadge(icon: icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          switch (action.status) {
            ToolActionStatus.pending => Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: () => ref
                          .read(aiChatProvider.notifier)
                          .dismissProposedAction(messageId, action.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: Text(
                            'تجاهل',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PressableScale(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(aiChatProvider.notifier)
                            .executeProposedAction(messageId, action.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: Text(
                            'تأكيد وإضافة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ToolActionStatus.executed => Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'تم التنفيذ والإضافة بنجاح',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ToolActionStatus.dismissed => Text(
                'تم تجاهل الاقتراح',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          },
        ],
      ),
    );
  }
}
