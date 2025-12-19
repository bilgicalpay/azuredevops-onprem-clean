/// Work Item servisi
/// 
/// Azure DevOps Server 2022 API'si ile work item'ları yönetir.
/// Work item listeleme, detay görüntüleme, güncelleme, query çalıştırma
/// ve ilişkili work item'ları getirme işlemlerini gerçekleştirir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';
import 'security_service.dart';
import 'token_refresh_service.dart';

/// Work Item servisi sınıfı
/// Azure DevOps API ile work item işlemlerini yönetir
class WorkItemService {
  final Dio _dio = CertificatePinningService.createSecureDio();
  
  // Expose for UI layer
  Dio get dio => _dio;
  
  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }
  
  // Expose for UI layer
  String encodeToken(String token) => _encodeToken(token);

  /// Get user's saved queries (My Queries, Shared Queries, Favorites)
  Future<Map<String, List<SavedQuery>>> getSavedQueriesGrouped({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
  }) async {
    final result = <String, List<SavedQuery>>{
      'My Queries': [],
      'Shared Queries': [],
      'Favorites': [],
    };

    // Get My Queries
    result['My Queries'] = await getSavedQueries(
      serverUrl: serverUrl,
      token: token,
      collection: collection,
      project: project,
    );

    // Get Shared Queries
    result['Shared Queries'] = await getSharedQueries(
      serverUrl: serverUrl,
      token: token,
      collection: collection,
      project: project,
    );

    // Get Favorites
    result['Favorites'] = await getFavoriteQueries(
      serverUrl: serverUrl,
      token: token,
      collection: collection,
      project: project,
    );

    return result;
  }

  /// Get user's saved queries
  Future<List<SavedQuery>> getSavedQueries({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      // Try multiple endpoints - queries can be at different levels
      // Azure DevOps queries are typically project-scoped
      List<String> endpoints = [];
      
      // Try with project (most specific) - My Queries
      if (project != null && project.isNotEmpty) {
        if (collection != null && collection.isNotEmpty) {
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries/My%20Queries?\$depth=2&api-version=7.0');
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries?\$filter=MyQueries&\$depth=2&api-version=7.0');
        }
        endpoints.add('$cleanUrl/$project/_apis/wit/queries/My%20Queries?\$depth=2&api-version=7.0');
        endpoints.add('$cleanUrl/$project/_apis/wit/queries?\$filter=MyQueries&\$depth=2&api-version=7.0');
      }
      
      // Try with collection
      if (collection != null && collection.isNotEmpty) {
        endpoints.add('$cleanUrl/$collection/_apis/wit/queries/My%20Queries?\$depth=2&api-version=7.0');
        endpoints.add('$cleanUrl/$collection/_apis/wit/queries?\$filter=MyQueries&\$depth=2&api-version=7.0');
      }
      
      // Try without collection/project (organization level)
      endpoints.add('$cleanUrl/_apis/wit/queries/My%20Queries?\$depth=2&api-version=7.0');
      endpoints.add('$cleanUrl/_apis/wit/queries?\$filter=MyQueries&\$depth=2&api-version=7.0');

      for (final url in endpoints) {
        try {
          debugPrint('🔍 [QUERIES] Trying endpoint: $url');
          
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500, // Don't throw for 4xx errors
            ),
          );

          if (response.statusCode == 200) {
            debugPrint('✅ [QUERIES] Response received, keys: ${response.data.keys.toList()}');
            debugPrint('📦 [QUERIES] Full response preview: ${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}');
            
            // Check if response has 'value' key (list response)
            dynamic dataToProcess = response.data;
            if (response.data is Map && response.data.containsKey('value')) {
              final value = response.data['value'];
              debugPrint('📦 [QUERIES] Found value key, type: ${value.runtimeType}, length: ${value is List ? value.length : 'N/A'}');
              if (value is List && value.isEmpty) {
                debugPrint('⚠️ [QUERIES] Value list is empty. Response structure: ${response.data}');
                // Maybe queries are directly in response, not in value
                // Try processing the whole response
                dataToProcess = response.data;
              } else {
                dataToProcess = value;
              }
            }
            
            final queries = <SavedQuery>[];
            _extractQueries(dataToProcess, queries, '');
            
            debugPrint('✅ [QUERIES] Extracted ${queries.length} queries from endpoint: $url');
            
            if (queries.isNotEmpty) {
              return queries;
            } else {
              debugPrint('⚠️ [QUERIES] No queries extracted, trying to process response directly...');
              // Try processing response as a single query folder
              final directQueries = <SavedQuery>[];
              _extractQueries(response.data, directQueries, '');
              if (directQueries.isNotEmpty) {
                debugPrint('✅ [QUERIES] Found ${directQueries.length} queries by processing response directly');
                return directQueries;
              }
              debugPrint('⚠️ [QUERIES] No queries found, response data: ${response.data}');
            }
          } else {
            debugPrint('⚠️ [QUERIES] Status code: ${response.statusCode} for $url');
            if (response.data != null) {
              debugPrint('⚠️ [QUERIES] Error response: ${response.data}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ [QUERIES] Error with endpoint $url: $e');
          continue;
        }
      }
      
      // If no queries found with MyQueries filter, try without filter (get all queries)
      debugPrint('🔄 [QUERIES] Trying without MyQueries filter...');
      List<String> allQueriesEndpoints = [];
      
      if (project != null && project.isNotEmpty) {
        if (collection != null && collection.isNotEmpty) {
          allQueriesEndpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries?\$depth=2&api-version=7.0');
        }
        allQueriesEndpoints.add('$cleanUrl/$project/_apis/wit/queries?\$depth=2&api-version=7.0');
      }
      
      if (collection != null && collection.isNotEmpty) {
        allQueriesEndpoints.add('$cleanUrl/$collection/_apis/wit/queries?\$depth=2&api-version=7.0');
      }
      
      for (final url in allQueriesEndpoints) {
        try {
          debugPrint('🔍 [QUERIES] Trying endpoint (all queries): $url');
          
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          if (response.statusCode == 200) {
            debugPrint('✅ [QUERIES] Response received (all queries), keys: ${response.data.keys.toList()}');
            
            // Check if response has 'value' key
            dynamic dataToProcess = response.data;
            if (response.data is Map && response.data.containsKey('value')) {
              final value = response.data['value'];
              debugPrint('📦 [QUERIES] Found value key (all queries), type: ${value.runtimeType}, length: ${value is List ? value.length : 'N/A'}');
              dataToProcess = value;
            }
            
            final queries = <SavedQuery>[];
            _extractQueries(dataToProcess, queries, '');
            
            debugPrint('✅ [QUERIES] Extracted ${queries.length} queries (all queries)');
            
            if (queries.isNotEmpty) {
              return queries;
            } else {
              debugPrint('⚠️ [QUERIES] No queries extracted (all queries), response data: ${response.data}');
            }
          } else {
            debugPrint('⚠️ [QUERIES] Status code: ${response.statusCode} for $url');
            if (response.data != null) {
              debugPrint('⚠️ [QUERIES] Error response: ${response.data}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ [QUERIES] Error with endpoint $url: $e');
          continue;
        }
      }

      debugPrint('⚠️ [QUERIES] No queries found in any endpoint');
      return [];
    } catch (e) {
      debugPrint('❌ [QUERIES] Get saved queries error: $e');
      return [];
    }
  }

  /// Get shared queries
  Future<List<SavedQuery>> getSharedQueries({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      List<String> endpoints = [];
      
      if (project != null && project.isNotEmpty) {
        if (collection != null && collection.isNotEmpty) {
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries/Shared%20Queries?\$depth=2&api-version=7.0');
        }
        endpoints.add('$cleanUrl/$project/_apis/wit/queries/Shared%20Queries?\$depth=2&api-version=7.0');
      }
      
      if (collection != null && collection.isNotEmpty) {
        endpoints.add('$cleanUrl/$collection/_apis/wit/queries/Shared%20Queries?\$depth=2&api-version=7.0');
      }
      
      endpoints.add('$cleanUrl/_apis/wit/queries/Shared%20Queries?\$depth=2&api-version=7.0');

      for (final url in endpoints) {
        try {
          debugPrint('🔍 [QUERIES] Trying Shared Queries endpoint: $url');
          
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          if (response.statusCode == 200) {
            dynamic dataToProcess = response.data;
            if (response.data is Map && response.data.containsKey('value')) {
              final value = response.data['value'];
              if (value is List && value.isNotEmpty) {
                dataToProcess = value;
              }
            }
            
            final queries = <SavedQuery>[];
            _extractQueries(dataToProcess, queries, '');
            
            if (queries.isNotEmpty) {
              debugPrint('✅ [QUERIES] Found ${queries.length} shared queries');
              return queries;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [QUERIES] Error with Shared Queries endpoint $url: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ [QUERIES] Get shared queries error: $e');
      return [];
    }
  }

  /// Get favorite queries
  Future<List<SavedQuery>> getFavoriteQueries({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      List<String> endpoints = [];
      
      if (project != null && project.isNotEmpty) {
        if (collection != null && collection.isNotEmpty) {
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries?\$filter=Favorites&\$depth=2&api-version=7.0');
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/queries/Favorites?\$depth=2&api-version=7.0');
        }
        endpoints.add('$cleanUrl/$project/_apis/wit/queries?\$filter=Favorites&\$depth=2&api-version=7.0');
        endpoints.add('$cleanUrl/$project/_apis/wit/queries/Favorites?\$depth=2&api-version=7.0');
      }
      
      if (collection != null && collection.isNotEmpty) {
        endpoints.add('$cleanUrl/$collection/_apis/wit/queries?\$filter=Favorites&\$depth=2&api-version=7.0');
        endpoints.add('$cleanUrl/$collection/_apis/wit/queries/Favorites?\$depth=2&api-version=7.0');
      }

      for (final url in endpoints) {
        try {
          debugPrint('🔍 [QUERIES] Trying Favorites endpoint: $url');
          
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          if (response.statusCode == 200) {
            dynamic dataToProcess = response.data;
            if (response.data is Map && response.data.containsKey('value')) {
              final value = response.data['value'];
              if (value is List && value.isNotEmpty) {
                dataToProcess = value;
              }
            }
            
            final queries = <SavedQuery>[];
            _extractQueries(dataToProcess, queries, '');
            
            if (queries.isNotEmpty) {
              debugPrint('✅ [QUERIES] Found ${queries.length} favorite queries');
              return queries;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [QUERIES] Error with Favorites endpoint $url: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ [QUERIES] Get favorite queries error: $e');
      return [];
    }
  }

  /// Recursively extract queries from API response
  void _extractQueries(dynamic data, List<SavedQuery> queries, String path) {
    if (data is Map<String, dynamic>) {
      final isFolder = data['isFolder'] as bool? ?? false;
      final name = data['name'] as String? ?? '';
      final currentPath = path.isEmpty ? name : '$path/$name';
      
      debugPrint('🔍 [QUERIES] Processing: $name (isFolder: $isFolder, path: $currentPath)');
      debugPrint('🔍 [QUERIES] Data keys: ${data.keys.toList()}');
      
      // Check if this is a query (not a folder and has url or wiql)
      if (!isFolder) {
        // Check if it has wiql directly
        if (data.containsKey('wiql')) {
          final wiql = data['wiql'] as String? ?? '';
          if (wiql.isNotEmpty) {
            try {
              final query = SavedQuery.fromJson(data);
              queries.add(query);
              debugPrint('✅ [QUERIES] Found query with wiql: ${query.name} (path: $currentPath, id: ${query.id})');
            } catch (e) {
              debugPrint('⚠️ [QUERIES] Error parsing query: $e, data keys: ${data.keys.toList()}');
            }
          }
        } 
        // If no wiql but has url, it's a query that needs to be fetched
        else if (data.containsKey('url') && data.containsKey('id')) {
          try {
            // Create query without wiql - we'll fetch it when needed
            final query = SavedQuery(
              id: data['id'] as String,
              name: name,
              path: currentPath,
              wiql: '', // Will be fetched when query is executed
              url: data['url'] as String,
            );
            queries.add(query);
            debugPrint('✅ [QUERIES] Found query with url: ${query.name} (path: $currentPath, id: ${query.id})');
          } catch (e) {
            debugPrint('⚠️ [QUERIES] Error creating query from url: $e, data keys: ${data.keys.toList()}');
          }
        } else {
          debugPrint('📄 [QUERIES] Item is not a folder but has no wiql or url: $name (keys: ${data.keys.toList()})');
        }
      } else {
        debugPrint('📁 [QUERIES] Skipping folder: $name');
      }
      
      // Check for children (recursively) - even if it's a folder
      if (data.containsKey('children')) {
        final children = data['children'] as List?;
        if (children != null && children.isNotEmpty) {
          debugPrint('📁 [QUERIES] Found ${children.length} children in: $currentPath');
          for (var i = 0; i < children.length; i++) {
            final child = children[i];
            debugPrint('  🔍 [QUERIES] Processing child $i/${children.length}');
            if (child is Map<String, dynamic>) {
              debugPrint('  📋 [QUERIES] Child $i keys: ${child.keys.toList()}, name: ${child['name']}, isFolder: ${child['isFolder']}');
            }
            _extractQueries(child, queries, currentPath);
          }
        } else {
          debugPrint('📁 [QUERIES] No children or empty children list in: $currentPath');
        }
      }
      
      // Also check for 'value' key (some API responses wrap data in 'value')
      if (data.containsKey('value')) {
        debugPrint('📦 [QUERIES] Found value key, extracting...');
        _extractQueries(data['value'], queries, path);
      }
    } else if (data is List) {
      debugPrint('📋 [QUERIES] Processing list with ${data.length} items');
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        debugPrint('  🔍 [QUERIES] Processing list item $i/${data.length}');
        _extractQueries(item, queries, path);
      }
    } else {
      debugPrint('⚠️ [QUERIES] Unexpected data type: ${data.runtimeType}');
    }
  }

  /// Fetch query details by URL to get WIQL
  Future<String?> fetchQueryWiql({
    required String queryUrl,
    required String token,
    required String serverUrl, // Server URL from login (with correct hostname)
  }) async {
    try {
      // Replace hostname in queryUrl with serverUrl's hostname
      String urlWithCorrectHostname = queryUrl;
      try {
        final queryUri = Uri.parse(queryUrl);
        final serverUri = Uri.parse(serverUrl);
        
        // Replace the hostname and scheme from queryUrl with serverUrl's hostname and scheme
        urlWithCorrectHostname = queryUrl.replaceFirst(
          '${queryUri.scheme}://${queryUri.host}',
          '${serverUri.scheme}://${serverUri.host}',
        );
        
        debugPrint('🔍 [QUERIES] Original URL: $queryUrl');
        debugPrint('🔍 [QUERIES] Server URL: $serverUrl');
        debugPrint('🔍 [QUERIES] Replaced URL: $urlWithCorrectHostname');
      } catch (e) {
        debugPrint('⚠️ [QUERIES] Error parsing URLs: $e, using original URL');
      }
      
      // Add $expand=wiql and api-version parameters if not present
      String urlWithParams = urlWithCorrectHostname;
      bool hasParams = urlWithParams.contains('?');
      
      if (!urlWithParams.contains('\$expand=') && !urlWithParams.contains('%24expand=')) {
        urlWithParams = hasParams 
            ? '$urlWithParams&\$expand=wiql'
            : '$urlWithParams?\$expand=wiql';
        hasParams = true;
      }
      
      if (!urlWithParams.contains('api-version=')) {
        urlWithParams = hasParams 
            ? '$urlWithParams&api-version=7.0'
            : '$urlWithParams?api-version=7.0';
      }
      
      debugPrint('🔍 [QUERIES] Final URL: $urlWithParams');
      
      debugPrint('🔍 [QUERIES] Fetching query from: $urlWithParams');
      
      final response = await _dio.get(
        urlWithParams,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('📦 [QUERIES] Response status: ${response.statusCode}');
      debugPrint('📦 [QUERIES] Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'not a map'}');
      
      if (response.statusCode == 200) {
        // Check multiple possible keys for WIQL
        String? wiql;
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          wiql = data['wiql'] as String?;
          
          // If wiql is null, check if it's in a different format
          if (wiql == null || wiql.isEmpty) {
            debugPrint('⚠️ [QUERIES] WIQL not found in response. Full response: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}');
          } else {
            debugPrint('✅ [QUERIES] Fetched WIQL from URL: ${wiql.substring(0, wiql.length > 100 ? 100 : wiql.length)}...');
          }
        }
        return wiql;
      } else {
        debugPrint('⚠️ [QUERIES] Failed to fetch query. Status: ${response.statusCode}, Response: ${response.data}');
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('⚠️ [QUERIES] Error fetching query WIQL: $e');
      debugPrint('⚠️ [QUERIES] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Execute a query and return work items
  Future<List<WorkItem>> executeQuery({
    required String serverUrl,
    required String token,
    required String wiql,
    String? collection,
    String? username, // Optional username to replace @me in query
    String? project, // Optional project name to replace @project in query
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      // Replace @me and @project in WIQL query
      String processedWiql = wiql;
      
      // Get current user identity from API if @me is in query
      if (wiql.contains('@me')) {
        try {
          // Try profile API endpoint (more reliable for Azure DevOps Server)
          String? profileUrl;
          if (collection != null && collection.isNotEmpty) {
            profileUrl = '$cleanUrl/$collection/_apis/profile/profiles/me?api-version=7.0-preview';
          } else {
            profileUrl = '$cleanUrl/_apis/profile/profiles/me?api-version=7.0-preview';
          }
          
          debugPrint('🔍 [EXECUTE] Getting user identity from: $profileUrl');
          
          final profileResponse = await _dio.get(
            profileUrl,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500,
            ),
          );
          
          String? userIdentity;
          
          if (profileResponse.statusCode == 200) {
            final profileData = profileResponse.data;
            if (profileData is Map) {
              // Try different possible keys for user identity
              userIdentity = profileData['displayName'] as String? ??
                            profileData['publicAlias'] as String? ??
                            profileData['emailAddress'] as String? ??
                            profileData['coreAttributes']?['DisplayName']?['value'] as String? ??
                            profileData['coreAttributes']?['Mail']?['value'] as String?;
              
              debugPrint('📦 [EXECUTE] Profile response keys: ${profileData.keys.toList()}');
            }
          } else {
            debugPrint('⚠️ [EXECUTE] Profile API returned status: ${profileResponse.statusCode}');
          }
          
          // If profile API didn't work, try to get from work items (get assigned to field from existing work items)
          if (userIdentity == null || userIdentity.isEmpty) {
            debugPrint('🔄 [EXECUTE] Trying to get user identity from work items...');
            try {
              final testWorkItems = await getWorkItems(
                serverUrl: serverUrl,
                token: token,
                collection: collection,
              );
              
              if (testWorkItems.isNotEmpty) {
                // Get assigned to from first work item that has assigned to
                for (var item in testWorkItems) {
                  if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
                    userIdentity = item.assignedTo;
                    debugPrint('✅ [EXECUTE] Got user identity from work item: $userIdentity');
                    break;
                  }
                }
              }
            } catch (e) {
              debugPrint('⚠️ [EXECUTE] Error getting user from work items: $e');
            }
          }
          
          if (userIdentity != null && userIdentity.isNotEmpty) {
            // Replace @me with user identity (wrap in quotes for WIQL)
            processedWiql = processedWiql.replaceAll('@me', "'$userIdentity'");
            debugPrint('🔄 [EXECUTE] Replaced @me with user identity: $userIdentity');
          } else if (username != null && username.isNotEmpty) {
            // Fallback to provided username (wrap in quotes)
            processedWiql = processedWiql.replaceAll('@me', "'$username'");
            debugPrint('🔄 [EXECUTE] Replaced @me with username (fallback): $username');
          } else {
            debugPrint('⚠️ [EXECUTE] Could not get user identity, @me will remain in query (Azure DevOps Server should handle it)');
          }
        } catch (e) {
          debugPrint('⚠️ [EXECUTE] Error getting user identity: $e');
          // Fallback to username if provided
          if (username != null && username.isNotEmpty) {
            processedWiql = processedWiql.replaceAll('@me', "'$username'");
            debugPrint('🔄 [EXECUTE] Replaced @me with username (fallback after error): $username');
          }
        }
      }
      
      // Replace @project with actual project name if provided (wrap in quotes for WIQL)
      if (project != null && project.isNotEmpty && processedWiql.contains('@project')) {
        processedWiql = processedWiql.replaceAll('@project', "'$project'");
        debugPrint('🔄 [EXECUTE] Replaced @project with: $project');
      }

      // Execute WIQL query
      final queryUrl = '$baseUrl/_apis/wit/wiql?api-version=7.0';

      debugPrint('🔍 [EXECUTE] Original WIQL: $wiql');
      debugPrint('🔍 [EXECUTE] Processed WIQL: $processedWiql');
      debugPrint('🔍 [EXECUTE] Query URL: $queryUrl');

      final response = await _dio.post(
        queryUrl,
        data: {'query': processedWiql},
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('📦 [EXECUTE] WIQL response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final workItemIds = (response.data['workItems'] as List)
            .map((item) => item['id'] as int)
            .toList();

        debugPrint('✅ [EXECUTE] Found ${workItemIds.length} work item IDs');

        if (workItemIds.isEmpty) {
          debugPrint('⚠️ [EXECUTE] No work items found for query');
          return [];
        }

        // Get work item details
        final detailsUrl = '$baseUrl/_apis/wit/workitems?ids=${workItemIds.join(',')}&\$expand=all&api-version=7.0';

        debugPrint('🔍 [EXECUTE] Fetching work item details: $detailsUrl');

        final detailsResponse = await _dio.get(
          detailsUrl,
          options: Options(
            headers: {
              'Authorization': 'Basic ${_encodeToken(token)}',
              'Content-Type': 'application/json',
            },
          ),
        );

        debugPrint('📦 [EXECUTE] Details response status: ${detailsResponse.statusCode}');

        if (detailsResponse.statusCode == 200) {
          final workItems = (detailsResponse.data['value'] as List)
              .map((item) => WorkItem.fromJson(item))
              .toList();
          debugPrint('✅ [EXECUTE] Loaded ${workItems.length} work items');
          return workItems;
        } else {
          debugPrint('⚠️ [EXECUTE] Failed to get work item details. Status: ${detailsResponse.statusCode}');
        }
      } else {
        debugPrint('⚠️ [EXECUTE] WIQL query failed. Status: ${response.statusCode}, Response: ${response.data}');
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [EXECUTE] Execute query error: $e');
      debugPrint('❌ [EXECUTE] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<WorkItem>> getWorkItems({
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

      // Get work items query
      final queryUrl = '$baseUrl/_apis/wit/wiql?api-version=7.0';
      
      // Optimized WIQL query: only get essential fields for performance
      final wiqlQuery = {
        'query': "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.ChangedDate] FROM WorkItems WHERE [System.AssignedTo] = @me ORDER BY [System.ChangedDate] DESC"
      };

      final response = await _dio.post(
        queryUrl,
        data: wiqlQuery,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final workItemIds = (response.data['workItems'] as List)
            .map((item) => item['id'] as int)
            .toList();

        if (workItemIds.isEmpty) return [];

        // Get work item details
        final detailsUrl = '$baseUrl/_apis/wit/workitems?ids=${workItemIds.join(',')}&api-version=7.0';
        
        final detailsResponse = await _dio.get(
          detailsUrl,
          options: Options(
            headers: {
              'Authorization': 'Basic ${_encodeToken(token)}',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (detailsResponse.statusCode == 200) {
          return (detailsResponse.data['value'] as List)
              .map((item) => WorkItem.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get work items error: $e');
      return [];
    }
  }

  Future<WorkItem?> getWorkItemDetails({
    required String serverUrl,
    required String token,
    required int workItemId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      // Get work item with relations (use expand=relations to get relations)
      final url = '$baseUrl/_apis/wit/workitems/$workItemId?\$expand=relations&api-version=7.0';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final workItem = WorkItem.fromJson(response.data);
        
        // Check relations in response
        if (response.data.containsKey('relations')) {
          final relations = response.data['relations'] as List?;
          debugPrint('✅ [getWorkItemDetails] Work item #$workItemId has ${relations?.length ?? 0} relations');
          if (relations != null && relations.isNotEmpty) {
            debugPrint('📋 [getWorkItemDetails] First relation: ${relations[0]}');
          }
        } else {
          debugPrint('⚠️ [getWorkItemDetails] Work item #$workItemId has no relations key');
          debugPrint('📦 [getWorkItemDetails] Response keys: ${response.data.keys.toList()}');
        }
        
        return workItem;
      }

      return null;
    } catch (e) {
      debugPrint('Get work item details error: $e');
      return null;
    }
  }
  
  /// Get related work items from relations array directly (no extra API call)
  Future<Map<String, List<RelatedWorkItem>>> getRelatedWorkItemsFromResponse({
    required String serverUrl,
    required String token,
    required List<dynamic> relations,
    required int workItemId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      debugPrint('🔄 [FROM_RESPONSE] Processing ${relations.length} relations directly from getWorkItemDetails response');

      // Group relations by type and extract IDs
      final childIds = <int>[];
      final relatedIds = <int>[];
      final parentIds = <int>[];
      final relationMap = <int, Map<String, dynamic>>{};

      for (var i = 0; i < relations.length; i++) {
        final relation = relations[i] as Map<String, dynamic>;
        final rel = relation['rel'] as String? ?? '';
        final relationUrl = relation['url'] as String? ?? '';
        final attributes = relation['attributes'] as Map<String, dynamic>?;
        
        debugPrint('🔍 [FROM_RESPONSE] Relation $i: rel=$rel, url=$relationUrl');
        
        // Only process work item links
        if (relationUrl.isEmpty || !relationUrl.contains('/workitems/')) {
          debugPrint('⏭️ [FROM_RESPONSE] Skipping non-workitem link');
          continue;
        }
        
          try {
            // Try multiple parsing methods
            int? id;
            
            // Method 1: Uri.parse with case-insensitive search
            try {
              final uri = Uri.parse(relationUrl);
              final pathSegments = uri.pathSegments;
              // Case-insensitive search for workitems/workItems
              int workitemsIndex = -1;
              for (int i = 0; i < pathSegments.length; i++) {
                if (pathSegments[i].toLowerCase() == 'workitems') {
                  workitemsIndex = i;
                  break;
                }
              }
              if (workitemsIndex != -1 && workitemsIndex + 1 < pathSegments.length) {
                id = int.tryParse(pathSegments[workitemsIndex + 1]);
                debugPrint('✅ [FROM_RESPONSE] Extracted ID $id from path segment at index ${workitemsIndex + 1}');
              }
            } catch (e) {
              debugPrint('⚠️ [FROM_RESPONSE] Uri.parse failed: $e');
            }
            
            // Method 2: String split (case-insensitive, fallback)
            if (id == null) {
              try {
                // Case-insensitive split
                final lowerUrl = relationUrl.toLowerCase();
                final workitemsIndex = lowerUrl.indexOf('/workitems/');
                if (workitemsIndex != -1) {
                  final afterWorkItems = relationUrl.substring(workitemsIndex + '/workitems/'.length);
                  final idStr = afterWorkItems.split('?').first.split('/').first.trim();
                  id = int.tryParse(idStr);
                  debugPrint('✅ [FROM_RESPONSE] Extracted ID $id using string split');
                }
              } catch (e) {
                debugPrint('⚠️ [FROM_RESPONSE] String split failed: $e');
              }
            }
          
          if (id != null && id != workItemId) {
            debugPrint('✅ [FROM_RESPONSE] Extracted ID: $id from URL: $relationUrl');
            relationMap[id] = {
              'rel': rel,
              'attributes': attributes,
            };
            
            // Categorize by relation type
            if (rel == 'System.LinkTypes.Hierarchy-Forward' || 
                rel.contains('Hierarchy-Forward')) {
              if (!childIds.contains(id)) {
                childIds.add(id);
                debugPrint('➕ [FROM_RESPONSE] Added $id to Child');
              }
            } else if (rel == 'System.LinkTypes.Hierarchy-Reverse' || 
                       rel.contains('Hierarchy-Reverse')) {
              if (!parentIds.contains(id)) {
                parentIds.add(id);
                debugPrint('➕ [FROM_RESPONSE] Added $id to Parent');
              }
            } else {
              if (!relatedIds.contains(id)) {
                relatedIds.add(id);
                debugPrint('➕ [FROM_RESPONSE] Added $id to Related (rel: $rel)');
              }
            }
          } else {
            debugPrint('⚠️ [FROM_RESPONSE] Could not extract ID from: $relationUrl');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [FROM_RESPONSE] Error parsing relation $i: $e');
          debugPrint('❌ [FROM_RESPONSE] Stack: $stackTrace');
          continue;
        }
      }

      final allIds = {...childIds, ...relatedIds, ...parentIds};
      debugPrint('📊 [FROM_RESPONSE] Total IDs: ${allIds.length} (Child: ${childIds.length}, Related: ${relatedIds.length}, Parent: ${parentIds.length})');
      
      if (allIds.isEmpty) {
        debugPrint('⚠️ [FROM_RESPONSE] No work item IDs extracted');
        return {};
      }

      // Get all related work items details
      final relatedUrl = '$baseUrl/_apis/wit/workitems?ids=${allIds.join(',')}&api-version=7.0';
      debugPrint('🔍 [FROM_RESPONSE] Fetching work items: $relatedUrl');
      
      final relatedResponse = await _dio.get(
        relatedUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (relatedResponse.statusCode != 200) {
        debugPrint('❌ [FROM_RESPONSE] Failed to get work items: ${relatedResponse.statusCode}');
        return {};
      }

      final items = (relatedResponse.data['value'] as List)
          .map((item) => WorkItem.fromJson(item))
          .toList();
      
      debugPrint('✅ [FROM_RESPONSE] Loaded ${items.length} work items');
      
      // Group items by relation type
      final result = <String, List<RelatedWorkItem>>{};
      
      for (var item in items) {
        final relationInfo = relationMap[item.id];
        final attributes = relationInfo?['attributes'] as Map<String, dynamic>?;
        
        DateTime? changedDate;
        if (attributes != null && attributes.containsKey('changedDate')) {
          changedDate = DateTime.tryParse(attributes['changedDate'] as String);
        }
        changedDate ??= item.changedDate;
        
        final relatedItem = RelatedWorkItem(
          workItem: item,
          relationType: relationInfo?['rel'] as String? ?? '',
          changedDate: changedDate,
        );
        
        if (childIds.contains(item.id)) {
          result.putIfAbsent('Child', () => []).add(relatedItem);
        } else if (parentIds.contains(item.id)) {
          result.putIfAbsent('Parent', () => []).add(relatedItem);
        } else if (relatedIds.contains(item.id)) {
          result.putIfAbsent('Related', () => []).add(relatedItem);
        }
      }
      
      debugPrint('✅ [FROM_RESPONSE] Final result: ${result.keys.toList()} with ${result.values.fold<int>(0, (sum, list) => sum + list.length)} items');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [FROM_RESPONSE] Error: $e');
      debugPrint('❌ [FROM_RESPONSE] Stack: $stackTrace');
      return {};
    }
  }
  
  /// Get related work items from relations array (helper method)
  Future<Map<String, List<RelatedWorkItem>>> getRelatedWorkItemsFromRelations({
    required String serverUrl,
    required String token,
    required List<dynamic> relations,
    required int workItemId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      // Group relations by type and extract IDs
      final childIds = <int>[];
      final relatedIds = <int>[];
      final parentIds = <int>[];
      final relationMap = <int, Map<String, dynamic>>{};

      for (var relation in relations) {
        final relationData = relation as Map<String, dynamic>;
        final rel = relationData['rel'] as String? ?? '';
        final relationUrl = relationData['url'] as String? ?? '';
        final attributes = relationData['attributes'] as Map<String, dynamic>?;
        
        // Only process work item links (case-insensitive)
        final lowerUrl = relationUrl.toLowerCase();
        if (relationUrl.isEmpty || !lowerUrl.contains('/workitems/')) {
          continue;
        }
        
        try {
          // Extract work item ID from URL (case-insensitive)
          final uri = Uri.parse(relationUrl);
          final pathSegments = uri.pathSegments;
          
          // Case-insensitive search for workitems/workItems
          int workitemsIndex = -1;
          for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i].toLowerCase() == 'workitems') {
              workitemsIndex = i;
              break;
            }
          }
          
          if (workitemsIndex != -1 && workitemsIndex + 1 < pathSegments.length) {
            final idStr = pathSegments[workitemsIndex + 1];
            final id = int.tryParse(idStr);
            
            if (id != null && id != workItemId) {
              relationMap[id] = {
                'rel': rel,
                'attributes': attributes,
              };
              
              // Categorize by relation type
              if (rel == 'System.LinkTypes.Hierarchy-Forward' || 
                  rel.contains('Hierarchy-Forward')) {
                if (!childIds.contains(id)) childIds.add(id);
              } else if (rel == 'System.LinkTypes.Hierarchy-Reverse' || 
                         rel.contains('Hierarchy-Reverse')) {
                if (!parentIds.contains(id)) parentIds.add(id);
              } else {
                if (!relatedIds.contains(id)) relatedIds.add(id);
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing relation URL $relationUrl: $e');
          continue;
        }
      }

      final allIds = {...childIds, ...relatedIds, ...parentIds};
      if (allIds.isEmpty) {
        return {};
      }

      // Get all related work items details
      final relatedUrl = '$baseUrl/_apis/wit/workitems?ids=${allIds.join(',')}&api-version=7.0';
      
      final relatedResponse = await _dio.get(
        relatedUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (relatedResponse.statusCode != 200) {
        return {};
      }

      final items = (relatedResponse.data['value'] as List)
          .map((item) => WorkItem.fromJson(item))
          .toList();
      
      // Group items by relation type
      final result = <String, List<RelatedWorkItem>>{};
      
      for (var item in items) {
        final relationInfo = relationMap[item.id];
        final attributes = relationInfo?['attributes'] as Map<String, dynamic>?;
        
        DateTime? changedDate;
        if (attributes != null && attributes.containsKey('changedDate')) {
          changedDate = DateTime.tryParse(attributes['changedDate'] as String);
        }
        changedDate ??= item.changedDate;
        
        final relatedItem = RelatedWorkItem(
          workItem: item,
          relationType: relationInfo?['rel'] as String? ?? '',
          changedDate: changedDate,
        );
        
        if (childIds.contains(item.id)) {
          result.putIfAbsent('Child', () => []).add(relatedItem);
        } else if (parentIds.contains(item.id)) {
          result.putIfAbsent('Parent', () => []).add(relatedItem);
        } else if (relatedIds.contains(item.id)) {
          result.putIfAbsent('Related', () => []).add(relatedItem);
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Get related work items from relations error: $e');
      return {};
    }
  }

  /// Get related work items for a given work item
  Future<List<WorkItem>> getRelatedWorkItems({
    required String serverUrl,
    required String token,
    required int workItemId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      // Get work item with relations (use expand=all to get all data including relations)
      final url = '$baseUrl/_apis/wit/workitems/$workItemId?\$expand=all&api-version=7.0';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final relations = response.data['relations'] as List?;
        if (relations == null || relations.isEmpty) {
          return [];
        }

        // Extract related work item IDs from relations
        final relatedIds = <int>[];
        for (var relation in relations) {
          final url = relation['url'] as String? ?? '';
          
          // Get all work item links (Parent, Child, Related, etc.)
          // Check if URL contains workitems
          if (url.isNotEmpty && url.contains('/workitems/')) {
            // Extract ID from URL - simpler approach
            // URL format examples:
            // https://server/tfs/collection/project/_apis/wit/workitems/12345
            // https://server/collection/project/_apis/wit/workitems/12345?api-version=7.0
            try {
              final parts = url.split('/workitems/');
              if (parts.length > 1) {
                // Get the part after /workitems/
                final idPart = parts[1];
                // Remove query parameters and trailing slashes
                final idStr = idPart.split('?').first.split('/').first.trim();
                final id = int.tryParse(idStr);
                if (id != null && id != workItemId && !relatedIds.contains(id)) {
                  relatedIds.add(id);
                }
              }
            } catch (e) {
              // Skip this relation if parsing fails
              continue;
            }
          }
        }

        if (relatedIds.isEmpty) {
          return [];
        }

        // Get related work items details
        final relatedUrl = '$baseUrl/_apis/wit/workitems?ids=${relatedIds.join(',')}&api-version=7.0';
        
        final relatedResponse = await _dio.get(
          relatedUrl,
          options: Options(
            headers: {
              'Authorization': 'Basic ${_encodeToken(token)}',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (relatedResponse.statusCode == 200) {
          return (relatedResponse.data['value'] as List)
              .map((item) => WorkItem.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get related work items error: $e');
      return [];
    }
  }

  /// Get related work items grouped by relation type (Child, Related, Parent)
  /// Based on Azure DevOps Server 2022 REST API documentation
  Future<Map<String, List<RelatedWorkItem>>> getRelatedWorkItemsGrouped({
    required String serverUrl,
    required String token,
    required int workItemId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      // According to Azure DevOps API docs: GET /_apis/wit/workitems/{id}?$expand=relations&api-version=7.0
      final url = '$baseUrl/_apis/wit/workitems/$workItemId?\$expand=relations&api-version=7.0';
      
      debugPrint('🔍 [RELATIONS] ==========================================');
      debugPrint('🔍 [RELATIONS] Fetching relations for work item $workItemId');
      debugPrint('🔍 [RELATIONS] URL: $url');
      debugPrint('🔍 [RELATIONS] Base URL: $baseUrl');
      debugPrint('🔍 [RELATIONS] ==========================================');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ [RELATIONS] Failed to get work item: ${response.statusCode}');
        if (response.data != null) {
          debugPrint('❌ [RELATIONS] Error response: ${response.data}');
        }
        return {};
      }

      // Check if relations exist in response
      debugPrint('📦 [RELATIONS] Response keys: ${response.data.keys.toList()}');
      debugPrint('📦 [RELATIONS] Response has relations: ${response.data.containsKey('relations')}');
      
      if (!response.data.containsKey('relations')) {
        debugPrint('⚠️ [RELATIONS] No relations key in response');
        // Try to see what's in the response
        if (response.data.containsKey('fields')) {
          debugPrint('📦 [RELATIONS] Response has fields, but no relations');
        }
        return {};
      }
        
      final relations = response.data['relations'] as List?;
      
      if (relations == null || relations.isEmpty) {
        debugPrint('⚠️ [RELATIONS] Relations list is empty or null');
        debugPrint('⚠️ [RELATIONS] This work item has no relations');
        return {};
      }
        
      debugPrint('✅ [RELATIONS] Found ${relations.length} relations');
      
      // Log ALL relations for debugging
      for (var i = 0; i < relations.length; i++) {
        final relation = relations[i] as Map<String, dynamic>;
        debugPrint('📋 [RELATIONS] Relation $i:');
        debugPrint('   - rel: ${relation['rel']}');
        debugPrint('   - url: ${relation['url']}');
        debugPrint('   - attributes: ${relation['attributes']}');
      }

      // Group relations by type and extract IDs
      // According to Azure DevOps API docs:
      // - System.LinkTypes.Hierarchy-Forward = Child
      // - System.LinkTypes.Hierarchy-Reverse = Parent  
      // - System.LinkTypes.Related = Related
      final childIds = <int>[];
      final relatedIds = <int>[];
      final parentIds = <int>[];
      final relationMap = <int, Map<String, dynamic>>{};

      for (var i = 0; i < relations.length; i++) {
        final relation = relations[i] as Map<String, dynamic>;
        final rel = relation['rel'] as String? ?? '';
        final relationUrl = relation['url'] as String? ?? '';
        final attributes = relation['attributes'] as Map<String, dynamic>?;
        
        // Only process work item links (case-insensitive)
        final lowerUrl = relationUrl.toLowerCase();
        if (relationUrl.isEmpty || !lowerUrl.contains('/workitems/')) {
          debugPrint('⚠️ [RELATIONS] Skipping non-work item relation: $relationUrl');
          continue;
        }
        
        try {
          // Extract work item ID from URL
          // URL format: https://server/collection/project/_apis/wit/workItems/12345 (camelCase)
          // or: /collection/project/_apis/wit/workitems/12345 (lowercase)
          debugPrint('🔍 [RELATIONS] Parsing URL: $relationUrl');
          
          final uri = Uri.parse(relationUrl);
          final pathSegments = uri.pathSegments;
          debugPrint('🔍 [RELATIONS] Path segments: $pathSegments');
          
          // Case-insensitive search for workitems/workItems
          int workitemsIndex = -1;
          for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i].toLowerCase() == 'workitems') {
              workitemsIndex = i;
              break;
            }
          }
          
          debugPrint('🔍 [RELATIONS] workitems index: $workitemsIndex');
          
          if (workitemsIndex != -1 && workitemsIndex + 1 < pathSegments.length) {
            final idStr = pathSegments[workitemsIndex + 1];
            debugPrint('🔍 [RELATIONS] Extracted ID string: $idStr');
            final id = int.tryParse(idStr);
            debugPrint('🔍 [RELATIONS] Parsed ID: $id');
            
            if (id != null && id != workItemId) {
              debugPrint('✅ [RELATIONS] Valid ID found: $id (rel: $rel)');
              relationMap[id] = {
                'rel': rel,
                'attributes': attributes,
              };
              
              // Categorize by relation type according to Azure DevOps API docs
              if (rel == 'System.LinkTypes.Hierarchy-Forward' || 
                  rel.contains('Hierarchy-Forward')) {
                if (!childIds.contains(id)) {
                  childIds.add(id);
                  debugPrint('➕ [RELATIONS] Added $id to Child');
                }
              } else if (rel == 'System.LinkTypes.Hierarchy-Reverse' || 
                         rel.contains('Hierarchy-Reverse')) {
                if (!parentIds.contains(id)) {
                  parentIds.add(id);
                  debugPrint('➕ [RELATIONS] Added $id to Parent');
                }
              } else if (rel == 'System.LinkTypes.Related' || 
                         rel.contains('Related')) {
                if (!relatedIds.contains(id)) {
                  relatedIds.add(id);
                  debugPrint('➕ [RELATIONS] Added $id to Related');
                }
              } else {
                // For other link types, default to Related
                if (!relatedIds.contains(id)) {
                  relatedIds.add(id);
                  debugPrint('➕ [RELATIONS] Added $id to Related (default, rel: $rel)');
                }
              }
            } else {
              debugPrint('⚠️ [RELATIONS] Invalid ID: $id (workItemId: $workItemId)');
            }
          } else {
            debugPrint('⚠️ [RELATIONS] Could not find workitems in path segments');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [RELATIONS] Error parsing relation URL $relationUrl: $e');
          debugPrint('❌ [RELATIONS] Stack trace: $stackTrace');
          continue;
        }
      }

      final allIds = {...childIds, ...relatedIds, ...parentIds};
      debugPrint('📊 Parsed IDs - Child: $childIds, Related: $relatedIds, Parent: $parentIds');
      debugPrint('📊 Total unique IDs: ${allIds.length}');
      
      if (allIds.isEmpty) {
        debugPrint('⚠️ No related work item IDs found after parsing relations');
        debugPrint('⚠️ This means relations exist but no work item IDs could be extracted');
        return {};
      }

      debugPrint('📊 Found ${allIds.length} related work items: Child=${childIds.length}, Related=${relatedIds.length}, Parent=${parentIds.length}');

      // Get all related work items details using batch API
      // According to Azure DevOps API docs: GET /_apis/wit/workitems?ids={ids}&api-version=7.0
      final relatedUrl = '$baseUrl/_apis/wit/workitems?ids=${allIds.join(',')}&api-version=7.0';
      
      debugPrint('🔍 Fetching related work items: $relatedUrl');
      
      final relatedResponse = await _dio.get(
        relatedUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (relatedResponse.statusCode != 200) {
        debugPrint('❌ Failed to get related work items: ${relatedResponse.statusCode}');
        return {};
      }

      final items = (relatedResponse.data['value'] as List)
          .map((item) => WorkItem.fromJson(item))
          .toList();
      
      debugPrint('✅ Loaded ${items.length} related work items');
      
      // Group items by relation type
      final result = <String, List<RelatedWorkItem>>{};
      
      for (var item in items) {
        final relationInfo = relationMap[item.id];
        final attributes = relationInfo?['attributes'] as Map<String, dynamic>?;
        
        // Get changed date from attributes or work item
        DateTime? changedDate;
        if (attributes != null && attributes.containsKey('changedDate')) {
          changedDate = DateTime.tryParse(attributes['changedDate'] as String);
        }
        changedDate ??= item.changedDate;
        
        final relatedItem = RelatedWorkItem(
          workItem: item,
          relationType: relationInfo?['rel'] as String? ?? '',
          changedDate: changedDate,
        );
        
        if (childIds.contains(item.id)) {
          result.putIfAbsent('Child', () => []).add(relatedItem);
        } else if (parentIds.contains(item.id)) {
          result.putIfAbsent('Parent', () => []).add(relatedItem);
        } else if (relatedIds.contains(item.id)) {
          result.putIfAbsent('Related', () => []).add(relatedItem);
        }
      }
      
      debugPrint('✅ Final result: ${result.keys.toList()} with ${result.values.fold<int>(0, (sum, list) => sum + list.length)} items');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Get related work items grouped error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {};
    }
  }

  Future<bool> updateWorkItem({
    required String serverUrl,
    required String token,
    required int workItemId,
    required List<Map<String, dynamic>> updates,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/_apis/wit/workitems/$workItemId?api-version=7.0';
      
      final patchBody = updates.map((update) => {
        'op': 'replace',
        'path': update['path'],
        'value': update['value'],
      }).toList();

      final response = await _dio.patch(
        url,
        data: patchBody,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json-patch+json',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update work item error: $e');
      return false;
    }
  }

  Future<List<String>> getWorkItemStates({
    required String serverUrl,
    required String token,
    required String workItemType,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      // Try multiple API endpoints
      List<String> endpoints = [];
      
      if (project != null && project.isNotEmpty) {
        // Try with project name first (most common)
        if (collection != null && collection.isNotEmpty) {
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/workitemtypes/$workItemType/states?api-version=7.0');
        }
        endpoints.add('$cleanUrl/$project/_apis/wit/workitemtypes/$workItemType/states?api-version=7.0');
      }
      
      // Fallback to collection-based
      if (collection != null && collection.isNotEmpty) {
        endpoints.add('$cleanUrl/$collection/_apis/wit/workitemtypes/$workItemType/states?api-version=7.0');
      }
      
      // Last resort: direct endpoint
      endpoints.add('$cleanUrl/_apis/wit/workitemtypes/$workItemType/states?api-version=7.0');
      
      for (final url in endpoints) {
        try {
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (response.statusCode == 200) {
            final states = (response.data['value'] as List)
                .map((state) => state['name'] as String)
                .toList();
            if (states.isNotEmpty) {
              debugPrint('States loaded from: $url');
              return states;
            }
          }
        } catch (e) {
          debugPrint('Failed to get states from $url: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get work item states error: $e');
      return [];
    }
  }

  Future<Map<String, FieldDefinition>> getWorkItemFieldDefinitions({
    required String serverUrl,
    required String token,
    required String workItemType,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      // Try multiple endpoints with project info
      List<String> endpoints = [];
      
      if (project != null && project.isNotEmpty) {
        if (collection != null && collection.isNotEmpty) {
          endpoints.add('$cleanUrl/$collection/$project/_apis/wit/workitemtypes/$workItemType/fields?\$expand=allowedValues&api-version=7.0');
        }
        endpoints.add('$cleanUrl/$project/_apis/wit/workitemtypes/$workItemType/fields?\$expand=allowedValues&api-version=7.0');
      }
      
      if (collection != null && collection.isNotEmpty) {
        endpoints.add('$cleanUrl/$collection/_apis/wit/workitemtypes/$workItemType/fields?\$expand=allowedValues&api-version=7.0');
      }
      
      endpoints.add('$cleanUrl/_apis/wit/workitemtypes/$workItemType/fields?\$expand=allowedValues&api-version=7.0');
      
      for (final url in endpoints) {
        try {
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (response.statusCode == 200) {
            final fields = <String, FieldDefinition>{};
            final fieldsList = response.data['value'] as List;
            
            for (var fieldData in fieldsList) {
              final refName = fieldData['referenceName'] as String;
              final allowedValues = (fieldData['allowedValues'] as List?)?.map((v) => v.toString()).toList() ?? [];
              final fieldType = fieldData['type'] as String? ?? '';
              
              // Check if it's a combo box: has allowed values and is string/picklist type
              final isComboBox = allowedValues.isNotEmpty && 
                  (fieldType == 'string' || 
                   fieldType == 'picklistString' || 
                   fieldType == 'picklistDouble' ||
                   fieldType == 'picklistInteger');
              
              fields[refName] = FieldDefinition(
                referenceName: refName,
                name: fieldData['name'] as String? ?? refName,
                type: fieldType,
                allowedValues: allowedValues,
                isComboBox: isComboBox,
              );
            }
            
            if (fields.isNotEmpty) {
              debugPrint('Field definitions loaded from: $url (${fields.length} fields)');
              return fields;
            }
          }
        } catch (e) {
          debugPrint('Failed to get field definitions from $url: $e');
          continue;
        }
      }

      return {};
    } catch (e) {
      debugPrint('Get field definitions error: $e');
      return {};
    }
  }
}

class WorkItem {
  final int id;
  final String title;
  final String type;
  final String state;
  final String? assignedTo;
  final String? description;
  final Map<String, dynamic>? allFields;
  final int? rev;

  WorkItem({
    required this.id,
    required this.title,
    required this.type,
    required this.state,
    this.assignedTo,
    this.description,
    this.allFields,
    this.rev,
  });

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>;
    return WorkItem(
      id: json['id'] as int,
      title: fields['System.Title'] as String? ?? '',
      type: fields['System.WorkItemType'] as String? ?? '',
      state: fields['System.State'] as String? ?? '',
      assignedTo: fields['System.AssignedTo']?['displayName'] as String?,
      description: fields['System.Description'] as String?,
      allFields: fields,
      rev: json['rev'] as int?,
    );
  }
  
  String? get project => allFields?['System.TeamProject'] as String?;
  
  DateTime? get changedDate {
    final dateStr = allFields?['System.ChangedDate'] as String?;
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'state': state,
      'assignedTo': assignedTo,
      'description': description,
      'allFields': allFields,
      'rev': rev,
    };
  }
}

class FieldDefinition {
  final String referenceName;
  final String name;
  final String type;
  final List<String> allowedValues;
  final bool isComboBox;

  FieldDefinition({
    required this.referenceName,
    required this.name,
    required this.type,
    required this.allowedValues,
    required this.isComboBox,
  });
}

class RelatedWorkItem {
  final WorkItem workItem;
  final String relationType;
  final DateTime? changedDate;

  RelatedWorkItem({
    required this.workItem,
    required this.relationType,
    this.changedDate,
  });
}

class SavedQuery {
  final String id;
  final String name;
  final String? path;
  final String wiql;
  final String? url;
  final bool isFolder;

  SavedQuery({
    required this.id,
    required this.name,
    this.path,
    required this.wiql,
    this.url,
    this.isFolder = false,
  });

  factory SavedQuery.fromJson(Map<String, dynamic> json) {
    return SavedQuery(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      path: json['path'] as String?,
      wiql: json['wiql'] as String? ?? '',
      url: json['url'] as String?,
      isFolder: json['isFolder'] as bool? ?? false,
    );
  }
}

