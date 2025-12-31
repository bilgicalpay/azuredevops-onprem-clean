/// Release servisi
/// 
/// AzureDevOps API'si ile release'leri yönetir.
/// Release listeleme, detay görüntüleme ve approval işlemlerini gerçekleştirir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';

/// Release model
class Release {
  final int id;
  final String name;
  final String? status;
  final String? releaseDefinitionName;
  final int? releaseDefinitionId;
  final String? projectName;
  final DateTime? createdOn;
  final DateTime? modifiedOn;
  final String? createdBy;
  final String? url;
  final List<ReleaseEnvironment> environments;
  final List<ReleaseApproval> approvals;

  Release({
    required this.id,
    required this.name,
    this.status,
    this.releaseDefinitionName,
    this.releaseDefinitionId,
    this.projectName,
    this.createdOn,
    this.modifiedOn,
    this.createdBy,
    this.environments = const [],
    this.approvals = const [],
    this.url,
  });

  factory Release.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('📋 [Release.fromJson] Parsing release JSON: ${json.keys.toList()}');
      debugPrint('📋 [Release.fromJson] ID: ${json['id']}, Name: ${json['name']}');
      
      final release = Release(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? json['releaseName'] as String? ?? '',
        status: json['status'] as String?,
        releaseDefinitionName: json['releaseDefinition']?['name'] as String? ?? 
                                json['definition']?['name'] as String?,
        releaseDefinitionId: json['releaseDefinition']?['id'] as int? ?? 
                             json['definition']?['id'] as int?,
        projectName: json['projectReference']?['name'] as String? ?? 
                     json['project']?['name'] as String?,
        createdOn: json['createdOn'] != null 
            ? DateTime.tryParse(json['createdOn'] as String)
            : null,
        modifiedOn: json['modifiedOn'] != null 
            ? DateTime.tryParse(json['modifiedOn'] as String)
            : null,
        createdBy: json['createdBy']?['displayName'] as String? ?? 
                   json['createdBy'] as String?,
        url: json['url'] as String?,
        environments: json['environments'] != null
            ? (json['environments'] as List)
                .map((e) => ReleaseEnvironment.fromJson(e))
                .toList()
            : [],
        approvals: json['environments'] != null
            ? (json['environments'] as List)
                .expand((env) {
                  final approvals = env['preDeployApprovals'] as List? ?? [];
                  final postApprovals = env['postDeployApprovals'] as List? ?? [];
                  return [
                    ...approvals.map((a) => ReleaseApproval.fromJson(a, env['name'] as String? ?? '')),
                    ...postApprovals.map((a) => ReleaseApproval.fromJson(a, env['name'] as String? ?? '')),
                  ];
                })
                .toList()
            : [],
      );
      
      debugPrint('✅ [Release.fromJson] Successfully parsed: ${release.name}');
      return release;
    } catch (e, stackTrace) {
      debugPrint('❌ [Release.fromJson] Error parsing release: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('❌ [Release.fromJson] JSON: $json');
      rethrow;
    }
  }
}

/// Release Environment model
class ReleaseEnvironment {
  final int id;
  final String name;
  final String? status;
  final DateTime? createdOn;
  final DateTime? modifiedOn;

  ReleaseEnvironment({
    required this.id,
    required this.name,
    this.status,
    this.createdOn,
    this.modifiedOn,
  });

  factory ReleaseEnvironment.fromJson(Map<String, dynamic> json) {
    return ReleaseEnvironment(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String?,
      createdOn: json['createdOn'] != null 
          ? DateTime.tryParse(json['createdOn'] as String)
          : null,
      modifiedOn: json['modifiedOn'] != null 
          ? DateTime.tryParse(json['modifiedOn'] as String)
          : null,
    );
  }
}

/// Release Approval model
class ReleaseApproval {
  final int id;
  final String? status; // pending, approved, rejected
  final String? approver;
  final String? environmentName;
  final DateTime? createdOn;
  final String? comment;

