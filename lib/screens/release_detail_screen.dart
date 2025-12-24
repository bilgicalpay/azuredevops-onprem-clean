/// Release detay ekranı
/// 
/// Release detaylarını gösterir ve release başlat/durdur işlemlerini yönetir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/release_service.dart';

class ReleaseDetailScreen extends StatefulWidget {
  final Release release;
  final String project;

  const ReleaseDetailScreen({
    super.key,
    required this.release,
    required this.project,
  });

  @override
  State<ReleaseDetailScreen> createState() => _ReleaseDetailScreenState();
}

class _ReleaseDetailScreenState extends State<ReleaseDetailScreen> {
  final ReleaseService _releaseService = ReleaseService();
  Release? _releaseDetail;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  Map<int, String?> _logsCache = {}; // environmentId -> logs
  Map<int, bool> _loadingLogs = {}; // environmentId -> isLoading

  @override
  void initState() {
    super.initState();
    _loadReleaseDetail();
  }

  Future<void> _loadReleaseDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final releaseDetail = await _releaseService.getReleaseDetail(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        releaseId: widget.release.id,
        collection: collection,
      );

      setState(() {
        _releaseDetail = releaseDetail ?? widget.release;
        _isLoading = false;
        // Clear logs cache when release detail is refreshed
        _logsCache.clear();
        _loadingLogs.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeployOptions() async {
    final release = _releaseDetail ?? widget.release;
    final deployableEnvs = release.environments
        .where((env) => env.status != 'inProgress' && 
                       env.status != 'succeeded' && 
                       env.status != 'failed' &&
                       env.status != 'canceled')
        .toList();

    if (deployableEnvs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deploy edilebilir environment bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deploy Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Deploy Multiple'),
              subtitle: const Text('Tüm deploy edilebilir environment\'lara deploy et'),
              onTap: () => Navigator.pop(context, 'multiple'),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Deploy Stage'),
              subtitle: const Text('Belirli environment seçerek deploy et'),
              onTap: () => Navigator.pop(context, 'stage'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (result == 'multiple') {
      _deployMultiple(release);
    } else if (result == 'stage') {
      _showStageSelection(deployableEnvs);
    }
  }

  Future<void> _deployMultiple(Release release) async {
    final deployableEnvs = release.environments
        .where((env) => env.status != 'inProgress' && 
                       env.status != 'succeeded')
        .toList();

    setState(() {
      _isActionInProgress = true;
    });

    int successCount = 0;
    int failCount = 0;

    for (final env in deployableEnvs) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final storage = Provider.of<StorageService>(context, listen: false);
        
        final serverUrl = authService.serverUrl!;
        final token = await authService.getAuthToken();
        final collection = storage.getCollection();

        final success = await _releaseService.deployRelease(
          serverUrl: serverUrl,
          token: token!,
          project: widget.project,
          releaseId: release.id,
          environmentId: env.id,
          collection: collection,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    setState(() {
      _isActionInProgress = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount başarılı, $failCount başarısız'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      _loadReleaseDetail();
    }
  }

  Future<void> _showStageSelection(List<ReleaseEnvironment> environments) async {
    final selectedEnv = await showDialog<ReleaseEnvironment>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deploy Stage'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: environments.length,
            itemBuilder: (context, index) {
              final env = environments[index];
              return ListTile(
                leading: Icon(Icons.cloud, color: _getStatusColor(env.status)),
                title: Text(env.name),
                subtitle: env.status != null ? Text('Status: ${env.status}') : null,
                onTap: () => Navigator.pop(context, env),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (selectedEnv != null) {
      _deployRelease(selectedEnv.id);
    }
  }

  Future<void> _showLogs(int environmentId, String environmentName) async {
    if (_logsCache[environmentId] != null && _loadingLogs[environmentId] != true) {
      _displayLogsDialog(environmentName, _logsCache[environmentId]!);
      return;
    }

    setState(() {
      _loadingLogs[environmentId] = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final logs = await _releaseService.getReleaseLogs(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        releaseId: widget.release.id,
        environmentId: environmentId,
        collection: collection,
      );

      setState(() {
        _logsCache[environmentId] = logs ?? 'Logs not available';
        _loadingLogs[environmentId] = false;
      });

      if (mounted) {
        _displayLogsDialog(environmentName, logs ?? 'Logs not available');
      }
    } catch (e) {
      setState(() {
        _loadingLogs[environmentId] = false;
      });
      if (mounted) {
        _displayLogsDialog(environmentName, 'Error loading logs: $e');
      }
    }
  }

  void _displayLogsDialog(String environmentName, String logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logs: $environmentName'),
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

  Future<void> _deployRelease(int environmentId) async {
    setState(() {
      _isActionInProgress = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final serverUrl = authService.serverUrl!;
      final token = await authService.getAuthToken();
      final collection = storage.getCollection();

      final success = await _releaseService.deployRelease(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        releaseId: widget.release.id,
        environmentId: environmentId,
        collection: collection,
      );

      setState(() {
        _isActionInProgress = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release deploy edildi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReleaseDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release deploy edilemedi'),
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

  Future<void> _cancelRelease(int environmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Release'),
        content: const Text('Bu release deployment\'ını iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Evet, İptal Et'),
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

      final success = await _releaseService.cancelRelease(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        releaseId: widget.release.id,
        environmentId: environmentId,
        collection: collection,
      );

      setState(() {
        _isActionInProgress = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release deployment iptal edildi'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadReleaseDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release deployment iptal edilemedi'),
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

  Future<void> _abandonRelease() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Release'),
        content: const Text('Bu release\'i iptal etmek istediğinizden emin misiniz?'),
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

      final success = await _releaseService.abandonRelease(
        serverUrl: serverUrl,
        token: token!,
        project: widget.project,
        releaseId: widget.release.id,
        collection: collection,
      );

      setState(() {
        _isActionInProgress = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release iptal edildi'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadReleaseDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Release iptal edilemedi'),
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'succeeded':
      case 'active':
        return Colors.green;
      case 'failed':
      case 'rejected':
        return Colors.red;
      case 'canceled':
      case 'abandoned':
        return Colors.grey;
      case 'inprogress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    final release = _releaseDetail ?? widget.release;
    final statusColor = _getStatusColor(release.status);
    final canAbandon = release.status != 'abandoned' && 
                       release.status != 'succeeded' && 
                       release.status != 'failed';

    return Scaffold(
      appBar: AppBar(
        title: Text('Release: ${release.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReleaseDetail,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                          Icon(Icons.rocket_launch, color: statusColor, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  release.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                if (release.status != null)
                                  Text(
                                    'Status: ${release.status}',
                                    style: TextStyle(color: statusColor),
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
                          if (release.releaseDefinitionName != null)
                            _buildDetailRow('Definition', release.releaseDefinitionName!),
                          if (release.projectName != null)
                            _buildDetailRow('Project', release.projectName!),
                          if (release.createdBy != null)
                            _buildDetailRow('Created By', release.createdBy!),
                          if (release.createdOn != null)
                            _buildDetailRow('Created On', dateFormat.format(release.createdOn!)),
                          if (release.modifiedOn != null)
                            _buildDetailRow('Modified On', dateFormat.format(release.modifiedOn!)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Environments
                  if (release.environments.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Environments',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (release.environments.any((env) => 
                                    env.status != 'inProgress' && 
                                    env.status != 'succeeded' && 
                                    env.status != 'failed' &&
                                    env.status != 'canceled'))
                                  TextButton.icon(
                                    onPressed: _isActionInProgress ? null : _showDeployOptions,
                                    icon: const Icon(Icons.play_circle_outline),
                                    label: const Text('Deploy Options'),
                                  ),
                              ],
                            ),
                            const Divider(),
                            ...release.environments.map((env) {
                              final envColor = _getStatusColor(env.status);
                              // Deploy can be done if environment is not currently in progress
                              // Canceled, rejected, or not started environments can be deployed
                              final canDeploy = env.status != 'inProgress' && 
                                                env.status != 'succeeded';
                              final canCancel = env.status == 'inProgress' || 
                                                env.status == 'queued';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.cloud, color: envColor, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            env.name,
                                            style: TextStyle(
                                              color: envColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (env.status != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${env.status})',
                                            style: TextStyle(
                                              color: envColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                        IconButton(
                                          icon: Icon(
                                            Icons.description,
                                            size: 20,
                                            color: _loadingLogs[env.id] == true 
                                                ? Colors.grey 
                                                : Colors.blue,
                                          ),
                                          onPressed: _loadingLogs[env.id] == true 
                                              ? null 
                                              : () => _showLogs(env.id, env.name),
                                          tooltip: 'View Logs',
                                        ),
                                      ],
                                    ),
                                    if (canDeploy || canCancel) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (canDeploy)
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _isActionInProgress 
                                                    ? null 
                                                    : () => _deployRelease(env.id),
                                                icon: _isActionInProgress
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.play_arrow, size: 18),
                                                label: const Text('Deploy'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                ),
                                              ),
                                            ),
                                          if (canDeploy && canCancel) const SizedBox(width: 8),
                                          if (canCancel)
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _isActionInProgress 
                                                    ? null 
                                                    : () => _cancelRelease(env.id),
                                                icon: _isActionInProgress
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.stop, size: 18),
                                                label: const Text('Cancel'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Actions
                  if (canAbandon)
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
                            ElevatedButton.icon(
                              onPressed: _isActionInProgress ? null : _abandonRelease,
                              icon: _isActionInProgress
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.cancel),
                              label: const Text('Abandon Release'),
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
}

