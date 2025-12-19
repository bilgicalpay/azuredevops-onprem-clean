/// Work Item detay ekranı
/// 
/// Work item'ın tüm detaylarını gösterir ve düzenleme imkanı sağlar.
/// State değiştirme, custom field güncelleme, description düzenleme
/// ve ilişkili work item'ları görüntüleme özelliklerini içerir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';

/// Work Item detay ekranı widget'ı
/// Work item detaylarını gösterir ve düzenleme yapar
class WorkItemDetailScreen extends StatefulWidget {
  final WorkItem workItem;

  const WorkItemDetailScreen({
    super.key,
    required this.workItem,
  });

  @override
  State<WorkItemDetailScreen> createState() => _WorkItemDetailScreenState();
}

class _WorkItemDetailScreenState extends State<WorkItemDetailScreen> {
  final WorkItemService _workItemService = WorkItemService();
  WorkItem? _detailedWorkItem;
  bool _isLoading = true;
  bool _isUpdating = false;
  List<String> _availableStates = [];
  String? _selectedState;
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, String?> _comboBoxValues = {};
  Map<String, FieldDefinition> _fieldDefinitions = {};
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditingDescription = false;
  Map<String, List<RelatedWorkItem>> _relatedWorkItemsGrouped = {};
  bool _isLoadingRelated = false;
  String _relatedWorkItemsError = '';
  Map<String, dynamic>? _lastApiResponse; // Store last API response for debugging

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 [UI] initState called for work item #${widget.workItem.id}');
    _loadWorkItemDetails();
  }

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkItemDetails() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    // Get work item details with relations - we'll get relations from the same response
    final cleanUrl = authService.serverUrl!.endsWith('/') 
        ? authService.serverUrl!.substring(0, authService.serverUrl!.length - 1) 
        : authService.serverUrl!;
    
    final baseUrl = storage.getCollection() != null && storage.getCollection()!.isNotEmpty
        ? '$cleanUrl/${storage.getCollection()}'
        : cleanUrl;

    final url = '$baseUrl/_apis/wit/workitems/${widget.workItem.id}?\$expand=relations&api-version=7.0';
    
    debugPrint('🔄 [UI] Fetching work item details from: $url');
    
    final token = await authService.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }
    final response = await _workItemService.dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Basic ${_workItemService.encodeToken(token)}',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Store response for debugging
    _lastApiResponse = response.data as Map<String, dynamic>?;

    WorkItem? detailedItem;
    List<dynamic>? relations;
    String relationsDebugInfo = '';
    
    if (response.statusCode == 200) {
      detailedItem = WorkItem.fromJson(response.data);
      
      // Get relations directly from response
      if (response.data.containsKey('relations')) {
        relations = response.data['relations'] as List?;
        relationsDebugInfo = 'Found ${relations?.length ?? 0} relations';
        debugPrint('✅ [UI] Found ${relations?.length ?? 0} relations in response');
        if (relations != null && relations.isNotEmpty) {
          debugPrint('📋 [UI] First relation: ${relations[0]}');
          // Store for UI display - show first relation details
          final firstRel = relations[0] as Map<String, dynamic>;
          final relType = firstRel['rel'] ?? 'unknown';
          final relUrl = firstRel['url'] ?? 'no url';
          relationsDebugInfo = 'DEBUG: ${relations.length} relations found. First: rel=$relType, url=$relUrl';
        } else {
          relationsDebugInfo = 'DEBUG: Relations key exists but list is empty or null';
        }
      } else {
        relationsDebugInfo = 'No relations key. Keys: ${response.data.keys.toList()}';
        debugPrint('⚠️ [UI] No relations key in response. Keys: ${response.data.keys.toList()}');
        final keys = response.data.keys.toList().take(5).join(", ");
        relationsDebugInfo = 'DEBUG: No relations key. Response keys: $keys';
      }
    } else {
      relationsDebugInfo = 'API Error: ${response.statusCode}';
    }
    
    // Set debug info immediately - ALWAYS set it, even if empty
    debugPrint('🔍 [UI] Setting debug info: $relationsDebugInfo');
    setState(() {
      _relatedWorkItemsError = relationsDebugInfo.isNotEmpty ? relationsDebugInfo : 'DEBUG: No relations debug info available';
    });

    if (detailedItem != null) {
      final item = detailedItem; // Local variable for null safety
      setState(() {
        _detailedWorkItem = item;
        _selectedState = item.state;
        _isEditingDescription = false;
      });
      
      // If we have relations, process them directly (no extra API call)
      if (relations != null && relations.isNotEmpty) {
        final relationsCount = relations.length;
        debugPrint('🔄 [UI] Processing $relationsCount relations directly from response');
        // Update error message to show we're processing
        setState(() {
          _relatedWorkItemsError = 'DEBUG: Processing $relationsCount relations...';
        });
        _loadRelatedWorkItemsFromRelations(relations);
      } else {
        debugPrint('⚠️ [UI] No relations found');
        setState(() {
          _relatedWorkItemsError = relationsDebugInfo.isNotEmpty ? relationsDebugInfo : 'DEBUG: No relations in response';
        });
        // Don't call fallback - we already have the data
      }

      // Load available states
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final states = await _workItemService.getWorkItemStates(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemType: item.type,
        collection: storage.getCollection(),
        project: item.project,
      );

      setState(() {
        _availableStates = states;
      });

      // Load field definitions to detect combo boxes
      final fieldDefs = await _workItemService.getWorkItemFieldDefinitions(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemType: detailedItem.type,
        collection: storage.getCollection(),
        project: detailedItem.project,
      );

      setState(() {
        _fieldDefinitions = fieldDefs;
      });

      // Initialize field controllers and combo box values for custom fields
      if (detailedItem.allFields != null) {
        for (var entry in detailedItem.allFields!.entries) {
          // Skip System fields (they're handled separately)
          if (entry.key.startsWith('System.')) continue;
          
          final fieldDef = fieldDefs[entry.key];
          final currentValue = entry.value?.toString() ?? '';
          
          // Check if field has allowed values (combo box)
          if (fieldDef != null && fieldDef.isComboBox && fieldDef.allowedValues.isNotEmpty) {
            // Combo box field
            _comboBoxValues[entry.key] = currentValue.isEmpty ? null : currentValue;
            print('Combo box field found: ${entry.key} with ${fieldDef.allowedValues.length} values');
          } else if (entry.value is String || entry.value is num || entry.value is bool) {
            // Regular text/number/boolean field
            _fieldControllers[entry.key] = TextEditingController(
              text: currentValue,
            );
          }
        }
      }
      
      print('Custom fields initialized: ${_fieldControllers.length} text fields, ${_comboBoxValues.length} combo boxes');
    }

    setState(() => _isLoading = false);
    
    // Load related work items after all other data is loaded
    debugPrint('🔄 [UI] Calling _loadRelatedWorkItems from _loadWorkItemDetails');
    _loadRelatedWorkItems();
  }

  /// Load related work items from relations array (direct from getWorkItemDetails response)
  Future<void> _loadRelatedWorkItemsFromRelations(List<dynamic> relations) async {
    if (!mounted) return;
    
    debugPrint('🔄 [UI] _loadRelatedWorkItemsFromRelations called with ${relations.length} relations');
    
    // Keep existing debug info, don't clear it
    setState(() {
      _isLoadingRelated = true;
      // Don't clear _relatedWorkItemsError - keep debug info
      _relatedWorkItemsGrouped = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoadingRelated = false;
          _relatedWorkItemsError = 'Authentication token not available';
        });
        return;
      }

      final relatedItemsGrouped = await _workItemService.getRelatedWorkItemsFromResponse(
        serverUrl: authService.serverUrl!,
        token: token,
        relations: relations,
        workItemId: widget.workItem.id,
        collection: storage.getCollection(),
      );

      final totalCount = relatedItemsGrouped.values.fold<int>(0, (sum, list) => sum + list.length);
      debugPrint('✅ [UI] Received $totalCount related work items in ${relatedItemsGrouped.keys.length} categories');

      if (mounted) {
        final totalCount = relatedItemsGrouped.values.fold<int>(0, (sum, list) => sum + list.length);
        setState(() {
          _relatedWorkItemsGrouped = relatedItemsGrouped;
          _isLoadingRelated = false;
          // Update debug info with result
          if (totalCount > 0) {
            _relatedWorkItemsError = 'DEBUG: Loaded $totalCount items in ${relatedItemsGrouped.keys.length} categories: ${relatedItemsGrouped.keys.join(", ")}';
          } else {
            _relatedWorkItemsError = 'DEBUG: No items loaded. Relations processed but no work items found.';
          }
        });
        debugPrint('✅ [UI] State updated. _relatedWorkItemsGrouped.length = ${_relatedWorkItemsGrouped.length}');
      }
    } catch (e) {
      debugPrint('❌ [UI] Error loading related work items from relations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
          _relatedWorkItemsError = 'DEBUG: Error - $e';
        });
      }
    }
  }

  Future<void> _loadRelatedWorkItems() async {
    if (!mounted) return;
    
    debugPrint('🔄 [UI] Starting _loadRelatedWorkItems for work item #${widget.workItem.id}');
    
    setState(() {
      _isLoadingRelated = true;
      _relatedWorkItemsError = '';
      _relatedWorkItemsGrouped = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoadingRelated = false;
          _relatedWorkItemsError = 'Authentication token not available';
        });
        return;
      }

      final relatedItemsGrouped = await _workItemService.getRelatedWorkItemsGrouped(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemId: widget.workItem.id,
        collection: storage.getCollection(),
      );

      final totalCount = relatedItemsGrouped.values.fold<int>(0, (sum, list) => sum + list.length);
      debugPrint('✅ [UI] Received $totalCount related work items in ${relatedItemsGrouped.keys.length} categories');

      if (mounted) {
        setState(() {
          _relatedWorkItemsGrouped = relatedItemsGrouped;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [UI] Error loading related work items: $e');
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
          _relatedWorkItemsError = 'Related work items yüklenemedi: $e';
        });
      }
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getWorkItemTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'epic':
        return Icons.workspace_premium;
      case 'feature':
        return Icons.star;
      case 'user story':
      case 'story':
        return Icons.book;
      case 'task':
        return Icons.checklist;
      case 'bug':
        return Icons.bug_report;
      default:
        return Icons.article;
    }
  }

  Future<void> _saveDescription() async {
    setState(() {
      _isEditingDescription = false;
    });
    // Description will be saved when _updateWorkItem is called
  }

  Future<void> _updateWorkItem() async {
    if (_detailedWorkItem == null) return;

    setState(() => _isUpdating = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    final updates = <Map<String, dynamic>>[];

    // Update state if changed
    if (_selectedState != null && _selectedState != _detailedWorkItem!.state) {
      updates.add({
        'path': '/fields/System.State',
        'value': _selectedState!,
      });
    }

    // Update description if changed
    final newDescription = _descriptionController.text;
    final currentDescription = _detailedWorkItem!.description ?? '';
    if (newDescription != currentDescription && newDescription.isNotEmpty) {
      updates.add({
        'path': '/fields/System.Description',
        'value': newDescription,
      });
    }

    // Update custom text fields
    for (var entry in _fieldControllers.entries) {
      final currentValue = _detailedWorkItem!.allFields?[entry.key]?.toString() ?? '';
      if (entry.value.text != currentValue) {
        updates.add({
          'path': '/fields/${entry.key}',
          'value': entry.value.text,
        });
      }
    }

    // Update combo box fields
    for (var entry in _comboBoxValues.entries) {
      final currentValue = _detailedWorkItem!.allFields?[entry.key]?.toString();
      if (entry.value != currentValue && entry.value != null) {
        updates.add({
          'path': '/fields/${entry.key}',
          'value': entry.value!,
        });
      }
    }

    if (updates.isEmpty) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklik yok')),
        );
      }
      return;
    }

    final success = await _workItemService.updateWorkItem(
      serverUrl: authService.serverUrl!,
      token: authService.token!,
      workItemId: _detailedWorkItem!.id,
      updates: updates,
      collection: storage.getCollection(),
    );

    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditingDescription = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work item güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
      _loadWorkItemDetails(); // Reload to get updated data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Güncelleme başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Item #${widget.workItem.id}'),
        actions: [
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateWorkItem,
              tooltip: 'Kaydet',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detailedWorkItem == null
              ? const Center(child: Text('Work item yüklenemedi'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _detailedWorkItem!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),

                      // State selector
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'State',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _availableStates.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('State yükleniyor...', style: TextStyle(color: Colors.grey)),
                                    )
                                  : DropdownButtonFormField<String>(
                                      initialValue: _selectedState,
                                      items: _availableStates.map((state) {
                                        return DropdownMenuItem(
                                          value: state,
                                          child: Text(state),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedState = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'State seçin',
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // System Fields
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sistem Bilgileri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Type', _detailedWorkItem!.type),
                              _buildInfoRow('ID', _detailedWorkItem!.id.toString()),
                              if (_detailedWorkItem!.assignedTo != null)
                                _buildInfoRow('Assigned To', _detailedWorkItem!.assignedTo!),
                              if (_detailedWorkItem!.rev != null)
                                _buildInfoRow('Revision', _detailedWorkItem!.rev.toString()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_isEditingDescription ? Icons.save : Icons.edit),
                                    onPressed: () {
                                      if (_isEditingDescription) {
                                        _saveDescription();
                                        _updateWorkItem(); // Auto-save when exiting edit mode
                                      } else {
                                        setState(() {
                                          _isEditingDescription = true;
                                          _descriptionController.text = _detailedWorkItem!.description ?? '';
                                        });
                                      }
                                    },
                                    tooltip: _isEditingDescription ? 'Kaydet' : 'Düzenle',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isEditingDescription)
                                SizedBox(
                                  height: 300,
                                  child: TextField(
                                    controller: _descriptionController,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Description girin (HTML desteklenir)',
                                      border: OutlineInputBorder(),
                                    ),
                                    textAlignVertical: TextAlignVertical.top,
                                  ),
                                )
                              else
                                _detailedWorkItem!.description != null && _detailedWorkItem!.description!.isNotEmpty
                                    ? Html(
                                        data: _detailedWorkItem!.description!,
                                        style: {
                                          "body": Style(
                                            margin: Margins.zero,
                                            padding: HtmlPaddings.zero,
                                          ),
                                        },
                                      )
                                    : const Text(
                                        'Description yok',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Related Work Items - YENİDEN YAZILDI
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Related Work',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Loading state
                              if (_isLoadingRelated)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                  // Error state
                                  else if (_relatedWorkItemsError.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            _relatedWorkItemsError,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        // Show raw response data for debugging
                                        if (_lastApiResponse != null)
                                          ExpansionTile(
                                            title: const Text('Raw API Response (Debug)', style: TextStyle(fontSize: 12)),
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: SelectableText(
                                                  _lastApiResponse.toString(),
                                                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    )
                              // Empty state
                              else if (_relatedWorkItemsGrouped.isEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Related work item bulunamadı',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    // Debug info
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'DEBUG INFO:',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text('_isLoadingRelated: $_isLoadingRelated'),
                                          Text('_relatedWorkItemsError: ${_relatedWorkItemsError.isEmpty ? "(empty)" : _relatedWorkItemsError}'),
                                          Text('_relatedWorkItemsGrouped.length: ${_relatedWorkItemsGrouped.length}'),
                                          const SizedBox(height: 8),
                                          // Always show Raw API Response link
                                          if (_lastApiResponse != null)
                                            ExpansionTile(
                                              title: const Text('Raw API Response (Debug)', style: TextStyle(fontSize: 12, color: Colors.blue)),
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: SelectableText(
                                                    _lastApiResponse.toString(),
                                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            const Text('API Response not available', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              // Data state - Show all categories
                              else ...[
                                // Debug info - Always show
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'DEBUG: ${_relatedWorkItemsGrouped.length} categories, ${_relatedWorkItemsGrouped.values.fold<int>(0, (sum, list) => sum + list.length)} items',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Show raw data for debugging
                                if (_relatedWorkItemsGrouped.isNotEmpty)
                                  ..._relatedWorkItemsGrouped.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Category: ${entry.key}, Items: ${entry.value.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    );
                                  }),
                                // Actual list
                                ..._buildRelatedWorkItemsList(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom Fields
                      if (_fieldControllers.isNotEmpty || _comboBoxValues.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Custom Fields',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Combo box fields
                                ..._comboBoxValues.entries.map((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  final allowedValues = fieldDef?.allowedValues ?? [];
                                  
                                  if (allowedValues.isEmpty) {
                                    // Fallback to text field if no allowed values
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: TextFormField(
                                        initialValue: entry.value ?? '',
                                        decoration: InputDecoration(
                                          labelText: fieldDef?.name ?? entry.key,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _comboBoxValues[entry.key] = value.isEmpty ? null : value;
                                          });
                                        },
                                      ),
                                    );
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: entry.value,
                                      decoration: InputDecoration(
                                        labelText: fieldDef?.name ?? entry.key,
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: allowedValues.map((value) {
                                        return DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _comboBoxValues[entry.key] = value;
                                        });
                                      },
                                    ),
                                  );
                                }),
                                // Text fields
                                ..._fieldControllers.entries.map((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: TextFormField(
                                      controller: entry.value,
                                      decoration: InputDecoration(
                                        labelText: fieldDef?.name ?? entry.key,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // All Fields (for debugging)
                      ExpansionTile(
                        title: const Text('Tüm Alanlar (Debug)'),
                        children: [
                          if (_detailedWorkItem!.allFields != null)
                            ..._detailedWorkItem!.allFields!.entries.map((entry) {
                              return ListTile(
                                title: Text(entry.key),
                                subtitle: Text(entry.value.toString()),
                              );
                            }),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getWorkItemTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'epic':
        return Colors.orange;
      case 'feature':
        return Colors.purple;
      case 'user story':
      case 'story':
        return Colors.blue;
      case 'task':
        return Colors.green;
      case 'bug':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Colors.grey;
      case 'active':
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.orange;
      case 'closed':
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Build related work items list widget
  List<Widget> _buildRelatedWorkItemsList() {
    debugPrint('🔄 [UI] _buildRelatedWorkItemsList called. _relatedWorkItemsGrouped.length = ${_relatedWorkItemsGrouped.length}');
    
    final widgets = <Widget>[];
    
    if (_relatedWorkItemsGrouped.isEmpty) {
      debugPrint('⚠️ [UI] _relatedWorkItemsGrouped is empty!');
      return [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'DEBUG: _relatedWorkItemsGrouped is empty',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ];
    }
    
    for (var entry in _relatedWorkItemsGrouped.entries) {
      final category = entry.key;
      final items = entry.value;
      
      debugPrint('🔄 [UI] Processing category: $category with ${items.length} items');
      
      if (items.isEmpty) {
        debugPrint('⚠️ [UI] Category $category has no items, skipping');
        continue;
      }
      
      // Category header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: Text(
            category == 'Related' 
                ? 'Related (${items.length})'
                : '$category (${items.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
      
      // Items in this category
      for (var relatedItem in items) {
        final item = relatedItem.workItem;
        final timeAgo = _formatTimeAgo(relatedItem.changedDate);
        
        widgets.add(
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkItemDetailScreen(workItem: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Work item type icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getWorkItemTypeColor(item.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _getWorkItemTypeIcon(item.type),
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // User avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Text(
                      item.assignedTo != null && item.assignedTo!.isNotEmpty
                          ? item.assignedTo![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.id} ${item.title}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (timeAgo.isNotEmpty) ...[
                              Text(
                                'Updated $timeAgo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStateColor(item.state),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.state,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
}
