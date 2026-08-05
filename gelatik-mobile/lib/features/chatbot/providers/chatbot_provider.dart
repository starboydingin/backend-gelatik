import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';

class ChatbotState {
  final List<ChatMessageModel> messages;
  final bool isTyping;

  const ChatbotState({
    required this.messages,
    this.isTyping = false,
  });

  ChatbotState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier()
      : super(
          ChatbotState(
            messages: [
              ChatMessageModel(
                id: 'welcome_msg',
                sender: ChatMessageSender.assistant,
                text:
                    'Halo! Saya Asisten Gelatik (AI TIK Pemkab Magelang). Anda dapat menanyakan informasi seputar peminjaman aset, layanan internet, usulan email BKD, atau konsultasi TIK.',
                timestamp: DateTime.now(),
              ),
            ],
          ),
        );

  final Random _random = Random();

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final userMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sender: ChatMessageSender.user,
      text: query,
      timestamp: DateTime.now(),
    );

    // Append user message and set typing state
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    // Dummy delay simulating AI processing (1-1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    final replyText = _generateDummyResponse(query);

    final aiMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sender: ChatMessageSender.assistant,
      text: replyText,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isTyping: false,
    );
  }

  void clearHistory() {
    state = const ChatbotState(messages: [], isTyping: false);
  }

  String _generateDummyResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('pinjam') || lower.contains('aset') || lower.contains('alat')) {
      return 'Untuk mengajukan peminjaman aset TIK (laptop, proyektor, sound system, dll), Anda dapat mengakses menu "Peminjaman Aset" di Halaman Utama dan mengisi formulir wizard 2 langkah.';
    }
    if (lower.contains('internet') || lower.contains('wifi') || lower.contains('router') || lower.contains('jaringan')) {
      return 'Informasi mengenai ketersediaan jaringan internet OPD, rekomendasi bandwidth, dan pengajuan self-assessment router dapat diakses melalui menu "Layanan Internet".';
    }
    if (lower.contains('email') || lower.contains('bkd') || lower.contains('surat')) {
      return 'Untuk usulan pembuatan atau aktivasi email resmi Pemkab Magelang, silakan gunakan menu "Usulan Email" dan pilih nama pegawai dari daftar yang tersedia.';
    }
    if (lower.contains('konsultasi') || lower.contains('tiket') || lower.contains('bantuan')) {
      return 'Jika Anda membutuhkan bantuan atau kendala teknis spesifik dari tim Diskominfo, Anda bisa membuat tiket konsultasi baru pada menu "Konsultasi TIK".';
    }
    if (lower.contains('status') || lower.contains('proses') || lower.contains('pengajuan')) {
      return 'Status pengajuan layanan Anda (Menunggu, Disetujui, Ditolak, atau Selesai) dapat dipantau secara real-time pada daftar riwayat masing-masing layanan.';
    }

    final templates = [
      'Terima kasih atas pertanyaan Anda. Asisten Gelatik siap membantu memberikan informasi seputar portal layanan TIK Diskominfo Pemkab Magelang. Silakan tanyakan detail layanan yang Anda perlukan.',
      'Pertanyaan Anda telah kami catat. Silakan telusuri menu Layanan TIK Utama pada Dashboard Gelatik untuk panduan lebih rinci.',
      'Asisten Gelatik menyarankan untuk memeriksa menu Konsultasi TIK apabila memerlukan asistensi teknis langsung dari petugas Diskominfo Pemkab Magelang.',
    ];

    return templates[_random.nextInt(templates.length)];
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});
