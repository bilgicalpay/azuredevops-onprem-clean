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
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';
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
  
  // Attachments data structure
  List<Map<String, dynamic>> _attachments = []; // Each attachment: {'name': '', 'url': '', 'size': 0}
  bool _isUploadingAttachment = false;
  
  // Identity (Assigned To) data
  List<Identity> _identities = [];
  bool _isLoadingIdentities = false;
  String? _selectedAssignedToDescriptor;

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
        _loadAttachmentsFromRelations(relations);
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
          
          // Skip Steps field - removed from UI
          if (entry.key == 'Microsoft.VSTS.TCM.Steps' || 
              entry.key == 'System.Steps' || 
              entry.key == 'Steps') {
            continue;
          }
          
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
        // Regular text/number field (but not boolean)
        else if ((fieldValue is String || fieldValue is num || fieldValue == null) && fieldType != 'boolean') {
          _fieldControllers[fieldKey] = TextEditingController(
            text: currentValue,
          );
        }
      }
      
      // Initialize Assigned To field
      final assignedToValue = detailedItem.allFields?['System.AssignedTo'];
      if (assignedToValue != null) {
        // Try to extract descriptor or display name
        if (assignedToValue is Map) {
          _selectedAssignedToDescriptor = assignedToValue['descriptor']?.toString() ?? 
                                          assignedToValue['uniqueName']?.toString() ??
                                          assignedToValue['displayName']?.toString();
        } else if (assignedToValue is String && assignedToValue.isNotEmpty) {
          _selectedAssignedToDescriptor = assignedToValue;
        }
      }
      
      // Load comments
      _loadComments();
      
      print('Custom fields initialized: ${_fieldControllers.length} text fields, ${_comboBoxValues.length} combo boxes');
    }

    setState(() => _isLoading = false);
    
    // Load related work items after all other data is loaded
    debugPrint('🔄 [UI] Calling _loadRelatedWorkItems from _loadWorkItemDetails');
    _loadRelatedWorkItems();
  }

  /// Load identities for Assigned To field
  Future<void> _loadIdentities() async {
    setState(() => _isLoadingIdentities = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null || _detailedWorkItem == null) {
        setState(() => _isLoadingIdentities = false);
        return;
      }
      
      final identities = await _workItemService.getIdentities(
        serverUrl: authService.serverUrl!,
        token: token,
        collection: storage.getCollection(),
        project: _detailedWorkItem!.project,
      );
      
      setState(() {
        _identities = identities;
        _isLoadingIdentities = false;
      });
    } catch (e) {
      debugPrint('Error loading identities: $e');
      setState(() => _isLoadingIdentities = false);
    }
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
  
  /// Load attachments from relations array
  void _loadAttachmentsFromRelations(List<dynamic> relations) {
    _attachments = [];
    
    for (var relation in relations) {
      if (relation is Map<String, dynamic>) {
        final rel = relation['rel'] as String?;
        final url = relation['url'] as String?;
        
        // Check for any file attachment relation
        if (rel != null && url != null && (rel.contains('File') || rel.contains('Attachment'))) {
          final attributes = relation['attributes'] as Map<String, dynamic>?;
          String? name = attributes?['name'] as String?;
          final size = attributes?['resourceSize'] as int?;
          
          // Extract name from URL if not in attributes
          if (name == null || name.isEmpty) {
            final uriParts = url.split('/');
            if (uriParts.isNotEmpty) {
              name = uriParts.last.split('?').first; // Remove query params
            }
          }
          
          if (name != null && name.isNotEmpty) {
            _attachments.add({
              'name': name,
              'url': url,
              'size': size ?? 0,
            });
            debugPrint('✅ [Attachments] Added: $name (${size ?? 0} bytes)');
          }
        }
      }
    }
    
    debugPrint('✅ [Attachments] Total: ${_attachments.length}');
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Upload and attach file to work item
  Future<void> _uploadAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya seçilemedi')),
        );
        return;
      }

      setState(() {
        _isUploadingAttachment = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Step 1: Upload file
      final attachmentUrl = await _workItemService.uploadAttachment(
        serverUrl: authService.serverUrl!,
        token: token,
        filePath: file.path!,
        fileName: file.name,
        collection: storage.getCollection(),
      );

      if (attachmentUrl == null) {
        throw Exception('File upload failed');
      }

      // Step 2: Attach to work item
      final success = await _workItemService.attachFileToWorkItem(
        serverUrl: authService.serverUrl!,
        token: token,
        workItemId: widget.workItem.id,
        attachmentUrl: attachmentUrl,
        collection: storage.getCollection(),
      );

      if (success) {
        // Reload work item details to show new attachment
        await _loadWorkItemDetails();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya başarıyla eklendi')),
          );
        }
      } else {
        throw Exception('Failed to attach file to work item');
      }
    } catch (e) {
      debugPrint('❌ [Attachments] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
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

    // Update Assigned To field if changed
    if (_selectedAssignedToDescriptor != null && _detailedWorkItem != null && _identities.isNotEmpty) {
      try {
        final selectedIdentity = _identities.firstWhere(
          (id) => id.descriptor == _selectedAssignedToDescriptor || id.uniqueName == _selectedAssignedToDescriptor,
        );
        final currentAssignedTo = _detailedWorkItem!.assignedTo ?? '';
        
        if (selectedIdentity.displayName != currentAssignedTo) {
          // For identity fields, we need to use the display name
          updates.add({
            'path': '/fields/System.AssignedTo',
            'value': selectedIdentity.displayName, // Azure DevOps accepts display name
          });
        }
      } catch (e) {
        debugPrint('Error updating Assigned To: $e');
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
                              // Assigned To field - editable if identity field
                              _buildAssignedToField(),
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
                                  
                                  // Check if it's a boolean field (toggle/switch)
                                  if (fieldType == 'boolean') {
                                    final boolValue = entry.value == 'true';
                                    return SwitchListTile(
                                      title: Text(fieldDef?.name ?? entry.key),
                                      value: boolValue,
                                      onChanged: (value) {
                                        setState(() {
                                          _comboBoxValues[entry.key] = value.toString();
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
                                    final isReadOnly = fieldDef?.isReadOnly ?? false;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: InkWell(
                                        onTap: isReadOnly ? null : () async {
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
                                            enabled: !isReadOnly,
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
                                    final isReadOnly = fieldDef?.isReadOnly ?? false;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: DropdownButtonFormField<String>(
                                        value: entry.value,
                                      decoration: InputDecoration(
                                        labelText: fieldDef?.name ?? entry.key,
                                        border: const OutlineInputBorder(),
                                        enabled: !isReadOnly,
                                      ),
                                      items: allowedValues.map((value) {
                                        return DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: isReadOnly ? null : (value) {
                                        setState(() {
                                          _comboBoxValues[entry.key] = value;
                                          });
                                        },
                                      ),
                                    );
                                  }
                                  
                                  // Fallback to text field if no allowed values and not date/boolean
                                  final isReadOnly = fieldDef?.isReadOnly ?? false;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: TextFormField(
                                      initialValue: entry.value ?? '',
                                      decoration: InputDecoration(
                                        labelText: fieldDef?.name ?? entry.key,
                                        border: const OutlineInputBorder(),
                                      ),
                                      readOnly: isReadOnly,
                                      onChanged: isReadOnly ? null : (value) {
                                        setState(() {
                                          _comboBoxValues[entry.key] = value.isEmpty ? null : value;
                                        });
                                      },
                                    ),
                                  );
                                }),
                                // Text fields (including textarea/html fields) - exclude boolean fields
                                ..._fieldControllers.entries.where((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  final fieldType = (fieldDef?.type ?? '').toLowerCase();
                                  // Exclude boolean fields from text fields
                                  return fieldType != 'boolean';
                                }).map((entry) {
                                  final fieldDef = _fieldDefinitions[entry.key];
                                  final fieldType = (fieldDef?.type ?? '').toLowerCase();
                                  
                                  // Check if it's a textarea/html field
                                  final isTextArea = fieldType == 'html' || 
                                                    fieldType == 'plainttext' || 
                                                    fieldType == 'text' ||
                                                    fieldDef?.name.toLowerCase().contains('multiple') == true ||
                                                    entry.key.toLowerCase().contains('multiple') == true;
                                  
                                  final isReadOnly = fieldDef?.isReadOnly ?? false;
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
                                      readOnly: isReadOnly,
                                      enabled: !isReadOnly,
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
                      
                      // Attachments Section
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
                                    'Attachments',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: _isUploadingAttachment
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.attach_file),
                                    onPressed: _isUploadingAttachment ? null : _uploadAttachment,
                                    tooltip: 'Dosya Ekle',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_attachments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Henüz ek dosya yok',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              else
                                ..._attachments.map((attachment) {
                                  final name = attachment['name'] as String? ?? 'Unknown';
                                  final size = attachment['size'] as int? ?? 0;
                                  final url = attachment['url'] as String?;
                                  
                                  String sizeText = '';
                                  if (size > 0) {
                                    if (size < 1024) {
                                      sizeText = '$size B';
                                    } else if (size < 1024 * 1024) {
                                      sizeText = '${(size / 1024).toStringAsFixed(1)} KB';
                                    } else {
                                      sizeText = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
                                    }
                                  }
                                  
                                  return ListTile(
                                    leading: const Icon(Icons.attach_file),
                                    title: Text(name),
                                    subtitle: sizeText.isNotEmpty ? Text(sizeText) : null,
                                    onTap: url != null ? () => _openAttachment(url, name, context) : null,
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Open attachment file (download and open)
  Future<void> _openAttachment(String attachmentUrl, String fileName, BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya indiriliyor: $fileName')),
        );
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Download attachment
      final fileData = await _workItemService.downloadAttachment(
        attachmentUrl: attachmentUrl,
        token: token,
        serverUrl: authService.serverUrl,
        collection: storage.getCollection(),
      );

      if (fileData == null) {
        throw Exception('File download failed');
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = path.join(tempDir.path, safeFileName);

      // Write file to temporary directory
      final file = File(filePath);
      await file.writeAsBytes(fileData);

      debugPrint('✅ [Attachments] File saved to: $filePath');

      // Check if it's an image
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final isImage = imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext.toLowerCase()));

      if (isImage && context.mounted) {
        // Show image in dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(file),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (context.mounted) {
        // Open file with system default app
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Cannot open file: $fileName');
        }
      }
    } catch (e) {
      debugPrint('❌ [Attachments] Error opening attachment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya açılamadı: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildAssignedToField() {
    final assignedToFieldDef = _fieldDefinitions['System.AssignedTo'];
    final canEdit = assignedToFieldDef?.isIdentity == true && !(assignedToFieldDef?.isReadOnly ?? false);
    final currentValue = _detailedWorkItem!.assignedTo ?? '';
    
    if (!canEdit) {
      return _buildInfoRow('Assigned To', currentValue.isEmpty ? 'Unassigned' : currentValue);
    }
    
    // Find current identity from list
    Identity? currentIdentity;
    if (_selectedAssignedToDescriptor != null && _identities.isNotEmpty) {
      try {
        currentIdentity = _identities.firstWhere(
          (id) => id.descriptor == _selectedAssignedToDescriptor || 
                  id.displayName == currentValue ||
                  id.uniqueName == _selectedAssignedToDescriptor,
        );
      } catch (e) {
        // If not found, try to find by display name
        try {
          currentIdentity = _identities.firstWhere(
            (id) => id.displayName == currentValue,
          );
        } catch (e2) {
          currentIdentity = null;
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<Identity>(
        value: currentIdentity,
        decoration: const InputDecoration(
          labelText: 'Assigned To',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<Identity>(
            value: null,
            child: Text('Unassigned'),
          ),
          ..._identities.map((identity) {
            return DropdownMenuItem<Identity>(
              value: identity,
              child: Text(identity.displayName),
            );
          }),
        ],
        onChanged: _isLoadingIdentities ? null : (Identity? identity) {
          setState(() {
            _selectedAssignedToDescriptor = identity?.descriptor ?? identity?.uniqueName;
            if (identity != null && _detailedWorkItem != null) {
              // Update assignedTo in allFields if available
              if (_detailedWorkItem!.allFields != null) {
                _detailedWorkItem!.allFields!['System.AssignedTo'] = identity.displayName;
              }
              // Also update the assignedTo property
              _detailedWorkItem = WorkItem(
                id: _detailedWorkItem!.id,
                title: _detailedWorkItem!.title,
                type: _detailedWorkItem!.type,
                state: _detailedWorkItem!.state,
                assignedTo: identity.displayName,
              );
            }
          });
        },
        isExpanded: true,
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
  
  // Steps parsing removed - no longer needed
  
  // Old Steps parsing code removed
  /*
  void _parseSteps_OLD(Map<String, dynamic>? allFields) {
    _steps = [];
    
    if (allFields == null) {
      debugPrint('⚠️ [Steps] allFields is null');
      return;
    }
    
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
          debugPrint('✅ [Steps] Found Steps field: $fieldName');
          break;
        }
      }
    }
    
    if (stepsHtml == null || stepsHtml.isEmpty) {
      debugPrint('⚠️ [Steps] Steps field not found or empty. Available fields: ${allFields.keys.where((k) => k.toLowerCase().contains('step')).toList()}');
      return;
    }
    
    debugPrint('🔍 [Steps] Raw Steps content (first 500 chars): ${stepsHtml.substring(0, stepsHtml.length > 500 ? 500 : stepsHtml.length)}');
    debugPrint('🔍 [Steps] Raw Steps content (last 500 chars): ${stepsHtml.length > 500 ? stepsHtml.substring(stepsHtml.length - 500) : stepsHtml}');
    
    // Try to detect format: XML (<steps>, <step>) or HTML (<div>)
    final isXmlFormat = stepsHtml.trim().startsWith('<steps') || stepsHtml.contains('<step ');
    final isDivFormat = stepsHtml.contains('<div>') || stepsHtml.contains('<div ');
    
    try {
      if (isXmlFormat) {
        // Parse XML format: <steps><step id="..." type="Action">...</step><step id="..." type="ExpectedResult">...</step></steps>
        // Or: <steps><step id="1"><parameterizedstring type="Action">...</parameterizedstring><parameterizedstring type="ExpectedResult">...</parameterizedstring></step></steps>
        debugPrint('🔍 [Steps] Detected XML format');
        
        // First, try to parse with parameterizedstring (more common format)
        final stepRegex = RegExp(r'<step[^>]*>(.*?)</step>', dotAll: true);
        final stepMatches = stepRegex.allMatches(stepsHtml);
        
        debugPrint('🔍 [Steps] Found ${stepMatches.length} step elements');
        
        // Parse each step - find all parameterizedstring tags first
        final allParamStrings = RegExp('<parameterizedstring[^>]*>(.*?)</parameterizedstring>', dotAll: true, caseSensitive: false);
        
        for (var stepMatch in stepMatches) {
          final stepContent = stepMatch.group(1) ?? '';
          
          String? action;
          String? expectedResult;
          
          // Find all parameterizedstring tags in this step
          final paramMatches = allParamStrings.allMatches(stepContent);
          
          for (var paramMatch in paramMatches) {
            final fullTag = paramMatch.group(0) ?? '';
            final content = paramMatch.group(1)?.trim() ?? '';
            
            // Extract type attribute
            final typeMatch = RegExp('type\\s*=\\s*["\']?([^"\']+)["\']?', caseSensitive: false).firstMatch(fullTag);
            final type = typeMatch?.group(1)?.toLowerCase() ?? '';
            
            if (type.contains('action')) {
              action = content;
            } else if (type.contains('expected') || type.contains('result')) {
              expectedResult = content;
            }
          }
          
          // Decode HTML entities
          String decodedAction = (action ?? '').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&apos;', "'");
          String decodedExpectedResult = (expectedResult ?? '').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&apos;', "'");
          
          // Only add if we have at least action
          if (decodedAction.isNotEmpty || decodedExpectedResult.isNotEmpty) {
            _steps.add({
              'action': decodedAction,
              'expectedResult': decodedExpectedResult,
            });
            debugPrint('✅ [Steps] Added step ${_steps.length}: Action="${decodedAction.substring(0, decodedAction.length > 50 ? 50 : decodedAction.length)}...", ExpectedResult="${decodedExpectedResult.substring(0, decodedExpectedResult.length > 50 ? 50 : decodedExpectedResult.length)}..."');
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
      for (int i = 0; i < _steps.length; i++) {
        final action = _steps[i]['action'] ?? '';
        final expectedResult = _steps[i]['expectedResult'] ?? '';
        final actionPreview = action.length > 100 ? '${action.substring(0, 100)}...' : action;
        final expectedResultPreview = expectedResult.length > 100 ? '${expectedResult.substring(0, 100)}...' : expectedResult;
        debugPrint('  Step ${i + 1}: Action length=${action.length}, ExpectedResult length=${expectedResult.length}');
        if (action.isNotEmpty) {
          debugPrint('    Action: "$actionPreview"');
        }
        if (expectedResult.isNotEmpty) {
          debugPrint('    ExpectedResult: "$expectedResultPreview"');
        }
      }
    } catch (e) {
      debugPrint('❌ [Steps] Error parsing Steps: $e');
      // If parsing fails, show as single text field with HTML
      _steps = [{
        'action': stepsHtml.trim(), // Keep HTML
        'expectedResult': '',
      }];
    }
  }
  */
  
}
