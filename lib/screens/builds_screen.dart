/// Builds ekranı
/// 
/// Azure DevOps build'lerini listeler ve görüntüler.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/build_service.dart';
import 'build_detail_screen.dart';
import '../l10n/app_localizations.dart';

class BuildsScreen extends StatefulWidget {
  const BuildsScreen({super.key});

  @override
  State<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends State<BuildsScreen> {
  final BuildService _buildService = BuildService();
  List<Map<String, dynamic>> _projects = [];
  List<Build> _builds = [];
  String? _selectedProject;
  bool _isLoadingProjects = true;
  bool _isLoadingBuilds = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _error = 'Not authenticated';
          _isLoadingProjects = false;
        });
        return;
      }

      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final baseUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection'
          : cleanUrl;

      final url = '$baseUrl/_apis/projects?api-version=7.0';
      
      final dio = _buildService.dio;
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_buildService.encodeToken(token!)}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final projects = (response.data['value'] as List)
            .map((p) => {
              'id': p['id'],
              'name': p['name'],
            })
            .toList();
        
        setState(() {
          _projects = projects;
          _isLoadingProjects = false;
        });
      } else {
        setState(() {
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _loadBuilds(String project) async {
    setState(() {
      _isLoadingBuilds = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _error = 'Not authenticated';
          _isLoadingBuilds = false;
        });
        return;
      }

      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final builds = await _buildService.getBuilds(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: project,
        top: 50,
      );

      debugPrint('📦 [BuildsScreen] Received ${builds.length} builds');

      setState(() {
        _builds = builds;
        _isLoadingBuilds = false;
        if (builds.isEmpty) {
          _error = 'No builds found for this project';
        } else {
          _error = null;
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildsScreen] Error loading builds: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoadingBuilds = false;
      });
    }
  }

  Color _getStatusColor(String? status, String? result) {
    if (result == 'succeeded') return Colors.green;
    if (result == 'failed') return Colors.red;
    if (result == 'canceled') return Colors.grey;
    if (status == 'inProgress') return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(String? status, String? result) {
    if (result == 'succeeded') return Icons.check_circle;
    if (result == 'failed') return Icons.error;
    if (result == 'canceled') return Icons.cancel;
    if (status == 'inProgress') return Icons.hourglass_empty;
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Builds'),
        actions: [
          if (_selectedProject != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadBuilds(_selectedProject!),
              tooltip: 'Yenile',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProjects,
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: _isLoadingProjects
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: $_error',
                        style: TextStyle(color: Colors.red.shade300),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProjects,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _selectedProject == null
                  ? ListView.builder(
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(Icons.folder, color: Colors.orange),
                            ),
                            title: Text(
                              project['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              setState(() {
                                _selectedProject = project['name'] as String;
                                _builds = [];
                              });
                              _loadBuilds(project['name'] as String);
                            },
                          ),
                        );
                      },
                    )
                  : Column(
                      children: [
                        // Project header with back button
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.blue.shade50,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  setState(() {
                                    _selectedProject = null;
                                    _builds = [];
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => _loadBuilds(_selectedProject!),
                                tooltip: 'Yenile',
                              ),
                              Expanded(
                                child: Text(
                                  'Project: $_selectedProject',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Builds list
                        Expanded(
                          child: _isLoadingBuilds
                              ? const Center(child: CircularProgressIndicator())
                                  : _builds.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.build_outlined, size: 64, color: Colors.grey.shade400),
                                              const SizedBox(height: 16),
                                              Text(
                                                _error ?? 'Build bulunamadı',
                                                style: TextStyle(color: Colors.grey.shade600),
                                                textAlign: TextAlign.center,
                                              ),
                                              if (_error == null) ...[
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: () => _loadBuilds(_selectedProject!),
                                                  child: const Text('Yenile'),
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                  : RefreshIndicator(
                                      onRefresh: () => _loadBuilds(_selectedProject!),
                                      child: ListView.builder(
                                        itemCount: _builds.length,
                                        itemBuilder: (context, index) {
                                          final build = _builds[index];
                                          final statusColor = _getStatusColor(build.status, build.result);
                                          final statusIcon = _getStatusIcon(build.status, build.result);
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: statusColor.withOpacity(0.2),
                                                child: Icon(statusIcon, color: statusColor),
                                              ),
                                              title: Text(
                                                build.buildNumber,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (build.definitionName != null)
                                                    Text('Definition: ${build.definitionName}'),
                                                  if (build.queueTime != null)
                                                    Text('Queue: ${dateFormat.format(build.queueTime!)}'),
                                                  if (build.result != null)
                                                    Text(
                                                      'Result: ${build.result}',
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              trailing: const Icon(Icons.chevron_right),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => BuildDetailScreen(
                                                      build: build,
                                                      project: _selectedProject!,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ],
                    ),
    );
  }
}

