/// Board servisi
/// 
/// AzureDevOps API'si ile board'ları yönetir.
/// Board listeleme ve detay görüntüleme işlemlerini gerçekleştirir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'certificate_pinning_service.dart';

/// Board model
class Board {
  final String id;
  final String name;
  final String? description;
  final String? url;
  final String? projectId;
  final String? projectName;

  Board({
    required this.id,
    required this.name,
    this.description,
    this.url,
    this.projectId,
    this.projectName,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      url: json['url'] as String?,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
    );
  }
}

/// Board servisi sınıfı
/// Azure DevOps API ile board işlemlerini yönetir
class BoardService {
  final Dio _dio = CertificatePinningService.createSecureDio();
  
  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }

  /// Get all boards for projects user has access to
  Future<List<Board>> getBoards({
    required String serverUrl,
    required String token,
    String? collection,
    String? project,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      List<Board> allBoards = [];

      // If project is specified, get boards for that project
      if (project != null && project.isNotEmpty) {
        final url = '$baseUrl/$project/_apis/work/boards?api-version=7.0';
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

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            if (data['value'] != null) {
              final boards = (data['value'] as List)
                  .map((json) => Board.fromJson(json))
                  .toList();
              allBoards.addAll(boards);
            }
          }
        } catch (e) {
          debugPrint('⚠️ [BoardService] Error getting boards for project $project: $e');
        }
      } else {
        // Get all projects first, then get boards for each
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
                    final boardsUrl = '$baseUrl/$projectName/_apis/work/boards?api-version=7.0';
                    final boardsResponse = await _dio.get(
                      boardsUrl,
                      options: Options(
                        headers: {
                          'Authorization': 'Basic ${_encodeToken(token)}',
                          'Content-Type': 'application/json',
                        },
                        validateStatus: (status) => status! < 500,
                      ),
                    );

                    if (boardsResponse.statusCode == 200 && boardsResponse.data != null) {
                      final data = boardsResponse.data;
                      if (data['value'] != null) {
                        final boards = (data['value'] as List)
                            .map((json) {
                              final board = Board.fromJson(json);
                              // Add project info
                              return Board(
                                id: board.id,
                                name: board.name,
                                description: board.description,
                                url: board.url,
                                projectId: projectData['id'] as String?,
                                projectName: projectName,
                              );
                            })
                            .toList();
                        allBoards.addAll(boards);
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ [BoardService] Error getting boards for project $projectName: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [BoardService] Error getting projects: $e');
        }
      }

      return allBoards;
    } catch (e, stackTrace) {
      debugPrint('❌ [BoardService] Get boards error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get work items from board backlog (Backlog Items, Epics, Features)
  Future<Map<String, List<Map<String, dynamic>>>> getBoardWorkItems({
    required String serverUrl,
    required String token,
    required String project,
    required String boardId,
    String? collection,
  }) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final result = <String, List<Map<String, dynamic>>>{
        'Backlog Items': [],
        'Epics': [],
        'Features': [],
      };

      // Get backlog items
      try {
        final backlogUrl = '$baseUrl/$project/_apis/work/boards/$boardId/workitems?api-version=7.0';
        final response = await _dio.get(
          backlogUrl,
          options: Options(
            headers: {
              'Authorization': 'Basic ${_encodeToken(token)}',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final workItems = response.data['value'] as List?;
          if (workItems != null) {
            for (final item in workItems) {
              final workItemType = item['workItemType'] as String?;
              if (workItemType != null) {
                if (workItemType.toLowerCase() == 'backlog item' || 
                    workItemType.toLowerCase() == 'product backlog item' ||
                    workItemType.toLowerCase() == 'user story') {
                  result['Backlog Items']!.add(item);
                } else if (workItemType.toLowerCase() == 'epic') {
                  result['Epics']!.add(item);
                } else if (workItemType.toLowerCase() == 'feature') {
                  result['Features']!.add(item);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [BoardService] Error getting board work items: $e');
      }

      // Alternative: Get from backlog API
      try {
        final backlogApiUrl = '$baseUrl/$project/_apis/work/backlogs?api-version=7.0';
        final backlogResponse = await _dio.get(
          backlogApiUrl,
          options: Options(
            headers: {
              'Authorization': 'Basic ${_encodeToken(token)}',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );

        if (backlogResponse.statusCode == 200 && backlogResponse.data != null) {
          final backlogs = backlogResponse.data['value'] as List?;
          if (backlogs != null) {
            for (final backlog in backlogs) {
              final backlogType = backlog['workItemType']?['name'] as String?;
              final backlogName = backlog['name'] as String?;
              
              if (backlogName != null) {
                // Get work items for this backlog
                try {
                  final workItemsUrl = '$baseUrl/$project/_apis/work/backlogs/$backlogName/workitems?api-version=7.0';
                  final workItemsResponse = await _dio.get(
                    workItemsUrl,
                    options: Options(
                      headers: {
                        'Authorization': 'Basic ${_encodeToken(token)}',
                        'Content-Type': 'application/json',
                      },
                      validateStatus: (status) => status! < 500,
                    ),
                  );

                  if (workItemsResponse.statusCode == 200 && workItemsResponse.data != null) {
                    final workItems = workItemsResponse.data['workItems'] as List?;
                    if (workItems != null) {
                      for (final item in workItems) {
                        final itemType = item['workItemType']?['name'] as String?;
                        if (itemType != null) {
                          if (itemType.toLowerCase() == 'backlog item' || 
                              itemType.toLowerCase() == 'product backlog item' ||
                              itemType.toLowerCase() == 'user story') {
                            result['Backlog Items']!.add(item);
                          } else if (itemType.toLowerCase() == 'epic') {
                            result['Epics']!.add(item);
                          } else if (itemType.toLowerCase() == 'feature') {
                            result['Features']!.add(item);
                          }
                        }
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('⚠️ [BoardService] Error getting work items for backlog $backlogName: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [BoardService] Error getting backlogs: $e');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [BoardService] Get board work items error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'Backlog Items': [],
        'Epics': [],
        'Features': [],
      };
    }
  }
}

