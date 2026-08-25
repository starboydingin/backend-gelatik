import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chatbot_provider.dart';
import '../../services/chatbot_visit_tracker.dart';

class ChatbotNativeScreen extends ConsumerStatefulWidget {
  const ChatbotNativeScreen({super.key});

  @override
  ConsumerState<ChatbotNativeScreen> createState() =>
      _ChatbotNativeScreenState();
}

class _ChatbotNativeScreenState extends ConsumerState<ChatbotNativeScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatbotVisitTracker _visitTracker;
  late final String _visitSessionKey;
  DateTime? _inactiveSince;
  int? _starterPromptAnchor;
  bool _showStarterPrompts = false;
  Timer? _idleResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onInputChanged);
    _visitTracker = ref.read(chatbotVisitTrackerProvider);
    final userId = ref.read(authProvider).currentUser?.id;
    _visitSessionKey = userId == null ? 'current-session' : 'user:$userId';
    _showStarterPrompts = _visitTracker.shouldShowStarter(
      _visitSessionKey,
      DateTime.now(),
    );
    _scheduleIdleReset();
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _visitTracker.markLeft(_visitSessionKey, DateTime.now());
    _idleResetTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageController
      ..removeListener(_onInputChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleIdleReset() {
    _idleResetTimer?.cancel();
    _idleResetTimer = Timer(ChatbotVisitTracker.promptResetAfter, () {
      if (!mounted) return;
      setState(() {
        _showStarterPrompts = true;
        _starterPromptAnchor = ref.read(chatbotProvider).messages.length;
      });
      _scrollToBottom();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _inactiveSince ??= DateTime.now();
        return;
      case AppLifecycleState.resumed:
        final inactiveSince = _inactiveSince;
        _inactiveSince = null;
        if (inactiveSince != null &&
            DateTime.now().difference(inactiveSince) >=
                ChatbotVisitTracker.promptResetAfter) {
          setState(() {
            _showStarterPrompts = true;
            _starterPromptAnchor = ref.read(chatbotProvider).messages.length;
          });
          _scrollToBottom();
        }
        _scheduleIdleReset();
        return;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? quickQuestion]) async {
    final text = (quickQuestion ?? _messageController.text).trim();
    final state = ref.read(chatbotProvider);
    if (text.isEmpty || state.isTyping) return;
    if (_showStarterPrompts && _starterPromptAnchor == null) {
      setState(() => _starterPromptAnchor = state.messages.length);
    }
    _scheduleIdleReset();
    _messageController.clear();
    FocusScope.of(context).unfocus();
    await ref.read(chatbotProvider.notifier).sendMessage(text);
  }

  Future<void> _loginAgain() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat percakapan dengan Asisten Gelatik?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatbotProvider.notifier).deleteHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatbotProvider);
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);
    final canSend =
        _messageController.text.trim().isNotEmpty && !state.isTyping;

    ref.listen<ChatbotState>(chatbotProvider, (previous, next) {
      final historyJustLoaded = previous?.isLoadingHistory == true;
      if ((!historyJustLoaded &&
              previous?.messages.length != next.messages.length) ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: GelatikPageHeader(
        title: 'Asisten',
        showBack: true,
        actions: [
          IconButton(
            key: const Key('chatbot-delete'),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus Riwayat',
            onPressed: state.isTyping || state.isRefreshing
                ? null
                : _confirmDelete,
          ),
          Icon(Icons.smart_toy_rounded, color: AppColors.accentGold(context)),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.errorMessage != null)
              _ErrorBanner(
                message: state.errorMessage!,
                unauthorized: state.isUnauthorized,
                onAction: state.isUnauthorized
                    ? _loginAgain
                    : () => ref.read(chatbotProvider.notifier).refreshHistory(),
              ),
            Expanded(
              child: _buildMessages(
                state: state,
                theme: theme,
                primaryTeal: primaryTeal,
                strokeColor: strokeColor,
                mutedText: mutedText,
              ),
            ),
            _buildInput(theme, primaryTeal, strokeColor, canSend),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages({
    required ChatbotState state,
    required ThemeData theme,
    required Color primaryTeal,
    required Color strokeColor,
    required Color mutedText,
  }) {
    if (state.isLoadingHistory) {
      return const Center(
        key: Key('chatbot-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final starterAnchor = (_starterPromptAnchor ?? state.messages.length).clamp(
      0,
      state.messages.length,
    );
    // An empty server conversation must never render as a blank chat. This
    // also covers account-scoped realtime deletion from the website.
    final showStarterPrompts = _showStarterPrompts || state.messages.isEmpty;
    final timeline = <Widget>[const _DayChip()];
    for (var index = 0; index <= state.messages.length; index++) {
      if (showStarterPrompts && index == starterAnchor) {
        timeline.add(
          _AssistantWelcome(primaryTeal: primaryTeal, strokeColor: strokeColor),
        );
        timeline.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _QuickQuestions(
              primaryTeal: primaryTeal,
              strokeColor: strokeColor,
              onSelected: _send,
            ),
          ),
        );
      }
      if (index >= state.messages.length) continue;
      final message = state.messages[index];
      timeline.add(
        _MessageBubble(
          message: message,
          primaryTeal: primaryTeal,
          strokeColor: strokeColor,
          mutedText: mutedText,
          onRetry: message.status == ChatMessageStatus.failed
              ? () =>
                    ref.read(chatbotProvider.notifier).retryMessage(message.id)
              : null,
        ),
      );
    }
    if (state.isTyping) {
      timeline.add(
        _TypingIndicator(
          primaryTeal: primaryTeal,
          strokeColor: strokeColor,
          mutedText: mutedText,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: ref.read(chatbotProvider.notifier).refreshHistory,
      child: ListView(
        controller: _scrollController,
        key: Key(state.messages.isEmpty ? 'chatbot-empty' : 'chatbot-messages'),
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: timeline,
      ),
    );
  }

  Widget _buildInput(
    ThemeData theme,
    Color primaryTeal,
    Color strokeColor,
    bool canSend,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: strokeColor, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: strokeColor, width: 1.5),
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppColors.accentNavy(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('chatbot-input'),
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => canSend ? _send() : null,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: .5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: strokeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: primaryTeal, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('chatbot-send'),
            onPressed: canSend ? _send : null,
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Kirim pesan',
          ),
        ],
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final Color primaryTeal;
  final Color strokeColor;
  final Future<void> Function(String) onSelected;

  const _QuickQuestions({
    required this.primaryTeal,
    required this.strokeColor,
    required this.onSelected,
  });

  static const _questions = [
    'Bagaimana cara mengajukan peminjaman aset TIK?',
    'WiFi terhubung tetapi tidak ada internet. Apa yang harus dilakukan?',
    'Bagaimana cara reset kata sandi email resmi?',
    'Bagaimana cara mengajukan sertifikat elektronik TTE?',
    'Bagaimana cara mengajukan usulan email dinas?',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pertanyaan cepat',
          style: TextStyle(
            color: primaryTeal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _questions
              .map(
                (question) => ActionChip(
                  key: Key('chatbot-quick-${_questions.indexOf(question)}'),
                  label: Text(question),
                  labelStyle: TextStyle(color: primaryTeal, fontSize: 12),
                  side: BorderSide(color: strokeColor),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: () => onSelected(question),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _AssistantWelcome extends StatelessWidget {
  final Color primaryTeal;
  final Color strokeColor;

  const _AssistantWelcome({
    required this.primaryTeal,
    required this.strokeColor,
  });

  @override
  Widget build(BuildContext context) => Align(
    key: const Key('chatbot-welcome'),
    alignment: Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width * .82).clamp(0, 560),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asisten Gelatik (AI)',
            style: TextStyle(
              color: primaryTeal,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Halo, saya Asisten Konsultasi TIK Gelatik. Ada yang bisa saya bantu hari ini? Pilih salah satu pertanyaan cepat di bawah atau tulis pertanyaan Anda sendiri.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DayChip extends StatelessWidget {
  const _DayChip();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Hari Ini',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText(context),
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final Color primaryTeal;
  final Color strokeColor;
  final Color mutedText;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.primaryTeal,
    required this.strokeColor,
    required this.mutedText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final failed = message.status == ChatMessageStatus.failed;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    return Align(
      key: Key('chat-message-${message.id}'),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * .82).clamp(0, 560),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? (failed ? theme.colorScheme.error : primaryTeal)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: strokeColor),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  isUser ? 'Anda' : 'Asisten Gelatik (AI)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white : primaryTeal,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser ? Colors.white70 : mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _plainChatText(message.text),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            if (failed) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                key: Key('chatbot-retry-${message.id}'),
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _plainChatText(String value) {
    final withoutBold = value.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*', dotAll: true),
      (match) => match.group(1) ?? '',
    );
    return withoutBold.replaceAllMapped(
      RegExp(r'^\s*\*\s+', multiLine: true),
      (_) => '- ',
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color primaryTeal;
  final Color strokeColor;
  final Color mutedText;

  const _TypingIndicator({
    required this.primaryTeal,
    required this.strokeColor,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      key: const Key('chatbot-typing'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strokeColor),
      ),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryTeal,
            ),
          ),
          Text(
            'Asisten Gelatik sedang mengetik...',
            style: TextStyle(fontSize: 12, color: mutedText),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool unauthorized;
  final Future<void> Function() onAction;

  const _ErrorBanner({
    required this.message,
    required this.unauthorized,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('chatbot-error-banner'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(child: Text(message, maxLines: 3)),
          TextButton(
            onPressed: onAction,
            child: Text(unauthorized ? 'Masuk ulang' : 'Muat ulang'),
          ),
        ],
      ),
    ),
  );
}
