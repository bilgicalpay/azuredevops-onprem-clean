/// Ana ekran
/// 
/// Kullanıcıya atanan work item'ları listeler ve wiki içeriğini gösterir.
/// Work item'ları görüntüleme, detay sayfasına gitme ve yenileme işlemlerini yönetir.
/// 
/// @author Alpay Bilgiç

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import '../services/realtime_service.dart';
import '../services/background_task_service.dart';
import '../services/wiki_service.dart';
import 'work_item_detail_screen.dart';
import 'queries_screen.dart';
import 'settings_screen.dart';
import 'wiki_viewer_screen.dart';
import 'documents_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Ana ekran widget'ı
/// Work item listesi ve wiki içeriğini gösterir
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final WorkItemService _workItemService = WorkItemService();
  final WikiService _wikiService = WikiService();
  final List<WorkItem> _workItems = [];
  bool _isLoading = true;
  String? _wikiContent;
  bool _isLoadingWiki = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppVersion();
    _loadWorkItems();
    _loadWikiContent();
    _startRealtimeService();
    // Ensure background task service is running
    BackgroundTaskService().start();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't stop services on dispose - let them run in background
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh data
      _loadWorkItems();
      // Ensure background service is running
      BackgroundTaskService().start();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - ensure services keep running
      print('App went to background, services should continue');
      BackgroundTaskService().start();
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated - services will continue if started
      print('App detached, background services should continue');
    }
  }

  void _startRealtimeService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    
    // Start real-time service (WebSocket with polling fallback)
    // Polling interval: 1 minute for faster updates
    RealtimeService().start(
      authService: authService,
      storageService: storage,
      onNewWorkItems: (changedIds) {
        // Refresh work items when changes are detected
        print('🔄 [HomeScreen] Work items changed, refreshing list... (${changedIds.length} items)');
        if (mounted) {
          // Force immediate refresh
          _loadWorkItems().then((_) {
            if (mounted && changedIds.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${changedIds.length} work item güncellendi'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Yenile',
                    onPressed: _loadWorkItems,
                  ),
                ),
              );
            }
          });
        }
      },
      onError: (error) {
        print('Realtime service error: $error');
        // Don't show error to user - service will retry automatically
      },
      onConnected: () {
        print('Realtime service connected');
      },
      onDisconnected: () {
        print('Realtime service disconnected');
        // Service will automatically reconnect
      },
    );
  }

  Future<void> _loadWorkItems() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final workItems = await _workItemService.getWorkItems(
      serverUrl: authService.serverUrl!,
      token: authService.token!,
      collection: storage.getCollection(),
    );
    
    setState(() {
      _workItems.clear();
      _workItems.addAll(workItems);
      _isLoading = false;
    });
  }

  Future<void> _loadWikiContent() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final wikiUrl = storage.getWikiUrl();
    if (wikiUrl == null || wikiUrl.isEmpty) {
      setState(() {
        _wikiContent = null;
      });
      return;
    }

    setState(() => _isLoadingWiki = true);
    
    try {
      final content = await _wikiService.fetchWikiContent(
        wikiUrl: wikiUrl,
        token: authService.token!,
        serverUrl: authService.serverUrl,
        collection: storage.getCollection(),
      );
      
      setState(() {
        _wikiContent = content;
        _isLoadingWiki = false;
      });
    } catch (e) {
      setState(() {
        _wikiContent = null;
        _isLoadingWiki = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AzureDevOps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Version display in top right
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: Center(
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.query_stats),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QueriesScreen(),
                ),
              );
            },
            tooltip: 'My Queries',
          ),
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentsScreen(),
                ),
              );
            },
            tooltip: 'Belgeler',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) {
                // Reload wiki content when returning from settings
                _loadWikiContent();
              });
            },
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadWorkItems();
              _loadWikiContent();
            },
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
            tooltip: 'Çıkış',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadWorkItems();
          await _loadWikiContent();
        },
        child: Column(
          children: [
            // Üst Bölüm: Wiki
            if (_wikiContent != null || _isLoadingWiki)
              Container(
                margin: const EdgeInsets.all(16.0),
                child: Card(
                  child: InkWell(
                    onTap: _wikiContent != null && _wikiContent!.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WikiViewerScreen(
                                  wikiContent: _wikiContent!,
                                  wikiTitle: 'Wiki',
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Wiki',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_wikiContent != null && _wikiContent!.isNotEmpty)
                                const Icon(Icons.open_in_full, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _loadWikiContent,
                                tooltip: 'Wiki\'yi Yenile',
                              ),
                            ],
                          ),
                          const Divider(),
                          SizedBox(
                            height: 150,
                            child: _isLoadingWiki
                                ? const Center(child: CircularProgressIndicator())
                                : _wikiContent != null && _wikiContent!.isNotEmpty
                                    ? SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: MarkdownBody(
                                          data: _wikiContent!.length > 500 
                                              ? '${_wikiContent!.substring(0, 500)}...\n\n**[Tamamını görmek için tıklayın]**'
                                              : _wikiContent!,
                                          styleSheet: MarkdownStyleSheet(
                                            p: const TextStyle(fontSize: 12),
                                            h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            code: TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              backgroundColor: Colors.grey.shade200,
                                            ),
                                            a: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                          ),
                                        ),
                                      )
                                    : Builder(
                                        builder: (context) {
                                          final storage = Provider.of<StorageService>(context, listen: false);
                                          final wikiUrl = storage.getWikiUrl();
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.info_outline, color: Colors.grey, size: 32),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Wiki içeriği yüklenemedi',
                                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    wikiUrl != null && wikiUrl.isNotEmpty
                                                        ? 'URL: ${wikiUrl.length > 50 ? wikiUrl.substring(0, 50) + "..." : wikiUrl}'
                                                        : 'Wiki URL\'si ayarlanmamış',
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Alt Bölüm: Work Items
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _workItems.isEmpty
                      ? const Center(
                          child: Text('Work item bulunamadı'),
                        )
                      : ListView.builder(
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
                                title: Text(item.title),
                                subtitle: Text('${item.type} - ${item.state}'),
                                trailing: item.assignedTo != null
                                    ? Chip(
                                        label: Text(item.assignedTo!),
                                        avatar: const Icon(Icons.person, size: 16),
                                      )
                                    : null,
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
          ],
        ),
      ),
    );
  }

}

