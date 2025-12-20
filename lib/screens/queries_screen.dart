/// Query ekranı
/// 
/// Kullanıcının kayıtlı query'lerini listeler ve çalıştırır.
/// My Queries, Shared Queries ve Favorites kategorilerinde query'leri gösterir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import 'work_item_list_screen.dart';

/// Query ekranı widget'ı
/// Kayıtlı query'leri listeler ve çalıştırır
class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  final WorkItemService _workItemService = WorkItemService();
  Map<String, List<SavedQuery>> _queriesGrouped = {
    'My Queries': [],
    'Shared Queries': [],
    'Favorites': [],
  };
  bool _isLoading = true;
  String? _currentProject; // Store project for executeQuery

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    debugPrint('🔄 [UI] Loading queries...');
    debugPrint('🔄 [UI] Server URL: ${authService.serverUrl}');
    debugPrint('🔄 [UI] Collection: ${storage.getCollection()}');

    // Get project from first work item if available
    String? project;
    try {
      final workItems = await _workItemService.getWorkItems(
        serverUrl: authService.serverUrl!,
        token: await authService.getAuthToken() ?? '',
        collection: storage.getCollection(),
      );
      if (workItems.isNotEmpty) {
        project = workItems.first.project;
        debugPrint('🔄 [UI] Using project: $project for queries');
      }
    } catch (e) {
      debugPrint('⚠️ [UI] Could not get project: $e');
    }
    
    // Store project for later use in executeQuery
    _currentProject = project;

    final queriesGrouped = await _workItemService.getSavedQueriesGrouped(
      serverUrl: authService.serverUrl!,
      token: authService.token!,
      collection: storage.getCollection(),
      project: project,
    );

    debugPrint('✅ [UI] Loaded queries - My: ${queriesGrouped['My Queries']?.length ?? 0}, Shared: ${queriesGrouped['Shared Queries']?.length ?? 0}, Favorites: ${queriesGrouped['Favorites']?.length ?? 0}');

    setState(() {
      _queriesGrouped = queriesGrouped;
      _isLoading = false;
    });
  }

  Future<void> _executeQuery(SavedQuery query) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // If query doesn't have WIQL, fetch it from URL
    String? wiql = query.wiql;
    if (wiql.isEmpty && query.url != null && query.url!.isNotEmpty) {
      debugPrint('🔄 [UI] Fetching WIQL from URL: ${query.url}');
      wiql = await _workItemService.fetchQueryWiql(
        queryUrl: query.url!,
        token: await authService.getAuthToken() ?? '',
        serverUrl: authService.serverUrl!,
      );
      
      if (wiql == null || wiql.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Query WIQL alınamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (wiql.isEmpty) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu query için WIQL bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final workItems = await _workItemService.executeQuery(
      serverUrl: authService.serverUrl!,
      token: authService.token!,
      wiql: wiql,
      collection: storage.getCollection(),
      username: authService.username, // Pass username to replace @me
      project: _currentProject, // Pass project to replace @project
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkItemListScreen(
          workItems: workItems,
          title: query.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueries,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queriesGrouped.values.every((list) => list.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Query bulunamadı',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Azure DevOps\'ta kaydedilmiş query\'leriniz burada görünecek',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQueries,
                  child: ListView(
                    children: [
                      // My Queries
                      if (_queriesGrouped['My Queries']?.isNotEmpty ?? false)
                        ExpansionTile(
                          leading: const Icon(Icons.person),
                          title: Text('My Queries (${_queriesGrouped['My Queries']?.length ?? 0})'),
                          initiallyExpanded: true,
                          children: _queriesGrouped['My Queries']!
                              .map((query) => ListTile(
                                    leading: const Icon(Icons.query_stats, size: 20),
                                    title: Text(query.name),
                                    subtitle: query.path != null
                                        ? Text(
                                            query.path!,
                                            style: const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _executeQuery(query),
                                  ))
                              .toList(),
                        ),
                      // Shared Queries
                      if (_queriesGrouped['Shared Queries']?.isNotEmpty ?? false)
                        ExpansionTile(
                          leading: const Icon(Icons.folder_shared),
                          title: Text('Shared Queries (${_queriesGrouped['Shared Queries']?.length ?? 0})'),
                          children: _queriesGrouped['Shared Queries']!
                              .map((query) => ListTile(
                                    leading: const Icon(Icons.query_stats, size: 20),
                                    title: Text(query.name),
                                    subtitle: query.path != null
                                        ? Text(
                                            query.path!,
                                            style: const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _executeQuery(query),
                                  ))
                              .toList(),
                        ),
                      // Favorites
                      if (_queriesGrouped['Favorites']?.isNotEmpty ?? false)
                        ExpansionTile(
                          leading: const Icon(Icons.star),
                          title: Text('Favorites (${_queriesGrouped['Favorites']?.length ?? 0})'),
                          children: _queriesGrouped['Favorites']!
                              .map((query) => ListTile(
                                    leading: const Icon(Icons.query_stats, size: 20),
                                    title: Text(query.name),
                                    subtitle: query.path != null
                                        ? Text(
                                            query.path!,
                                            style: const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _executeQuery(query),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
    );
  }
}

