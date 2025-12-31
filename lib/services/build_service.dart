/// Build servisi
/// 
/// AzureDevOps API'si ile build'leri yönetir.
/// Build listeleme ve detay görüntüleme işlemlerini gerçekleştirir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';

/// Build model
class Build {
  final int id;
  final String buildNumber;
  final String? status;
  final String? result;
  final String? definitionName;
  final int? definitionId;
  final String? projectName;
  final DateTime? queueTime;
  final DateTime? startTime;
  final DateTime? finishTime;
  final String? requestedBy;
  final String? url;

  Build({
    required this.id,
    required this.buildNumber,
    this.status,
    this.result,
    this.definitionName,
    this.definitionId,
    this.projectName,
    this.queueTime,
    this.startTime,
    this.finishTime,
    this.requestedBy,
    this.url,
  });

  factory Build.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('📋 [Build.fromJson] Parsing build JSON: ${json.keys.toList()}');
      debugPrint('📋 [Build.fromJson] ID: ${json['id']}, BuildNumber: ${json['buildNumber']}');
      
      final build = Build(
        id: json['id'] as int? ?? 0,
        buildNumber: json['buildNumber'] as String? ?? json['name'] as String? ?? '',
        status: json['status'] as String?,
        result: json['result'] as String?,
        definitionName: json['definition']?['name'] as String? ?? json['definitionName'] as String?,
        definitionId: json['definition']?['id'] as int? ?? json['definitionId'] as int?,
        projectName: json['project']?['name'] as String? ?? json['projectName'] as String?,
        queueTime: json['queueTime'] != null 
            ? DateTime.tryParse(json['queueTime'] as String)
            : null,
        startTime: json['startTime'] != null 
            ? DateTime.tryParse(json['startTime'] as String)
            : null,
        finishTime: json['finishTime'] != null 
            ? DateTime.tryParse(json['finishTime'] as String)
            : null,
        requestedBy: json['requestedBy']?['displayName'] as String? ?? json['requestedBy'] as String?,
        url: json['url'] as String?,
      );
      
      debugPrint('✅ [Build.fromJson] Successfully parsed: ${build.buildNumber}');
      return build;
    } catch (e, stackTrace) {
      debugPrint('❌ [Build.fromJson] Error parsing build: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('❌ [Build.fromJson] JSON: $json');
      rethrow;
    }
  }
}

/// Build servisi sınıfı
/// Azure DevOps API ile build işlemlerini yönetir
class BuildService {
  final Dio _dio = CertificatePinningService.createSecureDio();
  
