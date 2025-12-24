/// Project Work Item Types ekranı
/// 
/// Bir projeye ait work item type'ları listeler.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import 'work_item_type_items_screen.dart';

class ProjectWorkItemTypesScreen extends StatefulWidget {
  final String projectName;

  const ProjectWorkItemTypesScreen({
    super.key,
    required this.projectName,
  });

  @override
  State<ProjectWorkItemTypesScreen> createState() => _ProjectWorkItemTypesScreenState();
}

class _ProjectWorkItemTypesScreenState extends State<ProjectWorkItemTypesScreen> {
  final WorkItemService _workItemService = WorkItemService();
  List<String> _workItemTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkItemTypes();
  }

  Future<void> _loadWorkItemTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final types = await _workItemService.getWorkItemTypes(
        serverUrl: serverUrl,
        token: token!,
        project: widget.projectName,
        collection: collection,
      );

      setState(() {
        _workItemTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getWorkItemTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'epic':
        return Icons.star;
      case 'feature':
        return Icons.flag;
      case 'backlog item':
      case 'product backlog item':
      case 'user story':
        return Icons.list;
      case 'task':
        return Icons.assignment;
      case 'bug':
        return Icons.bug_report;
      default:
        return Icons.description;
    }
  }

  Color _getWorkItemTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'epic':
        return Colors.orange;
      case 'feature':
        return Colors.purple;
      case 'backlog item':
      case 'product backlog item':
      case 'user story':
        return Colors.blue;
      case 'task':
        return Colors.green;
      case 'bug':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkItemTypes,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadWorkItemTypes,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _workItemTypes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Work item type bulunamadı',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWorkItemTypes,
                      child: ListView.builder(
                        itemCount: _workItemTypes.length,
                        itemBuilder: (context, index) {
                          final type = _workItemTypes[index];
                          final icon = _getWorkItemTypeIcon(type);
                          final color = _getWorkItemTypeColor(type);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(
                                type,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Project: ${widget.projectName}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkItemTypeItemsScreen(
                                      projectName: widget.projectName,
                                      workItemType: type,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

