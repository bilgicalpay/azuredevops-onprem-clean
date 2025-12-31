/// Wiki servisi
/// 
/// AzureDevOps'den wiki içeriğini getirir.
/// Hem Git repository dosyalarını hem de Wiki sayfalarını destekler.
/// Markdown ve HTML formatlarını işler.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';

/// Wiki model class
class Wiki {
  final String id;
  final String name;
  final String projectId;
  final String projectName;
  final String? url;

  Wiki({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName,
    this.url,
  });

  factory Wiki.fromJson(Map<String, dynamic> json, String projectName) {
    return Wiki(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      projectName: projectName,
      url: json['url'] as String?,
    );
  }
}

/// Wiki servisi sınıfı
/// Wiki içeriklerini Azure DevOps API'den getirir
class WikiService {
  final Dio _dio = CertificatePinningService.createSecureDio();

  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }

  /// Get list of projects user has access to
  Future<List<Map<String, String>>> getProjects({
    required String serverUrl,
    required String token,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/_apis/projects?api-version=7.0';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final projects = response.data['value'] as List?;
        if (projects != null) {
          return projects.map((project) {
            return {
              'id': project['id'] as String? ?? '',
              'name': project['name'] as String? ?? '',
            };
          }).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ [WikiService] Error getting projects: $e');
      return [];
    }
  }

  /// Get list of wikis for a project
  Future<List<Wiki>> getWikis({
    required String serverUrl,
    required String token,
    required String project,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/wiki/wikis?api-version=7.0';
      
      debugPrint('🔍 [WikiService] Fetching wikis for project: $project');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final wikis = response.data['value'] as List?;
        if (wikis != null) {
          return wikis.map((wiki) => Wiki.fromJson(wiki as Map<String, dynamic>, project)).toList();
        }
      }

      debugPrint('⚠️ [WikiService] No wikis found for project: $project');
      return [];
    } catch (e) {
      debugPrint('❌ [WikiService] Error getting wikis: $e');
      return [];
    }
  }

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
      
      // Try multiple endpoints and headers
      List<Map<String, String>> attempts = [];
      
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
            // final version = wikiParts[1]; // Version not used in API call
            final pagePath = wikiParts.length > 2 ? wikiParts.sublist(2).join('/') : '';
            
            // Try multiple wiki API endpoints
            if (pagePath.isNotEmpty) {
              // Try HTML endpoint first (rendered HTML content)
              final encodedPagePath = Uri.encodeComponent(pagePath);
              apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/wiki/wikis/$wikiName/pages/$encodedPagePath?includeContent=true&api-version=7.0';
              debugPrint('🔄 [WIKI] Converted wiki URL to HTML API: $apiUrl');
              // Also try with format=html parameter
              attempts.add({
                'url': '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/wiki/wikis/$wikiName/pages/$encodedPagePath?includeContent=true&format=html&api-version=7.0',
                'accept': 'text/html',
              });
            } else {
              // Try pages endpoint
              apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/wiki/wikis/$wikiName/pages?api-version=7.0';
              debugPrint('🔄 [WIKI] Converted wiki URL to pages API: $apiUrl');
            }
          }
        }
      }
      
      // If it's a git repo URL, convert to API endpoint
      // Format: https://devops.higgscloud.com/Dev/_git/demo?path=/README.md
      if (uri.path.contains('/_git/') && uri.queryParameters.containsKey('path')) {
        final path = uri.queryParameters['path'] ?? '';
        debugPrint('🔍 [WIKI] Git repo URL detected, path: $path');
        
        // Extract project/repo name from path: /Dev/_git/demo -> demo
        final projectMatch = RegExp(r'/_git/([^/?]+)').firstMatch(uri.path);
        if (projectMatch != null) {
          final project = projectMatch.group(1);
          debugPrint('🔍 [WIKI] Extracted project: $project');
          
          // Extract collection from path segments
          // URL: /Dev/_git/demo -> segments: ['Dev', '_git', 'demo']
          // Collection is the first segment before '_git'
          String collectionPath = '';
          final pathSegments = uri.pathSegments;
          for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i] == '_git' && i > 0) {
              collectionPath = pathSegments[i - 1];
              break;
            }
          }
          
          // If not found, try first segment
          if (collectionPath.isEmpty && pathSegments.isNotEmpty && pathSegments[0] != '_git') {
            collectionPath = pathSegments[0];
          }
          
          debugPrint('🔍 [WIKI] Extracted collection: $collectionPath');
          
          // Use provided collection if available, otherwise use extracted
          final finalCollection = (collection != null && collection.isNotEmpty) ? collection : collectionPath;
          
          // Normalize path (remove leading slash if present, then add it back for API)
          String normalizedPath = path.startsWith('/') ? path : '/$path';
          
          // Try multiple API endpoint formats
          if (finalCollection.isNotEmpty) {
            // Format 1: {server}/{collection}/{project}/_apis/git/repositories/{repoName}/items?path={path}&includeContent=true&api-version=7.0
            apiUrl = '${uri.scheme}://${uri.host}/$finalCollection/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0';
            debugPrint('🔄 [WIKI] Converted git URL to API (with collection): $apiUrl');
            
            // Format 2: Try with collection at root level
            attempts.add({
              'url': '${uri.scheme}://${uri.host}/$finalCollection/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0',
              'accept': 'application/json',
            });
            
            // Format 3: Try with DefaultCollection (common in Azure DevOps Server)
            attempts.add({
              'url': '${uri.scheme}://${uri.host}/DefaultCollection/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0',
              'accept': 'application/json',
            });
            
            // Format 4: Try without collection in path
            attempts.add({
              'url': '${uri.scheme}://${uri.host}/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0',
              'accept': 'application/json',
            });
          } else {
            apiUrl = '${uri.scheme}://${uri.host}/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0';
            debugPrint('🔄 [WIKI] Converted git URL to API (no collection): $apiUrl');
            
            // Also try with DefaultCollection
            attempts.add({
              'url': '${uri.scheme}://${uri.host}/DefaultCollection/$project/_apis/git/repositories/$project/items?path=${Uri.encodeComponent(normalizedPath)}&includeContent=true&api-version=7.0',
              'accept': 'application/json',
            });
          }
        }
      }
      
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
                    final decodedBytes = base64.decode(contentValue);
                    content = utf8.decode(decodedBytes);
                    debugPrint('✅ [WIKI] Decoded base64 content (${content.length} chars)');
                  } catch (e) {
                    // Not base64, use as plain text
                    content = contentValue;
                    debugPrint('✅ [WIKI] Using content as plain text (${content.length} chars)');
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
}