  Dio get dio => _dio;
  
  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }

  String encodeToken(String token) => _encodeToken(token);

  /// Get builds user has access to
  Future<List<Build>> getBuilds({
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
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      List<Build> allBuilds = [];

      // If project is specified, get builds for that project
      if (project != null && project.isNotEmpty) {
        final topParam = top != null ? '&\$top=$top' : '&\$top=50';
        final url = '$baseUrl/$project/_apis/build/builds?api-version=7.0$topParam';
        
        debugPrint('🔍 [BuildService] Getting builds for project: $project');
        debugPrint('🔍 [BuildService] URL: $url');
        
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

          debugPrint('📦 [BuildService] Response status: ${response.statusCode}');

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            debugPrint('📦 [BuildService] Response data keys: ${data.keys.toList()}');
            
            if (data['value'] != null) {
              final buildsList = data['value'] as List;
              debugPrint('📦 [BuildService] Found ${buildsList.length} builds');
              
              final builds = buildsList
                  .map((json) {
                    debugPrint('📋 [BuildService] Parsing build: ${json['id']} - ${json['buildNumber']}');
                    return Build.fromJson(json);
                  })
                  .toList();
              allBuilds.addAll(builds);
              debugPrint('✅ [BuildService] Successfully parsed ${builds.length} builds');
            } else {
              debugPrint('⚠️ [BuildService] No "value" key in response');
            }
          } else {
            debugPrint('⚠️ [BuildService] Failed to get builds: ${response.statusCode}');
            if (response.data != null) {
              debugPrint('⚠️ [BuildService] Error response: ${response.data}');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [BuildService] Error getting builds for project $project: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        // Get all projects first, then get builds for each
        try {
          final projectsUrl = '$baseUrl/_apis/projects?api-version=7.0';
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
                    final buildsUrl = '$baseUrl/$projectName/_apis/build/builds?api-version=7.0$topParam';
                    final buildsResponse = await _dio.get(
                      buildsUrl,
                      options: Options(
                        headers: {
                          'Authorization': 'Basic ${_encodeToken(token)}',
                          'Content-Type': 'application/json',
                        },
                        validateStatus: (status) => status! < 500,
                      ),
                    );

                    if (buildsResponse.statusCode == 200 && buildsResponse.data != null) {
                      final data = buildsResponse.data;
                      if (data['value'] != null) {
                        final builds = (data['value'] as List)
                            .map((json) => Build.fromJson(json))
                            .toList();
                        allBuilds.addAll(builds);
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ [BuildService] Error getting builds for project $projectName: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [BuildService] Error getting projects: $e');
        }
      }

      // Sort by queue time (newest first)
      allBuilds.sort((a, b) {
        final aTime = a.queueTime ?? DateTime(1970);
        final bTime = b.queueTime ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return allBuilds;
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Get builds error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get build detail
  Future<Build?> getBuildDetail({
    required String serverUrl,
    required String token,
    required String project,
    required int buildId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/build/builds/$buildId?api-version=7.0';
      
      debugPrint('🔍 [BuildService] Getting build detail: $url');
      
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

      debugPrint('📦 [BuildService] Build detail response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ [BuildService] Build detail data received');
        debugPrint('📋 [BuildService] Build data keys: ${response.data.keys.toList()}');
        final build = Build.fromJson(response.data);
        debugPrint('✅ [BuildService] Build parsed: ${build.buildNumber}');
        return build;
      } else {
        debugPrint('⚠️ [BuildService] Build detail failed: ${response.statusCode}');
        if (response.data != null) {
          debugPrint('⚠️ [BuildService] Error response: ${response.data}');
        }
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Get build detail error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Queue a new build
  Future<Build?> queueBuild({
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
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/build/builds?api-version=7.0';
      
      debugPrint('🔍 [BuildService] Queueing build for definition: $definitionId');
      
      final response = await _dio.post(
        url,
        data: {
          'definition': {'id': definitionId},
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('📦 [BuildService] Queue build response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return Build.fromJson(response.data);
        }
        return null;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Queue build error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Cancel a build
  Future<bool> cancelBuild({
    required String serverUrl,
    required String token,
    required String project,
    required int buildId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/build/builds/$buildId?api-version=7.0';
      
      final response = await _dio.patch(
        url,
        data: {
          'status': 'cancelling',
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
      debugPrint('❌ [BuildService] Cancel build error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get build definitions for a project
  Future<List<Map<String, dynamic>>> getBuildDefinitions({
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

      final url = '$baseUrl/$project/_apis/build/definitions?api-version=7.0';
      
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
        return (response.data['value'] as List)
            .map((def) => {
              'id': def['id'],
              'name': def['name'],
            })
            .toList();
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Get build definitions error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get build timeline (stages and jobs)
  Future<Map<String, dynamic>?> getBuildTimeline({
    required String serverUrl,
    required String token,
    required String project,
    required int buildId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/build/builds/$buildId/timeline?api-version=7.0';
      
      debugPrint('🔍 [BuildService] Getting build timeline: $url');
      
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

      debugPrint('📦 [BuildService] Timeline response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Get build timeline error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get build logs
  Future<String?> getBuildLog({
    required String serverUrl,
    required String token,
    required String project,
    required int buildId,
    required int logId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/$project/_apis/build/builds/$buildId/logs/$logId?api-version=7.0';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'text/plain',
          },
          validateStatus: (status) => status! < 500,
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {
        return response.data as String?;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildService] Get build log error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}

