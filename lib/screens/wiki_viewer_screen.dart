/// Wiki görüntüleyici ekranı
/// 
/// Wiki içeriğini tam sayfa olarak gösterir.
/// Markdown formatındaki içeriği render eder.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Wiki görüntüleyici ekranı widget'ı
/// Wiki içeriğini tam sayfa gösterir
class WikiViewerScreen extends StatelessWidget {
  final String wikiContent;
  final String? wikiTitle;

  const WikiViewerScreen({
    super.key,
    required this.wikiContent,
    this.wikiTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(wikiTitle ?? 'Wiki'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Kapat',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Markdown(
            data: wikiContent,
            styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 16, height: 1.6),
            h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
            h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
            h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
            h4: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
            code: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              backgroundColor: Colors.grey.shade200,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            blockquote: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
            blockquoteDecoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                left: BorderSide(color: Colors.blue, width: 4),
              ),
            ),
            blockquotePadding: const EdgeInsets.all(12),
            listBullet: const TextStyle(color: Colors.blue),
            a: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            tableHead: const TextStyle(fontWeight: FontWeight.bold),
            tableBody: const TextStyle(fontSize: 14),
            tableBorder: TableBorder.all(color: Colors.grey.shade300),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
          ),
          onTapLink: (text, href, title) {
            // Handle link taps if needed
            debugPrint('Link tapped: $href');
          },
        ),
        ),
      ),
    );
  }
}

