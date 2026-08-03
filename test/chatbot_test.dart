import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:gelatik/features/chatbot/presentation/screens/chatbot_web_view_screen.dart';

class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageFinished(void Function(String url) onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(void Function(String url) onPageStarted) async {}

  @override
  Future<void> setOnWebResourceError(void Function(WebResourceError error) onWebResourceError) async {}

  @override
  Future<void> setOnNavigationRequest(FutureOr<NavigationDecision> Function(NavigationRequest request) onNavigationRequest) async {}

  @override
  Future<void> setOnHttpError(void Function(HttpResponseError error) onHttpError) async {}

  @override
  Future<void> setOnUrlChange(void Function(UrlChange change) onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(void Function(HttpAuthRequest request) onHttpAuthRequest) async {}
}

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  setUpAll(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  group('ChatbotWebViewScreen Widget Tests (M-I)', () {
    testWidgets('ChatbotWebViewScreen renders AppBar and title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatbotWebViewScreen(),
          ),
        ),
      );

      expect(find.text('Chatbot AI'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
