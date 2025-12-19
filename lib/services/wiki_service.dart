/// Wiki servisi
/// 
/// Azure DevOps Server 2022'den wiki içeriğini getirir.
/// Hem Git repository dosyalarını hem de Wiki sayfalarını destekler.
/// Markdown ve HTML formatlarını işler.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Wiki servisi sınıfı
/// Wiki içeriklerini Azure DevOps API'den getirir
class WikiService {
  final Dio _dio = Dio();

  /// Fetch wiki content from Azure DevOps wiki URL
  /// Example URL: https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README
  /// Or Git repo file: https://devops.higgscloud.com/Dev/_git/demo?path=/README.md
  Future<String?> fetchWikiContent({
    required String wikiUrl,
    required String token,
    String? serverUrl,
    String? collection,
  }) async {
    try {
      debugPrint('🔍 [WIKI] Fetching wiki content from: $wikiUrl');
      
      // Encode token for Basic Auth
      final encodedToken = _encodeToken(token);
      
      // Check if it's a wiki URL or git repo URL
      final uri = Uri.parse(wikiUrl);
      String? apiUrl;
      
      // If it's a wiki URL, convert to API endpoint
      if (uri.path.contains('/_wiki/wikis/')) {
        // Extract wiki path from URL: /Dev/demo/_wiki/wikis/CAB-Plan/1/README
        // Format: /{collection}/{project}/_wiki/wikis/{wikiName}/{version}/{pagePath}
        final wikiPathMatch = RegExp(r'/_wiki/wikis/(.+)$').firstMatch(uri.path);
        if (wikiPathMatch != null) {
          final fullWikiPath = wikiPathMatch.group(1)!;
          // Split wiki path: CAB-Plan/1/README -> wikiName: CAB-Plan, version: 1, pagePath: README
          final wikiParts = fullWikiPath.split('/');
          String extractedCollection = '';
          String project = '';
          
          // Extract collection and project from path segments
          if (uri.pathSegments.length >= 2) {
            extractedCollection = uri.pathSegments[0];
            project = uri.pathSegments[1];
          }
          
          // Use provided collection parameter if available, otherwise use extracted collection
          final finalCollection = (collection != null && collection.isNotEmpty) ? collection : (extractedCollection.isNotEmpty ? extractedCollection : '');
          
          if (finalCollection.isNotEmpty && project.isNotEmpty && wikiParts.length >= 2) {
            final wikiName = wikiParts[0];
            final version = wikiParts[1];
            final pagePath = wikiParts.length > 2 ? wikiParts.sublist(2).join('/') : '';
            
            // Try multiple wiki API endpoints
            if (pagePath.isNotEmpty) {
              // Try text endpoint first (raw markdown/text) - this returns plain text
              final encodedPagePath = Uri.encodeComponent(pagePath);
              apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/wiki/wikis/$wikiName/pages/$encodedPagePath/text?api-version=7.0';
              debugPrint('🔄 [WIKI] Converted wiki URL to text API: $apiUrl');
            } else {
              // Try pages endpoint
              apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/wiki/wikis/$wikiName/pages?api-version=7.0';
              debugPrint('🔄 [WIKI] Converted wiki URL to pages API: $apiUrl');
            }
          }
        }
      }
      // If it's a git repo URL, convert to API endpoint
      else if (uri.path.contains('/_git/') && uri.queryParameters.containsKey('path')) {
        final path = uri.queryParameters['path'] ?? '';
        final projectMatch = RegExp(r'/_git/([^/?]+)').firstMatch(uri.path);
        if (projectMatch != null) {
          final project = projectMatch.group(1);
          // Extract collection from path (first segment after host)
          String collectionPath = '';
          if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] != '_git') {
            collectionPath = uri.pathSegments[0];
          }
          
          // Use provided collection if available
          final finalCollection = collectionPath.isNotEmpty ? collectionPath : (collection ?? '');
          
          // Try multiple API endpoint formats
          if (finalCollection.isNotEmpty) {
            apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(path)}&includeContent=true&api-version=7.0';
          } else {
            apiUrl = '${uri.scheme}://${uri.host}/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(path)}&includeContent=true&api-version=7.0';
          }
          debugPrint('🔄 [WIKI] Converted git URL to API: $apiUrl');
        }
      }
      
      // Try multiple endpoints and headers
      List<Map<String, String>> attempts = [];
      
      // Add API URL first if converted (prefer API endpoints)
      if (apiUrl != null) {
        // Try text endpoint first (if it's a text API) - this returns plain text/markdown
        if (apiUrl.contains('/text?')) {
          attempts.add({
            'url': apiUrl,
            'accept': 'text/plain',
          });
          // Also try with markdown accept header
          attempts.add({
            'url': apiUrl,
            'accept': 'text/markdown',
          });
        }
        // Try JSON endpoint (for pages API)
        attempts.add({
          'url': apiUrl,
          'accept': 'application/json',
        });
      }
      
      // Add original URL attempts (only if no API URL was found)
      if (apiUrl == null) {
        attempts.addAll([
          {
            'url': wikiUrl,
            'accept': 'text/plain, text/html, text/markdown, */*',
          },
          {
            'url': wikiUrl,
            'accept': 'text/plain',
          },
          {
            'url': wikiUrl,
            'accept': 'text/html',
          },
        ]);
      }
      
      for (var attempt in attempts) {
        try {
          debugPrint('🔍 [WIKI] Trying: ${attempt['url']} with Accept: ${attempt['accept']}');
          
          final response = await _dio.get(
            attempt['url']!,
            options: Options(
              headers: {
                'Authorization': 'Basic $encodedToken',
                'Accept': attempt['accept']!,
                'Content-Type': 'text/plain',
              },
              validateStatus: (status) => status! < 500,
              followRedirects: true,
            ),
          );

          debugPrint('📦 [WIKI] Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            String? content;
            if (response.data is String) {
              content = response.data as String;
              debugPrint('✅ [WIKI] Got string content (${content.length} chars)');
            } else if (response.data is Map) {
              // Try to extract content from JSON response
              final data = response.data as Map<String, dynamic>;
              debugPrint('📦 [WIKI] Response is JSON, keys: ${data.keys.toList()}');
              
              // Wiki API returns content in different formats
              if (data.containsKey('content')) {
                // Check if content is base64 encoded (Git API) or plain text (Wiki API)
                final contentValue = data['content'] as String?;
                if (contentValue != null && contentValue.isNotEmpty) {
                  // Try base64 decode first
                  try {
                    content = String.fromCharCodes(base64.decode(contentValue));
                    debugPrint('✅ [WIKI] Decoded base64 content');
                  } catch (e) {
                    // Not base64, use as plain text
                    content = contentValue;
                    debugPrint('✅ [WIKI] Using content as plain text');
                  }
                }
              } else if (data.containsKey('value')) {
                // Wiki pages API returns array in 'value'
                final value = data['value'];
                if (value is List && value.isNotEmpty) {
                  final firstPage = value[0] as Map<String, dynamic>?;
                  if (firstPage != null) {
                    content = firstPage['content'] as String? ??
                             firstPage['text'] as String? ??
                             firstPage['body'] as String?;
                    debugPrint('✅ [WIKI] Extracted content from pages array');
                  }
                } else if (value is String) {
                  content = value;
                }
              } else {
                // Try other possible keys
                content = data['text'] as String? ??
                         data['body'] as String? ??
                         data['markdown'] as String?;
                if (content != null) {
                  debugPrint('✅ [WIKI] Extracted content from alternative key');
                }
              }
            }
            
            if (content != null && content.isNotEmpty) {
              debugPrint('✅ [WIKI] Wiki content fetched successfully (${content.length} chars)');
              return content;
            } else {
              debugPrint('⚠️ [WIKI] Response 200 but content is empty or null');
            }
          } else if (response.statusCode == 401) {
            debugPrint('⚠️ [WIKI] Authentication failed (401). Token may be invalid or expired.');
            debugPrint('⚠️ [WIKI] URL: ${attempt['url']}');
            // Continue to next attempt
            continue;
          } else {
            debugPrint('⚠️ [WIKI] Failed with status: ${response.statusCode}');
            if (response.data != null) {
              debugPrint('⚠️ [WIKI] Error response: ${response.data}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ [WIKI] Attempt failed: $e');
          continue;
        }
      }
      
      debugPrint('❌ [WIKI] All attempts failed');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [WIKI] Error fetching wiki content: $e');
      debugPrint('❌ [WIKI] Stack trace: $stackTrace');
      return null;
    }
  }

  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }
}
