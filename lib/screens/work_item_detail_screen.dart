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
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
  List<WorkItemComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isAddingComment = false;
  final TextEditingController _commentController = TextEditingController();
  
  // Steps data structure
  List<Map<String, String>> _steps = []; // Each step: {'action': '', 'expectedResult': ''}
  bool _isEditingSteps = false;

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
    _commentController.dispose();
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

    // Get work item with all fields (use expand=all to get all fields including custom fields)
    final url = '$baseUrl/_apis/wit/workitems/${widget.workItem.id}?\$expand=all&api-version=7.0';
    
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

    WorkItem? detailedItem;
    List<dynamic>? relations;
    
    if (response.statusCode == 200) {
      detailedItem = WorkItem.fromJson(response.data);
      
      // Get relations directly from response
      if (response.data.containsKey('relations')) {
        relations = response.data['relations'] as List?;
        debugPrint('✅ [UI] Found ${relations?.length ?? 0} relations in response');
      }
    }

    if (detailedItem != null) {
      final item = detailedItem; // Local variable for null safety
      setState(() {
        _detailedWorkItem = item;
        _selectedState = item.state;
        _isEditingDescription = false;
      });
      
      // If we have relations, process them directly (no extra API call)
      if (relations != null && relations.isNotEmpty) {
        _loadRelatedWorkItemsFromRelations(relations);
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

      // Initialize field controllers and combo box values for ALL non-hidden fields
      // First, get all fields from field definitions (non-hidden)
      final allNonHiddenFields = <String, FieldDefinition>{};
      for (var entry in fieldDefs.entries) {
        if (!entry.value.isHidden && !entry.key.startsWith('System.')) {
          allNonHiddenFields[entry.key] = entry.value;
        }
      }
      
      // Also include fields from allFields that might not be in field definitions
      if (detailedItem.allFields != null) {
        for (var entry in detailedItem.allFields!.entries) {
          // Skip System fields (they're handled separately)
          if (entry.key.startsWith('System.')) continue;
          
          // If field is not in field definitions, add it (might be a custom field)
          if (!allNonHiddenFields.containsKey(entry.key)) {
            // Try to infer type from value
            String fieldType = 'string';
            if (entry.value is bool) {
              fieldType = 'boolean';
            } else if (entry.value is num) {
              fieldType = 'double';
            }
            
            allNonHiddenFields[entry.key] = FieldDefinition(
              referenceName: entry.key,
              name: entry.key,
              type: fieldType,
              allowedValues: [],
              isComboBox: false,
              isHidden: false,
            );
          }
        }
      }
      
      // Now initialize controllers for all non-hidden fields based on their types
      for (var entry in allNonHiddenFields.entries) {
        final fieldKey = entry.key;
        final fieldDef = entry.value;
        final fieldValue = detailedItem.allFields?[fieldKey];
        final currentValue = fieldValue?.toString() ?? '';
        final fieldType = fieldDef.type.toLowerCase();
        
        // Check field type and initialize appropriate controller
        if (fieldType == 'boolean') {
          // Boolean field - store as string for checkbox
          _comboBoxValues[fieldKey] = (fieldValue as bool? ?? false).toString();
        }
        // Check if it's a date field
        else if (fieldType == 'date' || fieldType == 'datetime') {
          // Date field - store as string, will use date picker in UI
          _comboBoxValues[fieldKey] = currentValue.isEmpty ? null : currentValue;
        }
        // Check if field has allowed values (combo box/selectbox/picklist)
        else if (fieldDef.allowedValues.isNotEmpty || 
                 fieldType.contains('picklist') ||
                 fieldDef.isComboBox) {
          // Combo box/selectbox/picklist field
          _comboBoxValues[fieldKey] = currentValue.isEmpty ? null : currentValue;
        } 
        // Check if it's a textarea/html field
        else if (fieldType == 'html' || fieldType == 'plainttext' || fieldType == 'text') {
          // TextArea field - use multiline text field
          _fieldControllers[fieldKey] = TextEditingController(
            text: currentValue,
          );
        }
        // Regular text/number field
        else if (fieldValue is String || fieldValue is num || fieldValue == null) {
          _fieldControllers[fieldKey] = TextEditingController(
            text: currentValue,
          );
        }
      }
      
      // Load Steps field if exists
      _parseSteps(detailedItem.allFields);
      
      // Load comments
      _loadComments();
      
      print('Custom fields initialized: ${_fieldControllers.length} text fields, ${_comboBoxValues.length} combo boxes');
    }

    setState(() => _isLoading = false);
    
    // Load related work items after all other data is loaded
    debugPrint('🔄 [UI] Calling _loadRelatedWorkItems from _loadWorkItemDetails');
    _loadRelatedWorkItems();
  }

  /// Load comments
  Future<void> _loadComments() async {
    if (!mounted || _detailedWorkItem == null) return;
    
    setState(() => _isLoadingComments = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null) {
        setState(() => _isLoadingComments = false);
        return;
      }
      
      final comments = await _workItemService.getWorkItemComments(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemId: _detailedWorkItem!.id,
        collection: storage.getCollection(),
        project: _detailedWorkItem!.project,
      );
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }
  
  /// Add comment
  Future<void> _addComment() async {
    if (!mounted || _detailedWorkItem == null || _commentController.text.trim().isEmpty) return;
    
    setState(() => _isAddingComment = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null) {
        setState(() => _isAddingComment = false);
        return;
      }
      
      final success = await _workItemService.addWorkItemComment(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemId: _detailedWorkItem!.id,
        text: _commentController.text.trim(),
        collection: storage.getCollection(),
        project: _detailedWorkItem!.project,
      );
      
      if (mounted) {
        if (success) {
          _commentController.clear();
          await _loadComments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yorum eklendi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yorum eklenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isAddingComment = false);
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        setState(() => _isAddingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load related work items from relations array (direct from getWorkItemDetails response)
  Future<void> _loadRelatedWorkItemsFromRelations(List<dynamic> relations) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRelated = true;
      _relatedWorkItemsGrouped = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoadingRelated = false;
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
        setState(() {
          _relatedWorkItemsGrouped = relatedItemsGrouped;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [UI] Error loading related work items from relations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  Future<void> _loadRelatedWorkItems() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRelated = true;
      _relatedWorkItemsGrouped = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoadingRelated = false;
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

    // Update combo box fields, boolean fields, and date fields
    for (var entry in _comboBoxValues.entries) {
      final fieldDef = _fieldDefinitions[entry.key];
      final fieldType = (fieldDef?.type ?? '').toLowerCase();
      final currentValue = _detailedWorkItem!.allFields?[entry.key];
      
      // Handle boolean fields
      if (fieldType == 'boolean') {
        final boolValue = entry.value == 'true';
        final currentBoolValue = currentValue is bool ? currentValue : (currentValue?.toString() == 'true');
        if (boolValue != currentBoolValue) {
          updates.add({
            'path': '/fields/${entry.key}',
            'value': boolValue,
          });
        }
      } 
      // Handle date fields
      else if (fieldType == 'date' || fieldType == 'datetime') {
        final currentStringValue = currentValue?.toString();
        if (entry.value != currentStringValue && entry.value != null && entry.value!.isNotEmpty) {
          updates.add({
            'path': '/fields/${entry.key}',
            'value': entry.value!,
          });
        }
      } 
      // Handle string/selectbox/combobox/picklist fields
      else {
        final currentStringValue = currentValue?.toString();
        if (entry.value != currentStringValue && entry.value != null) {
          updates.add({
            'path': '/fields/${entry.key}',
            'value': entry.value!,
          });
        }
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

                      // Steps Section
                      if (_steps.isNotEmpty || _isEditingSteps)
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
                                      'Steps',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (_isEditingSteps)
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: _addStep,
                                            tooltip: 'Add Step',
                                          ),
                                        IconButton(
                                          icon: Icon(_isEditingSteps ? Icons.save : Icons.edit),
                                          onPressed: _toggleStepsEditing,
                                          tooltip: _isEditingSteps ? 'Save Steps' : 'Edit Steps',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildStepsTable(),
                              ],
                            ),
                          ),
                        ),
                      if (_steps.isNotEmpty || _isEditingSteps)
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
                              // Empty state
                              else if (_relatedWorkItemsGrouped.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Related work item bulunamadı',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              // Data state
                              else
                                ..._buildRelatedWorkItemsList(),
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
                                // Combo box/selectbox fields, boolean/tickbox fields, and date fields
                                ..._comboBoxValues.entries.map((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  final allowedValues = fieldDef?.allowedValues ?? [];
                                  final fieldType = (fieldDef?.type ?? '').toLowerCase();
                                  
                                  // Check if it's a boolean field (tickbox)
                                  if (fieldType == 'boolean') {
                                    final boolValue = entry.value == 'true';
                                    return CheckboxListTile(
                                      title: Text(fieldDef?.name ?? entry.key),
                                      value: boolValue,
                                      onChanged: (value) {
                                        setState(() {
                                          _comboBoxValues[entry.key] = (value ?? false).toString();
                                        });
                                      },
                                    );
                                  }
                                  
                                  // Check if it's a date field
                                  if (fieldType == 'date' || fieldType == 'datetime') {
                                    DateTime? selectedDate;
                                    if (entry.value != null && entry.value!.isNotEmpty) {
                                      selectedDate = DateTime.tryParse(entry.value!);
                                    }
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate ?? DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              // Format date as ISO 8601 string (Azure DevOps format)
                                              _comboBoxValues[entry.key] = picked.toIso8601String();
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: fieldDef?.name ?? entry.key,
                                            border: const OutlineInputBorder(),
                                            suffixIcon: const Icon(Icons.calendar_today),
                                          ),
                                          child: Text(
                                            selectedDate != null
                                                ? DateFormat('MM/dd/yyyy hh:mm a').format(selectedDate)
                                                : 'Select date',
                                            style: TextStyle(
                                              color: selectedDate != null ? null : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Check if it's a picklist/combobox with allowed values
                                  if (allowedValues.isNotEmpty || 
                                      fieldType.contains('picklist') ||
                                      (fieldDef?.isComboBox ?? false)) {
                                    // Dropdown for selectbox/combobox/picklist
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: DropdownButtonFormField<String>(
                                        value: entry.value,
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
                                  }
                                  
                                  // Fallback to text field if no allowed values and not date/boolean
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
                                }),
                                // Text fields (including textarea/html fields)
                                ..._fieldControllers.entries.map((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  final fieldType = (fieldDef?.type ?? '').toLowerCase();
                                  
                                  // Check if it's a textarea/html field
                                  final isTextArea = fieldType == 'html' || 
                                                    fieldType == 'plainttext' || 
                                                    fieldType == 'text' ||
                                                    fieldDef?.name.toLowerCase().contains('multiple') == true ||
                                                    entry.key.toLowerCase().contains('multiple') == true;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: TextFormField(
                                      controller: entry.value,
                                      maxLines: isTextArea ? 5 : 1,
                                      decoration: InputDecoration(
                                        labelText: fieldDef?.name ?? entry.key,
                                        border: const OutlineInputBorder(),
                                        alignLabelWithHint: isTextArea,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),

                      // Discussion/Comments
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discussion',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Comments list
                              if (_isLoadingComments)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_comments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Henüz yorum yok',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              else
                                ..._comments.map((comment) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.blue,
                                              child: Text(
                                                comment.createdBy != null && comment.createdBy!.isNotEmpty
                                                    ? comment.createdBy![0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.createdBy ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (comment.createdDate != null)
                                                    Text(
                                                      _formatTimeAgo(comment.createdDate),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 32.0),
                                          child: Text(
                                            comment.text,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              
                              // Add comment
                              TextField(
                                controller: _commentController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Yorum ekle...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _isAddingComment ? null : _addComment,
                                  child: _isAddingComment
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Yorum Ekle'),
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final widgets = <Widget>[];
    
    if (_relatedWorkItemsGrouped.isEmpty) {
      return [];
    }
    
    for (var entry in _relatedWorkItemsGrouped.entries) {
      final category = entry.key;
      final items = entry.value;
      
      if (items.isEmpty) {
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
  
  /// Parse Steps HTML from work item fields
  void _parseSteps(Map<String, dynamic>? allFields) {
    _steps = [];
    
    if (allFields == null) return;
    
    // Try different possible field names for Steps
    final stepsFields = [
      'Microsoft.VSTS.TCM.Steps',
      'System.Steps',
      'Steps',
    ];
    
    String? stepsHtml;
    for (final fieldName in stepsFields) {
      if (allFields.containsKey(fieldName)) {
        stepsHtml = allFields[fieldName]?.toString();
        if (stepsHtml != null && stepsHtml.isNotEmpty) {
          break;
        }
      }
    }
    
    if (stepsHtml == null || stepsHtml.isEmpty) {
      return;
    }
    
    debugPrint('🔍 [Steps] Raw Steps content: ${stepsHtml.substring(0, stepsHtml.length > 200 ? 200 : stepsHtml.length)}...');
    
    // Try to detect format: XML (<steps>, <step>) or HTML (<div>)
    final isXmlFormat = stepsHtml.trim().startsWith('<steps') || stepsHtml.contains('<step ');
    final isDivFormat = stepsHtml.contains('<div>') || stepsHtml.contains('<div ');
    
    try {
      if (isXmlFormat) {
        // Parse XML format: <steps><step id="..." type="Action">...</step><step id="..." type="ExpectedResult">...</step></steps>
        debugPrint('🔍 [Steps] Detected XML format');
        final stepRegex = RegExp(r'<step[^>]*type="([^"]*)"[^>]*>(.*?)</step>', dotAll: true);
        final matches = stepRegex.allMatches(stepsHtml);
        
        String? currentAction;
        String? currentExpectedResult;
        
        for (var match in matches) {
          final stepType = match.group(1)?.toLowerCase() ?? '';
          final stepContent = match.group(2)?.trim() ?? '';
          
          if (stepType.contains('action')) {
            currentAction = stepContent;
          } else if (stepType.contains('expected')) {
            currentExpectedResult = stepContent;
            // When we get ExpectedResult, we have a complete step pair
            if (currentAction != null) {
              _steps.add({
                'action': currentAction,
                'expectedResult': currentExpectedResult,
              });
              currentAction = null;
              currentExpectedResult = null;
            }
          } else {
            // Unknown step type, treat as action if we don't have one
            if (currentAction == null) {
              currentAction = stepContent;
            } else {
              // We have an action, this might be expected result
              currentExpectedResult = stepContent;
              _steps.add({
                'action': currentAction,
                'expectedResult': currentExpectedResult,
              });
              currentAction = null;
              currentExpectedResult = null;
            }
          }
        }
        
        // If we have leftover action, add it
        if (currentAction != null) {
          _steps.add({
            'action': currentAction,
            'expectedResult': currentExpectedResult ?? '',
          });
        }
        
        // If no steps found with type attribute, try parsing by order (alternating Action/ExpectedResult)
        if (_steps.isEmpty) {
          final simpleStepRegex = RegExp(r'<step[^>]*>(.*?)</step>', dotAll: true);
          final simpleMatches = simpleStepRegex.allMatches(stepsHtml);
          final stepContents = simpleMatches.map((m) => m.group(1)?.trim() ?? '').where((s) => s.isNotEmpty).toList();
          
          for (int i = 0; i < stepContents.length; i += 2) {
            if (i + 1 < stepContents.length) {
              _steps.add({
                'action': stepContents[i],
                'expectedResult': stepContents[i + 1],
              });
            } else {
              _steps.add({
                'action': stepContents[i],
                'expectedResult': '',
              });
            }
          }
        }
      } else if (isDivFormat) {
        // Parse HTML div format: <div><div>Action</div><div>Expected result</div></div>...
        debugPrint('🔍 [Steps] Detected HTML div format');
        final regex = RegExp(r'<div[^>]*>(.*?)</div>', dotAll: true);
        final matches = regex.allMatches(stepsHtml);
        
        List<String> cells = [];
        for (var match in matches) {
          final content = match.group(1)?.trim() ?? '';
          // Keep HTML content, don't strip tags
          if (content.isNotEmpty) {
            cells.add(content);
          }
        }
        
        // Steps are typically in pairs: Action, Expected result
        // Skip header row if exists (first two cells might be "Action" and "Expected result")
        int startIndex = 0;
        if (cells.length >= 2) {
          // Check if first two cells are headers (plain text, no HTML tags)
          final firstCell = cells[0].replaceAll(RegExp(r'<[^>]+>'), '').toLowerCase();
          final secondCell = cells[1].replaceAll(RegExp(r'<[^>]+>'), '').toLowerCase();
          if (firstCell.contains('action') || secondCell.contains('expected')) {
            startIndex = 2;
          }
        }
        
        // Parse pairs - keep HTML content
        for (int i = startIndex; i < cells.length; i += 2) {
          if (i + 1 < cells.length) {
            _steps.add({
              'action': cells[i], // Keep HTML
              'expectedResult': cells[i + 1], // Keep HTML
            });
          } else {
            // Single cell (action only)
            _steps.add({
              'action': cells[i], // Keep HTML
              'expectedResult': '',
            });
          }
        }
      } else {
        // Unknown format, try to parse as plain text or show as-is
        debugPrint('⚠️ [Steps] Unknown format, showing as single field');
        _steps = [{
          'action': stepsHtml.trim(),
          'expectedResult': '',
        }];
      }
      
      debugPrint('✅ [Steps] Parsed ${_steps.length} steps');
    } catch (e) {
      debugPrint('❌ [Steps] Error parsing Steps: $e');
      // If parsing fails, show as single text field with HTML
      _steps = [{
        'action': stepsHtml.trim(), // Keep HTML
        'expectedResult': '',
      }];
    }
  }
  
  /// Build Steps table widget
  Widget _buildStepsTable() {
    if (_steps.isEmpty && !_isEditingSteps) {
      return const Text(
        'No steps defined',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }
    
    // If editing, show editable table
    if (_isEditingSteps) {
      return Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Action',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Expected Result',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40), // Space for delete button
              ],
            ),
          ),
          // Data rows
          ...List.generate(_steps.length, (index) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${index + 1}'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: TextEditingController(text: _steps[index]['action']),
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8.0),
                        ),
                        onChanged: (value) {
                          _steps[index]['action'] = value;
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: TextEditingController(text: _steps[index]['expectedResult']),
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8.0),
                        ),
                        onChanged: (value) {
                          _steps[index]['expectedResult'] = value;
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStep(index),
                    tooltip: 'Delete Step',
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }
    
    // If not editing, show read-only table
    return Column(
      children: [
        // Header row
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Action',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Expected Result',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data rows
        ...List.generate(_steps.length, (index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('${index + 1}'),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _steps[index]['action'] != null && _steps[index]['action']!.isNotEmpty
                        ? Html(
                            data: _steps[index]['action']!,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(14),
                              ),
                            },
                          )
                        : const Text(
                            '',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _steps[index]['expectedResult'] != null && _steps[index]['expectedResult']!.isNotEmpty
                        ? Html(
                            data: _steps[index]['expectedResult']!,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(14),
                              ),
                            },
                          )
                        : const Text(
                            '',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  /// Toggle Steps editing mode
  void _toggleStepsEditing() {
    if (_isEditingSteps) {
      // Save Steps
      _saveSteps();
    } else {
      // Start editing
      setState(() {
        _isEditingSteps = true;
        // If no steps exist, add one empty step
        if (_steps.isEmpty) {
          _steps.add({
            'action': '',
            'expectedResult': '',
          });
        }
      });
    }
  }
  
  /// Add a new step
  void _addStep() {
    setState(() {
      _steps.add({
        'action': '',
        'expectedResult': '',
      });
    });
  }
  
  /// Delete a step
  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }
  
  /// Save Steps back to work item
  Future<void> _saveSteps() async {
    if (!mounted || _detailedWorkItem == null) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      // Convert steps to HTML format
      final stepsHtml = _stepsToHtml();
      
      // Update work item with Steps field
      final cleanUrl = authService.serverUrl!.endsWith('/') 
          ? authService.serverUrl!.substring(0, authService.serverUrl!.length - 1) 
          : authService.serverUrl!;
      
      final baseUrl = storage.getCollection() != null && storage.getCollection()!.isNotEmpty
          ? '$cleanUrl/${storage.getCollection()}'
          : cleanUrl;
      
      final url = '$baseUrl/_apis/wit/workitems/${_detailedWorkItem!.id}?api-version=7.0';
      
      final patchBody = [
        {
          'op': 'add',
          'path': '/fields/Microsoft.VSTS.TCM.Steps',
          'value': stepsHtml,
        }
      ];
      
      final response = await _workItemService.dio.patch(
        url,
        data: patchBody,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_workItemService.encodeToken(token)}',
            'Content-Type': 'application/json-patch+json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        // Reload work item details
        await _loadWorkItemDetails();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Steps saved successfully')),
          );
        }
      } else {
        throw Exception('Failed to save Steps: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving Steps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Steps: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _isEditingSteps = false;
        });
      }
    }
  }
  
  /// Convert steps list to HTML format
  String _stepsToHtml() {
    if (_steps.isEmpty) {
      return '';
    }
    
    // Build HTML structure: <div><div>Action</div><div>Expected result</div></div>...
    final buffer = StringBuffer();
    buffer.write('<div>');
    
    // Header row (optional, but Azure DevOps usually includes it)
    buffer.write('<div><div>Action</div><div>Expected result</div></div>');
    
    // Data rows
    for (var step in _steps) {
      final action = step['action'] ?? '';
      final expectedResult = step['expectedResult'] ?? '';
      
      // If action/expectedResult already contains HTML tags, use as-is
      // Otherwise, escape HTML entities
      String processedAction = action;
      String processedExpected = expectedResult;
      
      // Check if content already has HTML tags
      final hasHtmlTags = RegExp(r'<[^>]+>').hasMatch(action) || RegExp(r'<[^>]+>').hasMatch(expectedResult);
      
      if (!hasHtmlTags) {
        // No HTML tags, escape entities
        processedAction = action
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        processedExpected = expectedResult
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
      }
      // If has HTML tags, use as-is (already HTML formatted)
      
      buffer.write('<div><div>$processedAction</div><div>$processedExpected</div></div>');
    }
    
    buffer.write('</div>');
    return buffer.toString();
  }
}
