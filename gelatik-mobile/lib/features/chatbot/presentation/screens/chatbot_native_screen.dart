import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chatbot_provider.dart';

/// ChatbotNativeScreen — Screen Chatbot Native (F-BOT) dengan Data Dummy & State Provider
class ChatbotNativeScreen extends ConsumerStatefulWidget {
  const ChatbotNativeScreen({super.key});

  @override
  ConsumerState<ChatbotNativeScreen> createState() =>
      _ChatbotNativeScreenState();
}

class _ChatbotNativeScreenState extends ConsumerState<ChatbotNativeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    _scrollToBottom();
    await ref.read(chatbotProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat percakapan dengan Asisten Gelatik?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(chatbotProvider.notifier).clearHistory();
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final chatbotState = ref.watch(chatbotProvider);

    // Auto scroll when state changes
    ref.listen<ChatbotState>(chatbotProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Asisten Gelatik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ditenagai AI',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus Riwayat',
            onPressed: _confirmClearHistory,
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // Chat Messages Area
            // -----------------------------------------------------------------
            Expanded(
              child: chatbotState.messages.isEmpty && !chatbotState.isTyping
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 48,
                              color: mutedText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Riwayat pesan kosong.\nSilakan ketik pertanyaan di bawah untuk memulai percakapan.',
                              style: TextStyle(fontSize: 13, color: mutedText),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatbotState.messages.length +
                          (chatbotState.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < chatbotState.messages.length) {
                          final msg = chatbotState.messages[index];
                          return _buildChatBubble(
                            context: context,
                            message: msg,
                            primaryTeal: primaryTeal,
                            strokeColor: strokeColor,
                            mutedText: mutedText,
                            theme: theme,
                            isDark: isDark,
                          );
                        } else {
                          // Typing Indicator Bubble
                          return _buildTypingIndicator(
                            context: context,
                            primaryTeal: primaryTeal,
                            strokeColor: strokeColor,
                            mutedText: mutedText,
                            theme: theme,
                          );
                        }
                      },
                    ),
            ),

            // -----------------------------------------------------------------
            // Bottom Reply Input Field
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: strokeColor, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _handleSendMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tanya apa saja soal layanan TIK...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: strokeColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: strokeColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: primaryTeal, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _handleSendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: actionEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chat Bubble Helper Builder
  Widget _buildChatBubble({
    required BuildContext context,
    required ChatMessageModel message,
    required Color primaryTeal,
    required Color strokeColor,
    required Color mutedText,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isAssistant = message.isAssistant;
    final alignment =
        isAssistant ? Alignment.centerLeft : Alignment.centerRight;

    final borderRadius = isAssistant
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    final bgColor = isAssistant
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : primaryTeal;

    final textColor = isAssistant
        ? theme.colorScheme.onSurface
        : Colors.white;

    final border = isAssistant
        ? Border.all(color: strokeColor, width: 1.5)
        : null;

    final formattedTime =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: border,
          ),
          child: Column(
            crossAxisAlignment: isAssistant
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              // Header Sender Info
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAssistant) ...[
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        size: 14,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Asisten Gelatik (AI)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Anda',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isAssistant
                          ? mutedText
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Message Body Text
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper Builder Typing Indicator
  Widget _buildTypingIndicator({
    required BuildContext context,
    required Color primaryTeal,
    required Color strokeColor,
    required Color mutedText,
    required ThemeData theme,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: strokeColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_rounded,
                size: 14,
                color: primaryTeal,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Asisten Gelatik sedang mengetik...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
