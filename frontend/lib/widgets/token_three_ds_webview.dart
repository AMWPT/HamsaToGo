import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/theme.dart';

/// 3DS challenge screen for saved-card (token) charges.
///
/// The Moyasar SDK only runs its own 3DS webview for payments it created
/// itself; token charges are created by our backend, so we host the
/// challenge here. Moyasar redirects to the backend's
/// `/cards/payment-callback` with `?status=paid|failed&message=...` when
/// the challenge finishes — we intercept that navigation instead of
/// letting the page load.
class TokenThreeDsWebView extends StatefulWidget {
  final String transactionUrl;
  final bool isAr;

  /// status is 'paid', 'failed', or 'cancelled' (user closed the screen).
  final void Function(String status, String message) onDone;

  const TokenThreeDsWebView({
    super.key,
    required this.transactionUrl,
    required this.isAr,
    required this.onDone,
  });

  static const callbackPath = '/cards/payment-callback';

  @override
  State<TokenThreeDsWebView> createState() => _TokenThreeDsWebViewState();
}

class _TokenThreeDsWebViewState extends State<TokenThreeDsWebView> {
  late final WebViewController _controller;
  bool _done = false;

  void _finish(String status, String message) {
    if (_done) return;
    _done = true;
    Navigator.of(context).pop();
    widget.onDone(status, message);
  }

  bool _isCallback(String url) =>
      Uri.tryParse(url)?.path == TokenThreeDsWebView.callbackPath;

  void _handleCallback(String url) {
    final params = Uri.parse(url).queryParameters;
    _finish(params['status'] ?? 'failed', params['message'] ?? '');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (_isCallback(request.url)) {
            _handleCallback(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        // Fallback — some redirect chains bypass onNavigationRequest.
        onPageFinished: (url) {
          if (_isCallback(url)) _handleCallback(url);
        },
      ))
      ..loadRequest(Uri.parse(widget.transactionUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => _finish('cancelled', ''),
        ),
        title: Text(
          widget.isAr ? 'تأكيد الدفع' : 'Verify payment',
          style: HamsaText.heading(size: 16, color: Colors.black87),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