  ReleaseApproval({
    required this.id,
    this.status,
    this.approver,
    required this.environmentName,
    this.createdOn,
    this.comment,
  });

  factory ReleaseApproval.fromJson(Map<String, dynamic> json, String environmentName) {
    return ReleaseApproval(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String?,
      approver: json['approver']?['displayName'] as String?,
      environmentName: environmentName,
      createdOn: json['createdOn'] != null 
          ? DateTime.tryParse(json['createdOn'] as String)
          : null,
      comment: json['comments'] as String?,
    );
  }
}

/// Release servisi sınıfı
/// Azure DevOps API ile release işlemlerini yönetir
class ReleaseService {
  final Dio _dio = CertificatePinningService.createSecureDio();
  
  Dio get dio => _dio;
  
  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }

  String encodeToken(String token) => _encodeToken(token);

  /// Check if URL is Azure DevOps Services (cloud)
  bool _isAzureDevOpsServices(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return host == 'dev.azure.com' || 
             host == 'vsrm.dev.azure.com' ||
             host.endsWith('.visualstudio.com') ||
             host == 'azure.com';
    } catch (e) {
      return false;
    }
  }

  /// Convert Azure DevOps Services URL to Release Management URL
  /// Release API uses vsrm.dev.azure.com instead of dev.azure.com
  String _getReleaseApiUrl(String baseUrl, bool isCloud) {
    if (!isCloud) {
      return baseUrl;
    }
    
    try {
      final uri = Uri.parse(baseUrl);
      final host = uri.host.toLowerCase();
      
      // If it's dev.azure.com, convert to vsrm.dev.azure.com
      if (host == 'dev.azure.com') {
        return baseUrl.replaceFirst('dev.azure.com', 'vsrm.dev.azure.com');
      }
      
      // If it's visualstudio.com, keep as is (it uses the same host)
      // If it's already vsrm.dev.azure.com, return as is
      return baseUrl;
    } catch (e) {
      debugPrint('⚠️ [ReleaseService] Error parsing URL: $e');
      return baseUrl;
    }
  }

  /// Get releases user has access to
  Future<List<Release>> getReleases({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
    int? top,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      // For Azure DevOps Services (cloud), don't use collection in URL
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      List<Release> allReleases = [];

      // If project is specified, get releases for that project
      if (project != null && project.isNotEmpty) {
        final topParam = top != null ? '&\$top=$top' : '&\$top=50';
        
        // Try different API versions for Azure DevOps Services
        // Version 6.0 is more widely supported for Release API
        final apiVersion = isCloud ? '6.0' : '7.0';
        final url = '$baseUrl/$project/_apis/release/releases?api-version=$apiVersion$topParam';
        
        debugPrint('🔍 [ReleaseService] Getting releases for project: $project');
        debugPrint('🔍 [ReleaseService] Is cloud: $isCloud');
        debugPrint('🔍 [ReleaseService] Collection: $collection');
        debugPrint('🔍 [ReleaseService] API version: $apiVersion');
        debugPrint('🔍 [ReleaseService] URL: $url');
        
        try {
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

          debugPrint('📦 [ReleaseService] Response status: ${response.statusCode}');
          debugPrint('📦 [ReleaseService] Response headers: ${response.headers}');

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            debugPrint('📦 [ReleaseService] Response data keys: ${data.keys.toList()}');
            
            if (data['value'] != null) {
              final releasesList = data['value'] as List;
              debugPrint('📦 [ReleaseService] Found ${releasesList.length} releases');
              
              final releases = releasesList
                  .map((json) {
                    debugPrint('📋 [ReleaseService] Parsing release: ${json['id']} - ${json['name']}');
                    return Release.fromJson(json);
                  })
                  .toList();
              allReleases.addAll(releases);
              debugPrint('✅ [ReleaseService] Successfully parsed ${releases.length} releases');
            } else {
              debugPrint('⚠️ [ReleaseService] No "value" key in response');
              debugPrint('⚠️ [ReleaseService] Response data: ${response.data}');
            }
          } else if (response.statusCode == 401) {
            debugPrint('❌ [ReleaseService] Unauthorized (401) - Token may be invalid or missing permissions');
            debugPrint('❌ [ReleaseService] Response data: ${response.data}');
            debugPrint('❌ [ReleaseService] Response headers: ${response.headers}');
            // Try to get more info from response
            if (response.data != null) {
              try {
                final errorData = response.data;
                debugPrint('❌ [ReleaseService] Error details: $errorData');
              } catch (e) {
                debugPrint('❌ [ReleaseService] Could not parse error response: $e');
              }
            }
          } else if (response.statusCode == 404) {
            debugPrint('⚠️ [ReleaseService] Release API not found (404) - Release feature may not be enabled on this server');
          } else {
            debugPrint('⚠️ [ReleaseService] Failed to get releases: ${response.statusCode}');
            if (response.data != null) {
              debugPrint('⚠️ [ReleaseService] Error response: ${response.data}');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [ReleaseService] Error getting releases for project $project: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        // Get all projects first, then get releases for each
        // Note: Projects API uses original URL, not vsrm subdomain
        final originalCleanUrl = serverUrl.endsWith('/') 
            ? serverUrl.substring(0, serverUrl.length - 1) 
            : serverUrl;
        final originalBaseUrl = (!isCloud && collection != null && collection.isNotEmpty)
            ? '$originalCleanUrl/$collection'
            : originalCleanUrl;
            
        try {
          final projectsUrl = '$originalBaseUrl/_apis/projects?api-version=7.0';
          final projectsResponse = await _dio.get(
            projectsUrl,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeToken(token)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          if (projectsResponse.statusCode == 200 && projectsResponse.data != null) {
            final projects = projectsResponse.data['value'] as List?;
            if (projects != null) {
              for (final projectData in projects) {
                final projectName = projectData['name'] as String?;
                if (projectName != null && projectName.isNotEmpty) {
                  try {
                    final topParam = top != null ? '&\$top=$top' : '&\$top=10';
                    final apiVersion = isCloud ? '6.0' : '7.0';
                    final releasesUrl = '$baseUrl/$projectName/_apis/release/releases?api-version=$apiVersion$topParam';
                    final releasesResponse = await _dio.get(
                      releasesUrl,
                      options: Options(
                        headers: {
                          'Authorization': 'Basic ${_encodeToken(token)}',
                          'Content-Type': 'application/json',
                        },
                        validateStatus: (status) => status! < 500,
                      ),
                    );

                    if (releasesResponse.statusCode == 200 && releasesResponse.data != null) {
                      final data = releasesResponse.data;
                      if (data['value'] != null) {
                        final releases = (data['value'] as List)
                            .map((json) => Release.fromJson(json))
                            .toList();
                        allReleases.addAll(releases);
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ [ReleaseService] Error getting releases for project $projectName: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ReleaseService] Error getting projects: $e');
        }
      }

      // Sort by created date (newest first)
      allReleases.sort((a, b) {
        final aTime = a.createdOn ?? DateTime(1970);
        final bTime = b.createdOn ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return allReleases;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Get releases error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Approve a release approval
  Future<bool> approveRelease({
    required String serverUrl,
    required String token,
    required int releaseId,
    required int approvalId,
    required String project,
    String? comment,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/approvals/$approvalId?api-version=$apiVersion';
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'approved',
          if (comment != null && comment.isNotEmpty) 'comments': comment,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Approve release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Reject a release approval
  Future<bool> rejectRelease({
    required String serverUrl,
    required String token,
    required int releaseId,
    required int approvalId,
    required String project,
    String? comment,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/approvals/$approvalId?api-version=$apiVersion';
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'rejected',
          if (comment != null && comment.isNotEmpty) 'comments': comment,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Reject release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get release detail
  Future<Release?> getReleaseDetail({
    required String serverUrl,
    required String token,
    required String project,
    required int releaseId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases/$releaseId?api-version=$apiVersion';
      
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

      if (response.statusCode == 200 && response.data != null) {
        return Release.fromJson(response.data);
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Get release detail error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Create a new release
  Future<Release?> createRelease({
    required String serverUrl,
    required String token,
    required String project,
    required int definitionId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases?api-version=$apiVersion';
      
      final response = await _dio.post(
        url,
        data: {
          'definitionId': definitionId,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return Release.fromJson(response.data);
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Create release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Abandon a release
  Future<bool> abandonRelease({
    required String serverUrl,
    required String token,
    required String project,
    required int releaseId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases/$releaseId?api-version=$apiVersion';
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'abandoned',
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Abandon release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Deploy a release to an environment
  Future<bool> deployRelease({
    required String serverUrl,
    required String token,
    required String project,
    required int releaseId,
    required int environmentId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases/$releaseId/environments/$environmentId?api-version=$apiVersion';
      
      debugPrint('🚀 [ReleaseService] Deploying release $releaseId to environment $environmentId');
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'inProgress',
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('📦 [ReleaseService] Deploy release response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Deploy release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Cancel/Stop a release deployment
  Future<bool> cancelRelease({
    required String serverUrl,
    required String token,
    required String project,
    required int releaseId,
    required int environmentId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases/$releaseId/environments/$environmentId?api-version=$apiVersion';
      
      debugPrint('🛑 [ReleaseService] Canceling release $releaseId environment $environmentId');
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'canceled',
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('📦 [ReleaseService] Cancel release response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Cancel release error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get release definitions for a project
  Future<List<Map<String, dynamic>>> getReleaseDefinitions({
    required String serverUrl,
    required String token,
    required String project,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // For Azure DevOps Services, use vsrm.dev.azure.com for Release API
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/definitions?api-version=$apiVersion';
      
      debugPrint('🔍 [ReleaseService] Getting release definitions for project: $project');
      
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

      if (response.statusCode == 200 && response.data != null) {
        final definitions = (response.data['value'] as List)
            .map((def) => {
              'id': def['id'],
              'name': def['name'],
            })
            .toList();
        return definitions;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Get release definitions error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get releases for a specific release definition
  Future<List<Release>> getReleasesByDefinition({
    required String serverUrl,
    required String token,
    required String project,
    required int definitionId,
    String? collection,
    int? top,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final topParam = top != null ? '&\$top=$top' : '&\$top=50';
      final apiVersion = isCloud ? '6.0' : '7.0';
      final url = '$baseUrl/$project/_apis/release/releases?definitionId=$definitionId&api-version=$apiVersion$topParam';
      
      debugPrint('🔍 [ReleaseService] Getting releases for definition: $definitionId');
      
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

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['value'] != null) {
          return (data['value'] as List)
              .map((json) => Release.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Get releases by definition error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get release logs for an environment
  Future<String?> getReleaseLogs({
    required String serverUrl,
    required String token,
    required String project,
    required int releaseId,
    required int environmentId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final isCloud = _isAzureDevOpsServices(cleanUrl);
      var baseUrl = (!isCloud && collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      baseUrl = _getReleaseApiUrl(baseUrl, isCloud);

      final apiVersion = isCloud ? '6.0' : '7.0';
      // Try to get logs from environment deployment
      final url = '$baseUrl/$project/_apis/release/releases/$releaseId/environments/$environmentId/logs?api-version=$apiVersion';
      
      debugPrint('🔍 [ReleaseService] Getting logs for release $releaseId environment $environmentId');
      
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

      if (response.statusCode == 200 && response.data != null) {
        // Logs can be in different formats, try to get as string
        if (response.data is String) {
          return response.data as String;
        } else if (response.data is Map) {
          // If it's a JSON structure, try to extract log content
          return response.data.toString();
        }
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleaseService] Get release logs error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}

