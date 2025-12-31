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
import 'package:url_launcher/url_launcher.dart';
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
import 'boards_screen.dart';
import 'builds_screen.dart';
import 'releases_screen.dart';
import 'work_items_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _workItemsKey = GlobalKey();

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
    _scrollController.dispose();
    // Don't stop services on dispose - let them run in background
    super.dispose();
  }


  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Stack(
                    children: [
                      Icon(
                        icon,
                        size: 40,
                        color: color,
                      ),
                      if (badge != null)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              badge > 99 ? '99+' : badge.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
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
              // Üst satır: Sol tarafta Logo + AzureDevOps, Sağ tarafta Vakıf Katılım
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sol taraf: AzureDevOps (logo kaldırıldı)
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse('https://github.com/bilgicalpay/azuredevops-server-mobile');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AzureDevOps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_appVersion.isNotEmpty)
                            Text(
                              _appVersion,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Sağ taraf: Şirket adı ve logo - dinamik olarak domain'den veya ayarlardan
                  Expanded(
                    child: Consumer<StorageService>(
                      builder: (context, storage, _) {
                        final companyName = storage.getDisplayCompanyName();
                        final logoMode = storage.getLogoDisplayMode();
                        final customLogoUrl = storage.getCompanyLogoUrl();
                        
                        // Logo gösterimi kapalıysa boş döndür
                        if (logoMode == 'none' || companyName.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo - özel URL varsa network image, yoksa ikon
                            if (customLogoUrl != null && customLogoUrl.isNotEmpty)
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Image.network(
                                  customLogoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 20,
                                      color: Colors.blue.shade900,
                                    );
                                  },
                                ),
                              )
                            else
                              Icon(
                                Icons.business,
                                size: 20,
                                color: Colors.blue.shade900,
                              ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                companyName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Alt satır: Menüler - ScrollableRow ile overflow önleniyor
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
              ),
            ],
          ),
        ),
        actions: const [],
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
            },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 5 Grid Kutusu: Boards, Work Items, Builds, Releases, CAB
              Container(
                margin: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    // 1. Boards
                    _buildGridCard(
                      context: context,
                      title: 'Boards',
                      icon: Icons.dashboard,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BoardsScreen(),
                          ),
                        );
                      },
                    ),
                    // 2. Work Items
                    _buildGridCard(
                      context: context,
                      title: 'Work Items',
                      icon: Icons.assignment,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkItemsScreen(),
                          ),
                        );
                      },
                      badge: _workItems.isNotEmpty ? _workItems.length : null,
                    ),
                    // 3. Builds
                    _buildGridCard(
                      context: context,
                      title: 'Builds',
                      icon: Icons.build,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuildsScreen(),
                          ),
                        );
                      },
                    ),
                    // 4. Releases
                    _buildGridCard(
                      context: context,
                      title: 'Releases',
                      icon: Icons.rocket_launch,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReleasesScreen(),
                          ),
                        );
                      },
                    ),
                    // 5. CAB (Wiki)
                    _buildGridCard(
                      context: context,
                      title: 'CAB',
                      icon: Icons.info_outline,
                      color: Colors.teal,
                      onTap: () {
                        if (_wikiContent != null && _wikiContent!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WikiViewerScreen(
                                wikiContent: _wikiContent!,
                                wikiTitle: 'Wiki',
                              ),
                            ),
                          );
                        } else {
                          // Wiki yükleniyorsa veya yoksa hata mesajı göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Wiki içeriği yüklenemedi veya ayarlanmamış'),
                              action: SnackBarAction(
                                label: 'Yenile',
                                onPressed: _loadWikiContent,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Alt Bölüm: Work Items
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _workItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Work item bulunamadı'),
                            ),
                          )
                        : ListView.builder(
                            key: _workItemsKey,
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}

