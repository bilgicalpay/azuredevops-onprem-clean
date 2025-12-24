/// Create Work Item ekranı
/// 
/// Yeni work item oluşturma formu.
/// Proje seçimi, work item type seçimi ve custom fields doldurma.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';

class CreateWorkItemScreen extends StatefulWidget {
  const CreateWorkItemScreen({super.key});

  @override
  State<CreateWorkItemScreen> createState() => _CreateWorkItemScreenState();
}

class _CreateWorkItemScreenState extends State<CreateWorkItemScreen> {
  final WorkItemService _workItemService = WorkItemService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _projects = [];
  List<String> _workItemTypes = [];
  Map<String, FieldDefinition> _fieldDefinitions = {};
  Map<String, dynamic> _fieldValues = {};

  String? _selectedProject;
  String? _selectedWorkItemType;
  bool _isLoadingProjects = true;
  bool _isLoadingTypes = false;
  bool _isLoadingFields = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
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
      
      final dio = _workItemService.dio;
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_workItemService.encodeToken(token!)}',
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
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _loadWorkItemTypes(String project) async {
    setState(() {
      _isLoadingTypes = true;
      _selectedWorkItemType = null;
      _fieldDefinitions = {};
      _fieldValues = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final types = await _workItemService.getWorkItemTypes(
        serverUrl: serverUrl,
        token: token!,
        project: project,
        collection: collection,
      );

      setState(() {
        _workItemTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadFieldDefinitions(String project, String workItemType) async {
    setState(() {
      _isLoadingFields = true;
      _fieldValues = {};
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final fields = await _workItemService.getWorkItemFieldDefinitions(
        serverUrl: serverUrl,
        token: token!,
        workItemType: workItemType,
        collection: collection,
        project: project,
      );

      setState(() {
        _fieldDefinitions = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFields = false;
      });
    }
  }

  Future<void> _createWorkItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProject == null || _selectedWorkItemType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen proje ve work item type seçin')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      // Prepare fields
      final fields = <String, dynamic>{
        'System.Title': _titleController.text,
        if (_descriptionController.text.isNotEmpty)
          'System.Description': _descriptionController.text,
        ..._fieldValues,
      };

      final workItem = await _workItemService.createWorkItem(
        serverUrl: serverUrl,
        token: token!,
        project: _selectedProject!,
        workItemType: _selectedWorkItemType!,
        fields: fields,
        collection: collection,
      );

      setState(() {
        _isCreating = false;
      });

      if (workItem != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work item #${workItem.id} oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work item oluşturulamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
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

  Widget _buildFieldInput(FieldDefinition field) {
    if (field.isHidden) {
      return const SizedBox.shrink();
    }

    switch (field.type.toLowerCase()) {
      case 'string':
      case 'html':
      case 'plaintext':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            _fieldValues[field.referenceName] = value;
          },
        );

      case 'integer':
      case 'double':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = num.tryParse(value);
            if (numValue != null) {
              _fieldValues[field.referenceName] = numValue;
            }
          },
        );

      case 'boolean':
        return CheckboxListTile(
          title: Text(field.name),
          value: _fieldValues[field.referenceName] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _fieldValues[field.referenceName] = value ?? false;
            });
          },
        );

      case 'dateTime':
        return ListTile(
          title: Text(field.name),
          subtitle: Text(
            _fieldValues[field.referenceName] != null
                ? _fieldValues[field.referenceName].toString()
                : 'Tarih seçin',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _fieldValues[field.referenceName] = date.toIso8601String();
              });
            }
          },
        );

      default:
        if (field.isComboBox && field.allowedValues.isNotEmpty) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: field.name,
              border: const OutlineInputBorder(),
            ),
            items: field.allowedValues.map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _fieldValues[field.referenceName] = value;
              });
            },
          );
        } else {
          return TextFormField(
            decoration: InputDecoration(
              labelText: field.name,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _fieldValues[field.referenceName] = value;
            },
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Work Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Project selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
              value: _selectedProject,
              items: _projects.map((project) {
                return DropdownMenuItem(
                  value: project['name'] as String,
                  child: Text(project['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProject = value;
                  _selectedWorkItemType = null;
                  _fieldDefinitions = {};
                  _fieldValues = {};
                });
                if (value != null) {
                  _loadWorkItemTypes(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Work Item Type selection
            if (_selectedProject != null) ...[
              if (_isLoadingTypes)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Work Item Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedWorkItemType,
                  items: _workItemTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWorkItemType = value;
                      _fieldDefinitions = {};
                      _fieldValues = {};
                    });
                    if (value != null) {
                      _loadFieldDefinitions(_selectedProject!, value);
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Title (required)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Custom fields
            if (_selectedWorkItemType != null) ...[
              if (_isLoadingFields)
                const Center(child: CircularProgressIndicator())
              else if (_fieldDefinitions.isNotEmpty) ...[
                const Text(
                  'Custom Fields',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._fieldDefinitions.values
                    .where((field) => 
                        field.referenceName != 'System.Title' &&
                        field.referenceName != 'System.Description')
                    .map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildFieldInput(field),
                        )),
              ],
            ],

            const SizedBox(height: 32),

            // Create button
            ElevatedButton(
              onPressed: _isCreating ? null : _createWorkItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Work Item'),
            ),
          ],
        ),
      ),
    );
  }
}

