/// Board detay ekranı
/// 
/// Board'daki work item'ları (Backlog Items, Epics, Features) gösterir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/board_service.dart';
import '../services/work_item_service.dart';
import 'work_item_detail_screen.dart';

class BoardDetailScreen extends StatefulWidget {
  final Board board;

  const BoardDetailScreen({
    super.key,
    required this.board,
  });

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final BoardService _boardService = BoardService();
  final WorkItemService _workItemService = WorkItemService();
  Map<String, List<Map<String, dynamic>>> _workItems = {
    'Backlog Items': [],
    'Epics': [],
    'Features': [],
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoardWorkItems();
  }

  Future<void> _loadBoardWorkItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated || widget.board.projectName == null) {
        setState(() {
          _error = 'Not authenticated or project name missing';
          _isLoading = false;
        });
        return;
      }

      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      // Get work items from board
      final workItems = await _boardService.getBoardWorkItems(
        serverUrl: serverUrl,
        token: token!,
        project: widget.board.projectName!,
        boardId: widget.board.id,
        collection: collection,
      );

      // If board API doesn't return items, try to get all work items from project
      if (workItems['Backlog Items']!.isEmpty && 
          workItems['Epics']!.isEmpty && 
          workItems['Features']!.isEmpty) {
        // Get all work items from project
        final allWorkItems = await _workItemService.getAllWorkItems(
          serverUrl: serverUrl,
          token: token,
          collection: collection,
          project: widget.board.projectName!,
        );

        // Categorize work items
        for (final item in allWorkItems) {
          final type = item.type.toLowerCase();
          if (type == 'backlog item' || type == 'product backlog item' || type == 'user story') {
            workItems['Backlog Items']!.add({
              'id': item.id,
              'title': item.title,
              'state': item.state,
              'workItemType': item.type,
            });
          } else if (type == 'epic') {
            workItems['Epics']!.add({
              'id': item.id,
              'title': item.title,
              'state': item.state,
              'workItemType': item.type,
            });
          } else if (type == 'feature') {
            workItems['Features']!.add({
              'id': item.id,
              'title': item.title,
              'state': item.state,
              'workItemType': item.type,
            });
          }
        }
      }

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

  Future<void> _navigateToWorkItem(int workItemId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      // Get work item detail first
      final workItem = await _workItemService.getWorkItemDetails(
        serverUrl: serverUrl,
        token: token!,
        workItemId: workItemId,
        collection: collection,
      );

      if (workItem != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkItemDetailScreen(workItem: workItem),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Work item yüklenemedi: $e')),
        );
      }
    }
  }

  Widget _buildWorkItemList(String title, List<Map<String, dynamic>> items, IconData icon, Color color) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          '$title (${items.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: items.map((item) {
          return ListTile(
            title: Text(
              item['title'] as String? ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'State: ${item['state'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Text(
              '#${item['id']}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              final id = item['id'] as int?;
              if (id != null) {
                _navigateToWorkItem(id);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoardWorkItems,
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
                        onPressed: _loadBoardWorkItems,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBoardWorkItems,
                  child: ListView(
                    children: [
                      if (widget.board.projectName != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Project: ${widget.board.projectName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      _buildWorkItemList(
                        'Backlog Items',
                        _workItems['Backlog Items']!,
                        Icons.list,
                        Colors.blue,
                      ),
                      _buildWorkItemList(
                        'Epics',
                        _workItems['Epics']!,
                        Icons.star,
                        Colors.orange,
                      ),
                      _buildWorkItemList(
                        'Features',
                        _workItems['Features']!,
                        Icons.flag,
                        Colors.purple,
                      ),
                      if (_workItems['Backlog Items']!.isEmpty &&
                          _workItems['Epics']!.isEmpty &&
                          _workItems['Features']!.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('Work item bulunamadı'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

