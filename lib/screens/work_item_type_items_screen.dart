/// Work Item Type Items ekranı
/// 
/// Belirli bir work item type'a ait work item'ları listeler.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import 'work_item_detail_screen.dart';

class WorkItemTypeItemsScreen extends StatefulWidget {
  final String projectName;
  final String workItemType;

  const WorkItemTypeItemsScreen({
    super.key,
    required this.projectName,
    required this.workItemType,
  });

  @override
  State<WorkItemTypeItemsScreen> createState() => _WorkItemTypeItemsScreenState();
}

class _WorkItemTypeItemsScreenState extends State<WorkItemTypeItemsScreen> {
  final WorkItemService _workItemService = WorkItemService();
  List<WorkItem> _workItems = [];
  bool _isLoading = true;
  String? _error;

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

      // Get all work items for this project and filter by type
      final allWorkItems = await _workItemService.getAllWorkItems(
        serverUrl: serverUrl,
        token: token!,
        collection: collection,
        project: widget.projectName,
      );

      // Filter by work item type
      final filteredWorkItems = allWorkItems
          .where((item) => item.type.toLowerCase() == widget.workItemType.toLowerCase())
          .toList();

      setState(() {
        _workItems = filteredWorkItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workItemType),
        actions: [
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

