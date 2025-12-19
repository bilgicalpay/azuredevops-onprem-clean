/// Work Item liste ekranı
/// 
/// Query sonuçlarını veya work item listesini gösterir.
/// Her work item için detay sayfasına geçiş sağlar.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import '../services/work_item_service.dart';
import 'work_item_detail_screen.dart';

/// Work Item liste ekranı widget'ı
/// Work item listesini gösterir
class WorkItemListScreen extends StatelessWidget {
  final List<WorkItem> workItems;
  final String title;

  const WorkItemListScreen({
    super.key,
    required this.workItems,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              '${workItems.length} work item',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: workItems.isEmpty
          ? const Center(
              child: Text(
                'Work item bulunamadı',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: workItems.length,
              itemBuilder: (context, index) {
                final workItem = workItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStateColor(workItem.state),
                      child: Text(
                        workItem.id.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      workItem.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${workItem.type}'),
                        Text('State: ${workItem.state}'),
                        if (workItem.assignedTo != null)
                          Text('Assigned to: ${workItem.assignedTo}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkItemDetailScreen(workItem: workItem),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'resolved':
        return Colors.purple;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

