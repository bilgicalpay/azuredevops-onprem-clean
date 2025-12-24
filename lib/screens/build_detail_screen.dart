/// Build detay ekranı
/// 
/// Build detaylarını gösterir ve build başlat/durdur işlemlerini yönetir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/build_service.dart';

class BuildDetailScreen extends StatefulWidget {
  final Build build;
  final String project;

  const BuildDetailScreen({
    super.key,
    required this.build,
    required this.project,
  });

  @override
  State<BuildDetailScreen> createState() => _BuildDetailScreenState();
}

class _BuildDetailScreenState extends State<BuildDetailScreen> {
  final BuildService _buildService = BuildService();
  Build? _buildDetail;
  Map<String, dynamic>? _timeline;
  bool _isLoading = true;
  bool _isLoadingTimeline = false;
  bool _isActionInProgress = false;
  Map<int, String?> _logsCache = {}; // logId -> logs
  Map<int, bool> _loadingLogs = {}; // logId -> isLoading

  @override
  void initState() {
    super.initState();
    _loadBuildDetail();
  }

  Future<void> _loadBuildDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final buildDetail = await _buildService.getBuildDetail(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        buildId: widget.build.id,
        collection: collection,
      );

      debugPrint('📦 [BuildDetailScreen] Build detail received: ${buildDetail?.buildNumber ?? 'null'}');
      debugPrint('📦 [BuildDetailScreen] Original build: ${widget.build.buildNumber}');

      setState(() {
        _buildDetail = buildDetail ?? widget.build;
        _isLoading = false;
      });

