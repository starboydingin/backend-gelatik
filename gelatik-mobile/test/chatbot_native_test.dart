import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/features/chatbot/presentation/screens/chatbot_native_screen.dart';
import 'package:gelatik/features/chatbot/providers/chatbot_provider.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';

void main() {
  group('ChatbotNative (F-BOT) Provider Unit Tests', () {
    test('1. Sending a message adds user message and dummy assistant reply',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatbotProvider.notifier);

      expect(container.read(chatbotProvider).messages.length, 1);
      expect(
          container.read(chatbotProvider).messages.first.isAssistant, isTrue);

      final future = notifier.sendMessage('Bagaimana cara pinjam proyektor?');

      expect(container.read(chatbotProvider).messages.length, 2);
      expect(container.read(chatbotProvider).messages.last.isUser, isTrue);
      expect(container.read(chatbotProvider).messages.last.text,
          'Bagaimana cara pinjam proyektor?');
      expect(container.read(chatbotProvider).isTyping, isTrue);

      await future;

      final messages = container.read(chatbotProvider).messages;
      expect(messages.length, 3);
      expect(messages.last.isAssistant, isTrue);
      expect(messages.last.text, contains('Peminjaman Aset'));
      expect(container.read(chatbotProvider).isTyping, isFalse);
    });

    test('2. clearHistory empties the messages list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatbotProvider.notifier);
      expect(container.read(chatbotProvider).messages.isNotEmpty, isTrue);

      notifier.clearHistory();

      expect(container.read(chatbotProvider).messages.isEmpty, isTrue);
    });
  });

  group('ChatbotNativeScreen Widget Tests', () {
    testWidgets('1. Kirim pesan baru muncul sebagai bubble user & balasan dummy muncul sebagai bubble asisten',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatbotNativeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check AppBar Title
      expect(find.text('Asisten Gelatik'), findsOneWidget);
      expect(find.text('Ditenagai AI'), findsOneWidget);

      // Initial welcome message from assistant
      expect(find.text('Asisten Gelatik (AI)'), findsOneWidget);

      // Enter user message
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Tanya soal layanan internet');

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump(); // Update UI for user message & typing state

      // User bubble appears
      expect(find.text('Anda'), findsOneWidget);
      expect(find.text('Tanya soal layanan internet'), findsOneWidget);
      expect(find.text('Asisten Gelatik sedang mengetik...'), findsOneWidget);

      // Fast forward past dummy delay (1.2s)
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();

      // Assistant response bubble appears
      expect(find.text('Asisten Gelatik sedang mengetik...'), findsNothing);
      expect(find.textContaining('Layanan Internet'), findsOneWidget);
    });

    testWidgets('2. Hapus riwayat mengosongkan list setelah konfirmasi',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatbotNativeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Asisten Gelatik (AI)'), findsOneWidget);

      // Tap trash icon in AppBar
      final trashIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(trashIcon, findsOneWidget);
      await tester.tap(trashIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog pops up
      expect(find.text('Hapus Riwayat Chat'), findsOneWidget);
      expect(
        find.text(
            'Apakah Anda yakin ingin menghapus semua riwayat percakapan dengan Asisten Gelatik?'),
        findsOneWidget,
      );

      // Tap 'Hapus' button in dialog
      final hapusButton = find.widgetWithText(ElevatedButton, 'Hapus');
      expect(hapusButton, findsOneWidget);
      await tester.tap(hapusButton);
      await tester.pumpAndSettle();

      // Dialog closed & messages empty state visible
      expect(find.textContaining('Riwayat pesan kosong.'), findsOneWidget);
      expect(find.text('Asisten Gelatik (AI)'), findsNothing);
    });

    testWidgets('3. HomeScreen Bento Grid contains Asisten Gelatik tile with AI badge',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tile exists
      expect(find.text('Asisten Gelatik'), findsOneWidget);
      expect(find.text('Tanya AI TIK'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // Tap Asisten Gelatik tile -> navigates to ChatbotNativeScreen
      await tester.tap(find.text('Asisten Gelatik'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatbotNativeScreen), findsOneWidget);
    });
  });
}
