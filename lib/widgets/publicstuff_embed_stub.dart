import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildPublicStuffEmbed() {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(
      Uri.parse('https://iframe.publicstuff.com/#?client_id=1000167'),
    );
  return SizedBox(
    height: 420,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: WebViewWidget(controller: controller),
    ),
  );
}
