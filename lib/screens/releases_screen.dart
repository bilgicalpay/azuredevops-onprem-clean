/// Releases ekranı
/// 
/// Azure DevOps release'lerini listeler, görüntüler ve approval işlemlerini yönetir.
/// Release Definitions'ları gösterir, her definition altında release'leri listeler.
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
import '../services/release_service.dart';
import 'release_detail_screen.dart';

class ReleasesScreen extends StatefulWidget {
  const ReleasesScreen({super.key});

  @override
  State<ReleasesScreen> createState() => _ReleasesScreenState();
}

class _ReleasesScreenState extends State<ReleasesScreen> {
  final ReleaseService _releaseService = ReleaseService();
  List<Map<String, dynamic>> _projects = [];
  Map<int, List<Release>> _releasesByDefinition = {}; // definitionId -> releases
  Map<int, bool> _expandedDefinitions = {}; // definitionId -> isExpanded
  Map<int, bool> _loadingDefinitions = {}; // definitionId -> isLoading
  String? _selectedProject;
  List<Map<String, dynamic>> _definitions = [];
  bool _isLoadingProjects = true;
  bool _isLoadingDefinitions = false;
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
      
      final dio = _releaseService.dio;
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_releaseService.encodeToken(token!)}',
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

  Future<void> _loadDefinitions(String project) async {
    setState(() {
      _isLoadingDefinitions = true;
      _error = null;
      _definitions = [];
      _releasesByDefinition = {};
      _expandedDefinitions = {};
      _loadingDefinitions = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _error = 'Not authenticated';
          _isLoadingDefinitions = false;
        });
        return;
      }

      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final definitions = await _releaseService.getReleaseDefinitions(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: project,
      );

      debugPrint('📦 [ReleasesScreen] Received ${definitions.length} definitions');

      setState(() {
        _definitions = definitions;
        _isLoadingDefinitions = false;
        if (definitions.isEmpty) {
          _error = 'No release definitions found for this project';
        } else {
          _error = null;
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleasesScreen] Error loading definitions: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoadingDefinitions = false;
      });
    }
  }

  Future<void> _loadReleasesForDefinition(String project, int definitionId) async {
    if (_loadingDefinitions[definitionId] == true) return;

    setState(() {
      _loadingDefinitions[definitionId] = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final releases = await _releaseService.getReleasesByDefinition(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: project,
        definitionId: definitionId,
        top: 50,
      );

      debugPrint('📦 [ReleasesScreen] Received ${releases.length} releases for definition $definitionId');

      setState(() {
        _releasesByDefinition[definitionId] = releases;
        _loadingDefinitions[definitionId] = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [ReleasesScreen] Error loading releases for definition $definitionId: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _loadingDefinitions[definitionId] = false;
      });
    }
  }

  Future<void> _createNewRelease(int definitionId, String definitionName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Release'),
        content: Text('$definitionName için yeni bir release oluşturmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final newRelease = await _releaseService.createRelease(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: _selectedProject!,
        definitionId: definitionId,
      );

      if (newRelease != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Release başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload releases for this definition
        _loadReleasesForDefinition(_selectedProject!, definitionId);
        // Navigate to the new release
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReleaseDetailScreen(
              release: newRelease,
              project: _selectedProject!,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Release oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'succeeded':
      case 'active':
        return Colors.green;
      case 'failed':
      case 'rejected':
        return Colors.red;
      case 'canceled':
      case 'abandoned':
        return Colors.grey;
      case 'inprogress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Releases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedProject != null 
                ? () => _loadDefinitions(_selectedProject!)
                : _loadProjects,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoadingProjects
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _selectedProject == null
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
                              backgroundColor: Colors.purple.shade100,
                              child: const Icon(Icons.folder, color: Colors.purple),
                            ),
                            title: Text(
                              project['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              setState(() {
                                _selectedProject = project['name'] as String;
                              });
                              _loadDefinitions(project['name'] as String);
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
                          color: Colors.purple.shade50,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  setState(() {
                                    _selectedProject = null;
                                    _definitions = [];
                                    _releasesByDefinition = {};
                                    _expandedDefinitions = {};
                                  });
                                },
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
                        // Definitions list
                        Expanded(
                          child: _isLoadingDefinitions
                              ? const Center(child: CircularProgressIndicator())
                                  : _definitions.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade400),
                                              const SizedBox(height: 16),
                                              Text(
                                                _error ?? 'Release definition bulunamadı',
                                                style: TextStyle(color: Colors.grey.shade600),
                                                textAlign: TextAlign.center,
                                              ),
                                              if (_error == null) ...[
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: () => _loadDefinitions(_selectedProject!),
                                                  child: const Text('Yenile'),
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                  : RefreshIndicator(
                                      onRefresh: () => _loadDefinitions(_selectedProject!),
                                      child: ListView.builder(
                                        itemCount: _definitions.length,
                                        itemBuilder: (context, index) {
                                          final definition = _definitions[index];
                                          final definitionId = definition['id'] as int;
                                          final definitionName = definition['name'] as String;
                                          final isExpanded = _expandedDefinitions[definitionId] ?? false;
                                          final releases = _releasesByDefinition[definitionId] ?? [];
                                          final isLoading = _loadingDefinitions[definitionId] ?? false;

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            child: ExpansionTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.purple.shade100,
                                                child: const Icon(Icons.folder, color: Colors.purple),
                                              ),
                                              title: Text(
                                                definitionName,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Text('${releases.length} release(s)'),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isExpanded && !isLoading)
                                                    IconButton(
                                                      icon: const Icon(Icons.add),
                                                      onPressed: () => _createNewRelease(definitionId, definitionName),
                                                      tooltip: 'Create New Release',
                                                      color: Colors.green,
                                                    ),
                                                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                                ],
                                              ),
                                              onExpansionChanged: (expanded) {
                                                setState(() {
                                                  _expandedDefinitions[definitionId] = expanded;
                                                });
                                                if (expanded && releases.isEmpty && !isLoading) {
                                                  _loadReleasesForDefinition(_selectedProject!, definitionId);
                                                }
                                              },
                                              children: [
                                                if (isLoading)
                                                  const Padding(
                                                    padding: EdgeInsets.all(16.0),
                                                    child: Center(child: CircularProgressIndicator()),
                                                  )
                                                else if (releases.isEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: Center(
                                                      child: Column(
                                                        children: [
                                                          Icon(Icons.rocket_launch_outlined, 
                                                            size: 48, 
                                                            color: Colors.grey.shade400,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'No releases found',
                                                            style: TextStyle(color: Colors.grey.shade600),
                                                          ),
                                                          const SizedBox(height: 16),
                                                          ElevatedButton.icon(
                                                            onPressed: () => _createNewRelease(definitionId, definitionName),
                                                            icon: const Icon(Icons.add),
                                                            label: const Text('Create New Release'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  ...releases.map((release) {
                                                    final statusColor = _getStatusColor(release.status);
                                                    final pendingApprovals = release.approvals
                                                        .where((a) => a.status?.toLowerCase() == 'pending')
                                                        .toList();
                                                    
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                      child: Card(
                                                        color: Colors.grey.shade50,
                                                        margin: const EdgeInsets.only(bottom: 8.0),
                                                        child: ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor: statusColor.withOpacity(0.2),
                                                            child: Icon(Icons.rocket_launch, color: statusColor, size: 20),
                                                          ),
                                                          title: Text(
                                                            release.name,
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              if (release.createdOn != null)
                                                                Text('Created: ${dateFormat.format(release.createdOn!)}'),
                                                              if (release.status != null)
                                                                Text(
                                                                  'Status: ${release.status}',
                                                                  style: TextStyle(
                                                                    color: statusColor,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              if (pendingApprovals.isNotEmpty)
                                                                Container(
                                                                  margin: const EdgeInsets.only(top: 4),
                                                                  padding: const EdgeInsets.all(4),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.orange.shade50,
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    border: Border.all(color: Colors.orange.shade200),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.pending_actions, 
                                                                        color: Colors.orange.shade700, 
                                                                        size: 16,
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        '${pendingApprovals.length} pending',
                                                                        style: TextStyle(
                                                                          color: Colors.orange.shade700,
                                                                          fontSize: 12,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          trailing: const Icon(Icons.chevron_right, size: 20),
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => ReleaseDetailScreen(
                                                                  release: release,
                                                                  project: _selectedProject!,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                              ],
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