      // Load timeline if build is in progress
      if ((buildDetail ?? widget.build).status == 'inProgress' || 
          (buildDetail ?? widget.build).status == 'notStarted') {
        _loadTimeline();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [BuildDetailScreen] Error loading build detail: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeline() async {
    if (_buildDetail == null) return;

    setState(() {
      _isLoadingTimeline = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final timeline = await _buildService.getBuildTimeline(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        buildId: _buildDetail!.id,
        collection: collection,
      );

      setState(() {
        _timeline = timeline;
        _isLoadingTimeline = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTimeline = false;
      });
    }
  }

  Future<void> _runBuild() async {
    if (_buildDetail?.definitionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Build definition ID bulunamadı')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Build'),
        content: const Text('Bu build definition\'ı çalıştırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çalıştır'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final newBuild = await _buildService.queueBuild(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        definitionId: _buildDetail!.definitionId!,
        collection: collection,
      );

      setState(() {
        _isActionInProgress = false;
      });

      if (newBuild != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Build #${newBuild.buildNumber} başlatıldı'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to new build detail
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BuildDetailScreen(
                build: newBuild,
                project: widget.project,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Build başlatılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isActionInProgress = false;
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

  Future<void> _cancelBuild() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Build'),
        content: const Text('Bu build\'i iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final success = await _buildService.cancelBuild(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        buildId: widget.build.id,
        collection: collection,
      );

      setState(() {
        _isActionInProgress = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Build iptal edildi'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadBuildDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Build iptal edilemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isActionInProgress = false;
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

  Color _getStatusColor(String? status, String? result) {
    if (result == 'succeeded') return Colors.green;
    if (result == 'failed') return Colors.red;
    if (result == 'canceled') return Colors.grey;
    if (status == 'inProgress') return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    final build = _buildDetail ?? widget.build;
    final statusColor = _getStatusColor(build.status, build.result);
    final canCancel = build.status == 'inProgress' || build.status == 'notStarted';
    final canRun = build.status != 'inProgress' && build.definitionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Build #${build.buildNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildDetail,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32.0, // Account for padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Status card
                  Card(
                    color: statusColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.build, color: statusColor, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  build.buildNumber,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                if (build.status != null)
                                  Text(
                                    'Status: ${build.status}',
                                    style: TextStyle(color: statusColor),
                                  ),
                                if (build.result != null)
                                  Text(
                                    'Result: ${build.result}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow('Build Number', build.buildNumber),
                          _buildDetailRow('Build ID', build.id.toString()),
                          if (build.definitionName != null)
                            _buildDetailRow('Definition', build.definitionName!)
                          else if (build.definitionId != null)
                            _buildDetailRow('Definition ID', build.definitionId.toString()),
                          if (build.projectName != null)
                            _buildDetailRow('Project', build.projectName!)
                          else
                            _buildDetailRow('Project', widget.project),
                          if (build.status != null)
                            _buildDetailRow('Status', build.status!),
                          if (build.result != null)
                            _buildDetailRow('Result', build.result!),
                          if (build.requestedBy != null)
                            _buildDetailRow('Requested By', build.requestedBy!)
                          else
                            _buildDetailRow('Requested By', 'Unknown'),
                          if (build.queueTime != null)
                            _buildDetailRow('Queue Time', dateFormat.format(build.queueTime!))
                          else
                            _buildDetailRow('Queue Time', 'Not available'),
                          if (build.startTime != null)
                            _buildDetailRow('Start Time', dateFormat.format(build.startTime!))
                          else
                            _buildDetailRow('Start Time', 'Not started'),
                          if (build.finishTime != null)
                            _buildDetailRow('Finish Time', dateFormat.format(build.finishTime!))
                          else
                            _buildDetailRow('Finish Time', 'Not finished'),
                          if (build.url != null)
                            _buildDetailRow('URL', build.url!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline (Stages and Jobs)
                  if (_buildDetail != null && (_buildDetail!.status == 'inProgress' || _buildDetail!.status == 'notStarted'))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Timeline',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_isLoadingTimeline)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadTimeline,
                                    tooltip: 'Yenile',
                                  ),
                              ],
                            ),
                            const Divider(),
                            if (_isLoadingTimeline)
                              const Center(child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ))
                            else if (_timeline != null && _timeline!['records'] != null)
                              ...(_buildTimelineView(_timeline!['records'] as List))
                            else
                              const Text('Timeline bilgisi bulunamadı'),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Actions
                  if (canCancel || canRun)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            if (canRun) ...[
                              ElevatedButton.icon(
                                onPressed: _isActionInProgress ? null : _runBuild,
                                icon: _isActionInProgress
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Run Build'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (canCancel)
                              ElevatedButton.icon(
                                onPressed: _isActionInProgress ? null : _cancelBuild,
                                icon: _isActionInProgress
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cancel),
                                label: const Text('Cancel Build'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(16),
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
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogs(int logId, String recordName) async {
    if (_logsCache[logId] != null && _loadingLogs[logId] != true) {
      _displayLogsDialog(recordName, _logsCache[logId]!);
      return;
    }

    setState(() {
      _loadingLogs[logId] = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final logs = await _buildService.getBuildLog(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        buildId: _buildDetail!.id,
        logId: logId,
        collection: collection,
      );

      setState(() {
        _logsCache[logId] = logs ?? 'Logs not available';
        _loadingLogs[logId] = false;
      });

      if (mounted) {
        _displayLogsDialog(recordName, logs ?? 'Logs not available');
      }
    } catch (e) {
      setState(() {
        _loadingLogs[logId] = false;
      });
      if (mounted) {
        _displayLogsDialog(recordName, 'Error loading logs: $e');
      }
    }
  }

  void _displayLogsDialog(String recordName, String logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logs: $recordName'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              logs,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineView(List records) {
    final widgets = <Widget>[];
    
    for (final record in records) {
      final name = record['name'] as String? ?? 'Unknown';
      final type = record['type'] as String? ?? 'unknown';
      final state = record['state'] as String? ?? 'unknown';
      final logId = record['log']?['id'] as int?;
      
      Color stateColor;
      IconData stateIcon;
      
      switch (state.toLowerCase()) {
        case 'completed':
          stateColor = Colors.green;
          stateIcon = Icons.check_circle;
          break;
        case 'inprogress':
          stateColor = Colors.orange;
          stateIcon = Icons.hourglass_empty;
          break;
        case 'pending':
          stateColor = Colors.blue;
          stateIcon = Icons.pending;
          break;
        case 'failed':
        case 'skipped':
          stateColor = Colors.red;
          stateIcon = Icons.error;
          break;
        default:
          stateColor = Colors.grey;
          stateIcon = Icons.help_outline;
      }
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(stateIcon, color: stateColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
                    ),
                    Text(
                      'Type: $type | State: $state',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (logId != null)
                IconButton(
                  icon: Icon(
                    Icons.description,
                    size: 20,
                    color: _loadingLogs[logId] == true 
                        ? Colors.grey 
                        : Colors.blue,
                  ),
                  onPressed: _loadingLogs[logId] == true 
                      ? null 
                      : () => _showLogs(logId, name),
                  tooltip: 'View Logs',
                ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
}

