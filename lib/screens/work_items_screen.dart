/// Work Items ekranı
/// 
/// Tüm work item'ları listeler ve yeni work item oluşturma özelliği sunar.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import 'work_item_detail_screen.dart';
import 'create_work_item_screen.dart';

class WorkItemsScreen extends StatefulWidget {
  const WorkItemsScreen({super.key});

  @override
  State<WorkItemsScreen> createState() => _WorkItemsScreenState();
}

class _WorkItemsScreenState extends State<WorkItemsScreen> {
  final WorkItemService _workItemService = WorkItemService();
  List<WorkItem> _workItems = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadWorkItems();
  }

  Future<void> _loadWorkItems() async {
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

      final workItems = await _workItemService.getAllWorkItems(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: _selectedProject,
      );

      setState(() {
        _workItems = workItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateWorkItemScreen(),
      ),
    );

    if (result == true) {
      _loadWorkItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Create Work Item',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkItems,
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
                        onPressed: _loadWorkItems,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _workItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Work item bulunamadı',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWorkItems,
                      child: ListView.builder(
                        itemCount: _workItems.length,
                        itemBuilder: (context, index) {
                          final item = _workItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(item.id.toString()),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${item.type}'),
                                  Text('State: ${item.state}'),
                                  if (item.assignedTo != null)
                                    Text('Assigned to: ${item.assignedTo}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkItemDetailScreen(workItem: item),
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

