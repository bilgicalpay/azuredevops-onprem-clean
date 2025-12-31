/// Wiki görüntüleyici ekranı
/// 
/// Wiki içeriğini tam sayfa olarak gösterir.
/// HTML formatındaki içeriği render eder.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;

/// Wiki görüntüleyici ekranı widget'ı
/// Wiki içeriğini HTML formatında tam sayfa gösterir
class WikiViewerScreen extends StatelessWidget {
  final String wikiContent;
  final String? wikiTitle;

  const WikiViewerScreen({
    super.key,
    required this.wikiContent,
    this.wikiTitle,
  });

  /// Extract only the content part from HTML (remove navigation, headers, etc.)
  String _extractContent(String html) {
    try {
      final document = html_parser.parse(html);
      
      // Try to find the main content area (class="vss-Splitter--pane-flexible relative")
      final contentElements = document.querySelectorAll('.vss-Splitter--pane-flexible.relative');
      if (contentElements.isNotEmpty) {
        return contentElements.first.innerHtml;
      }
      
      // Try alternative selectors
      final mainContent = document.querySelector('main') ?? 
                         document.querySelector('.wiki-content') ??
                         document.querySelector('article') ??
                         document.querySelector('.content') ??
                         document.querySelector('body');
      
      if (mainContent != null) {
        return mainContent.innerHtml;
      }
      
      // If no specific content area found, return the whole body
      return document.body?.innerHtml ?? html;
    } catch (e) {
      // If parsing fails, return original content
      debugPrint('⚠️ [WikiViewer] Error parsing HTML: $e');
      return html;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract only the content part from HTML
    final content = _extractContent(wikiContent);
    
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Html(
            data: content,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(16),
                lineHeight: LineHeight(1.6),
              ),
              "h1": Style(
                fontSize: FontSize(28),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 16),
              ),
              "h2": Style(
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 12),
              ),
              "h3": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 10),
              ),
              "h4": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 8),
              ),
              "p": Style(
                margin: Margins.only(bottom: 12),
              ),
              "code": Style(
                fontSize: FontSize(14),
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade200,
                padding: HtmlPaddings.all(2),
              ),
              "pre": Style(
                backgroundColor: Colors.grey.shade200,
                padding: HtmlPaddings.all(12),
                margin: Margins.only(bottom: 12),
              ),
              "a": Style(
                color: Colors.blue,
                textDecoration: TextDecoration.underline,
              ),
              "blockquote": Style(
                padding: HtmlPaddings.only(left: 12),
                margin: Margins.only(left: 0, bottom: 12),
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                backgroundColor: Colors.grey.shade100,
              ),
              "ul": Style(
                margin: Margins.only(bottom: 12),
              ),
              "ol": Style(
                margin: Margins.only(bottom: 12),
              ),
              "li": Style(
                margin: Margins.only(bottom: 4),
              ),
              "table": Style(
                border: Border.all(color: Colors.grey.shade300),
                margin: Margins.only(bottom: 12),
              ),
              "th": Style(
                fontWeight: FontWeight.bold,
                padding: HtmlPaddings.all(8),
                backgroundColor: Colors.grey.shade100,
              ),
              "td": Style(
                padding: HtmlPaddings.all(8),
              ),
            },
          ),
        ),
      ),
    );
  }
}

