import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';

/// ChatbotWebViewScreen — Modul M-I Chatbot AI (WebView Placeholder)
class ChatbotWebViewScreen extends StatefulWidget {
  final WebViewController? controller;

  const ChatbotWebViewScreen({super.key, this.controller});

  @override
  State<ChatbotWebViewScreen> createState() => _ChatbotWebViewScreenState();
}

class _ChatbotWebViewScreenState extends State<ChatbotWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocalHtml();
  }

  void _loadLocalHtml() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? '#0F172A' : '#F8FAFC';
    final cardBg = isDark ? '#1E293B' : '#FFFFFF';
    final textColor = isDark ? '#F1F5F9' : '#0F172A';
    final mutedColor = isDark ? '#94A3B8' : '#64748B';
    final tealColor = isDark ? '#2DD4BF' : '#0F766E';
    final strokeColor = isDark ? '#334155' : '#E2E8F0';

    final htmlContent = '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Chatbot AI Gelatik</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: $bgColor;
      color: $textColor;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      text-align: center;
    }
    .card {
      background-color: $cardBg;
      border: 2px solid $strokeColor;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 360px;
      width: 100%;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    }
    .icon-wrapper {
      width: 64px;
      height: 64px;
      background-color: rgba(15, 118, 110, 0.15);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px auto;
    }
    .icon-wrapper svg {
      width: 32px;
      height: 32px;
      fill: $tealColor;
    }
    h1 {
      font-size: 20px;
      font-weight: 700;
      color: $tealColor;
      margin-bottom: 12px;
    }
    p {
      font-size: 14px;
      line-height: 1.5;
      color: $textColor;
      margin-bottom: 8px;
    }
    .subtitle {
      font-size: 12px;
      color: $mutedColor;
      line-height: 1.4;
    }
    .badge {
      display: inline-block;
      margin-top: 16px;
      padding: 6px 12px;
      background-color: rgba(15, 118, 110, 0.1);
      border: 1px solid $tealColor;
      border-radius: 20px;
      color: $tealColor;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-wrapper">
      <svg viewBox="0 0 24 24">
        <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H5.2L4 17.2V4h16v12z"/>
        <circle cx="8" cy="10" r="1.5"/>
        <circle cx="12" cy="10" r="1.5"/>
        <circle cx="16" cy="10" r="1.5"/>
      </svg>
    </div>
    <h1>Chatbot AI Gelatik</h1>
    <p>Chatbot AI — akan terhubung setelah integrasi backend</p>
    <p class="subtitle">Modul ini siap dikoneksikan dengan iframe Chatbase resmi via endpoint <code>GET /api/chatbot</code>.</p>
    <div class="badge">Placeholder Mode (M-I)</div>
  </div>
</body>
</html>
''';

    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final primaryTeal = AppColors.primaryTeal(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chatbot AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: primaryTeal,
              ),
            ),
        ],
      ),
    );
  }
}
