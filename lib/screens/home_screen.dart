/// Ana ekran
/// 
/// Kullanıcıya atanan work item'ları listeler ve wiki içeriğini gösterir.
/// Work item'ları görüntüleme, detay sayfasına gitme ve yenileme işlemlerini yönetir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/work_item_service.dart';
import '../services/realtime_service.dart';
import '../services/background_task_service.dart';
import '../services/background_worker_service.dart';
import '../services/wiki_service.dart';
import '../services/auto_logout_service.dart';
import 'work_item_detail_screen.dart';
import 'queries_screen.dart';
import 'settings_screen.dart';
import 'wiki_viewer_screen.dart';
import 'documents_screen.dart';
import 'market_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/turkish_culture_service.dart';

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
  bool _showCulturePopup = false;
  Map<String, String>? _cultureInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppVersion();
    _loadWorkItems();
    _loadWikiContent();
    _startRealtimeService();
    // Ensure background task service is running and initialized
    _initializeBackgroundService();
    // Update activity timestamp on app start
    _updateActivity();
  }
  
  void _updateActivity() {
    final storage = Provider.of<StorageService>(context, listen: false);
    AutoLogoutService.updateActivity(storage);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _initializeBackgroundService() async {
    print('🚀 [HomeScreen] Initializing background service...');
    // Initialize tracking first
    await BackgroundTaskService().initializeTracking();
    // Then start the service
    await BackgroundTaskService().start();
    print('✅ [HomeScreen] Background service initialized and started');
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh data and restart services
      print('🔄 [HomeScreen] App resumed, refreshing and restarting services...');
      // Update activity timestamp
      _updateActivity();
      _loadWorkItems();
      // Restart realtime service to ensure it's running
      _startRealtimeService();
      // Ensure background service is running
      BackgroundTaskService().start();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - ensure services keep running
      print('🔄 [HomeScreen] App went to background, ensuring services continue...');
      // Restart realtime service to ensure it continues in background
      _startRealtimeService();
      BackgroundTaskService().start();
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated - services will continue if started
      print('⚠️ [HomeScreen] App detached, services should continue');
    }
  }

  void _startRealtimeService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    
    print('🚀 [HomeScreen] Starting realtime service...');
    final token = await authService.getAuthToken();
    print('🔍 [HomeScreen] Auth check - serverUrl: ${authService.serverUrl != null ? "✓" : "✗"}, token: ${token != null ? "✓" : "✗"}');
    
    // Ensure we have auth before starting
    if (authService.serverUrl == null || token == null) {
      print('❌ [HomeScreen] Cannot start realtime service: missing auth data');
      return;
    }
    
    // Start real-time service (direct polling, no WebSocket)
    // Polling interval: 30 seconds for faster updates
    RealtimeService().start(
      authService: authService,
      storageService: storage,
      onNewWorkItems: (changedIds) {
        // Refresh work items when changes are detected
        print('🔄 [HomeScreen] Work items changed callback triggered! (${changedIds.length} items)');
        if (mounted) {
          print('✅ [HomeScreen] Widget is mounted, refreshing list...');
          // Force immediate refresh
          _loadWorkItems().then((_) {
            print('✅ [HomeScreen] Work items list refreshed successfully');
            if (mounted && changedIds.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${changedIds.length} work item güncellendi'),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Yenile',
                    onPressed: () {
                      _loadWorkItems();
                    },
                  ),
                ),
              );
            }
          }).catchError((error) {
            print('❌ [HomeScreen] Error refreshing work items: $error');
          });
        } else {
          print('⚠️ [HomeScreen] Widget not mounted, skipping refresh');
        }
      },
      onError: (error) {
        print('❌ [HomeScreen] Realtime service error: $error');
        // Don't show error to user - service will retry automatically
      },
      onConnected: () {
        print('✅ [HomeScreen] Realtime service connected and polling started');
      },
      onDisconnected: () {
        print('⚠️ [HomeScreen] Realtime service disconnected');
        // Service will automatically reconnect
      },
    );
  }

  Future<void> _loadWorkItems() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await authService.getAuthToken();
    if (token == null || authService.serverUrl == null) {
      setState(() => _isLoading = false);
      return;
    }
    final workItems = await _workItemService.getWorkItems(
      serverUrl: authService.serverUrl!,
      token: token,
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
      final token = await authService.getAuthToken();
      if (token == null) {
        setState(() => _isLoadingWiki = false);
        return;
      }
      final content = await _wikiService.fetchWikiContent(
        wikiUrl: wikiUrl,
        token: token,
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180), // AppBar için daha fazla yükseklik
        child: SafeArea(
          child: AppBar(
            toolbarHeight: 180,
            title: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: Logo, AzureDevOps yazısı ve versiyon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 28,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AzureDevOps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_appVersion.isNotEmpty)
                        Text(
                          _appVersion,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Alt satır: Menüler
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  IconButton(
                    icon: const Icon(Icons.query_stats),
                    color: Colors.blue.shade900,
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
                    color: Colors.blue.shade900,
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
                    icon: const Icon(Icons.store),
                    color: Colors.blue.shade900,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketScreen(),
                        ),
                      );
                    },
                    tooltip: 'Market',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: Colors.blue.shade900,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ).then((_) async {
                        // Reload wiki content when returning from settings
                        _loadWikiContent();
                        // Restart realtime service with new polling interval if changed
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final storage = Provider.of<StorageService>(context, listen: false);
                        await RealtimeService().restartPolling(authService, storage);
                        // Restart background service
                        BackgroundTaskService().stop();
                        await BackgroundTaskService().start();
                        // Restart background worker service with new interval
                        await BackgroundWorkerService.stop();
                        await BackgroundWorkerService.start();
                      });
                    },
                    tooltip: 'Ayarlar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Colors.blue.shade900,
                    onPressed: () {
                      _loadWorkItems();
                      _loadWikiContent();
                    },
                    tooltip: 'Yenile',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    color: Colors.blue.shade900,
                    onPressed: () async {
                      await authService.logout();
                    },
                    tooltip: 'Çıkış',
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
        actions: [
          // Versiyon bilgisi en sağda, üstte
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
              child: Center(
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
        centerTitle: false,
        automaticallyImplyLeading: false,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadWorkItems();
              await _loadWikiContent();
              // Show Turkish culture popup on refresh
              _showTurkishCulturePopup();
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
                                                        ? 'URL: ${wikiUrl.length > 50 ? "${wikiUrl.substring(0, 50)}..." : wikiUrl}'
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
          // Turkish Culture Popup
          if (_showCulturePopup && _cultureInfo != null)
            _buildCulturePopup(),
        ],
      ),
    );
  }

  /// Show Turkish culture popup
  void _showTurkishCulturePopup() {
    final info = TurkishCultureService.getRandomInfo();
    // Ensure content is max 250 characters
    String content = info['content']!;
    if (content.length > 250) {
      content = content.substring(0, 247) + '...';
    }
    
    setState(() {
      _cultureInfo = {
        'title': info['title']!,
        'content': content,
        'type': info['type']!,
      };
      _showCulturePopup = true;
    });
  }

  /// Build Turkish culture popup widget
  Widget _buildCulturePopup() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _cultureInfo!['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showCulturePopup = false;
                          _cultureInfo = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content
                Text(
                  _cultureInfo!['content']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                // Footer
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showCulturePopup = false;
                        _cultureInfo = null;
                      });
                    },
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

