/// Ayarlar ekranı
/// 
/// Uygulama ayarlarını yönetir. Wiki URL'si girişi ve
/// mevcut server bilgilerini gösterir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:azuredevops_onprem/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/wiki_service.dart';

/// Ayarlar ekranı widget'ı
/// Uygulama ayarlarını yönetir
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wikiUrlController = TextEditingController();
  final _pollingIntervalController = TextEditingController();
  final _marketRepoUrlController = TextEditingController();
  final _groupController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyLogoUrlController = TextEditingController();
  bool _isLoading = false;
  int _pollingInterval = 15;
  bool _notifyOnFirstAssignment = false;
  bool _notifyOnAllUpdates = false;
  bool _notifyOnHotfixOnly = false;
  bool _notifyOnGroupAssignments = false;
  List<String> _notificationGroups = [];
  bool _enableSmartwatchNotifications = false;
  bool _onCallModePhone = false;
  bool _onCallModeWatch = false;
  bool _vacationModePhone = false;
  bool _vacationModeWatch = false;
  String _logoDisplayMode = 'auto';
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _wikiUrlController.dispose();
    _pollingIntervalController.dispose();
    _marketRepoUrlController.dispose();
    _groupController.dispose();
    _companyNameController.dispose();
    _companyLogoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    // Demo için default değerler
    const String defaultWikiUrl = 'https://dev.azure.com/hygieia-devops/DevOps-Turkiye/_wiki/wikis/README.md/3/README';
    const String defaultMarketUrl = 'https://ftp.kaist.ac.kr/apache/';
    const String defaultServerUrl = 'https://dev.azure.com/hygieia-devops';
    const String defaultToken = 'AI9TJm5RCCifo7r0YeyoMAHZuXxuUS6vAQxQyVpRsklnr5C9wSx0JQQJ99BLACAAAAAAAAAAAAASAZDO1YxI';
    
    // Wiki URL - eğer storage'da yoksa default değeri kullan ve kaydet
    final wikiUrl = storage.getWikiUrl();
    if (wikiUrl == null || wikiUrl.isEmpty) {
      await storage.setWikiUrl(defaultWikiUrl);
      _wikiUrlController.text = defaultWikiUrl;
    } else {
      _wikiUrlController.text = wikiUrl;
    }
    
    // Market URL - eğer storage'da yoksa default değeri kullan ve kaydet
    final marketRepoUrl = storage.getMarketRepoUrl();
    if (marketRepoUrl == null || marketRepoUrl.isEmpty) {
      await storage.setMarketRepoUrl(defaultMarketUrl);
      _marketRepoUrlController.text = defaultMarketUrl;
    } else {
      _marketRepoUrlController.text = marketRepoUrl;
    }
    
    // Server URL ve Token - eğer storage'da yoksa default değerleri ayarla
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentServerUrl = authService.serverUrl;
    final currentToken = await storage.getToken();
    
    // Eğer server URL veya token yoksa, default değerleri ayarla
    if (currentServerUrl == null || currentToken == null) {
      // Default değerleri storage'a kaydet
      await storage.setServerUrl(defaultServerUrl);
      await storage.setToken(defaultToken);
      await storage.setAuthType('pat'); // PAT authentication
      
      // AuthService'i güncelle
      await authService.loginWithToken(
        serverUrl: defaultServerUrl,
        token: defaultToken,
      );
    }
    
    // Load polling interval
    final interval = await storage.getPollingInterval();
    
    // Load notification settings
    final notifyOnFirstAssignment = storage.getNotifyOnFirstAssignment();
    final notifyOnAllUpdates = storage.getNotifyOnAllUpdates();
    final notifyOnHotfixOnly = storage.getNotifyOnHotfixOnly();
    final notifyOnGroupAssignments = storage.getNotifyOnGroupAssignments();
    final notificationGroups = await storage.getNotificationGroups();
    
    // Load smartwatch and mode settings
    final enableSmartwatchNotifications = storage.getEnableSmartwatchNotifications();
    final onCallModePhone = storage.getOnCallModePhone();
    final onCallModeWatch = storage.getOnCallModeWatch();
    final vacationModePhone = storage.getVacationModePhone();
    final vacationModeWatch = storage.getVacationModeWatch();
    
    // Load company/logo settings
    final logoDisplayMode = storage.getLogoDisplayMode();
    final companyName = storage.getCompanyName() ?? '';
    final companyLogoUrl = storage.getCompanyLogoUrl() ?? '';
    
    setState(() {
      _pollingInterval = interval;
      _pollingIntervalController.text = interval.toString();
      _notifyOnFirstAssignment = notifyOnFirstAssignment;
      _notifyOnAllUpdates = notifyOnAllUpdates;
      _notifyOnHotfixOnly = notifyOnHotfixOnly;
      _notifyOnGroupAssignments = notifyOnGroupAssignments;
      _notificationGroups = notificationGroups;
      _enableSmartwatchNotifications = enableSmartwatchNotifications;
      _onCallModePhone = onCallModePhone;
      _onCallModeWatch = onCallModeWatch;
      _vacationModePhone = vacationModePhone;
      _vacationModeWatch = vacationModeWatch;
      _logoDisplayMode = logoDisplayMode;
      _companyNameController.text = companyName;
      _companyLogoUrlController.text = companyLogoUrl;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    final storage = Provider.of<StorageService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final wikiUrl = _wikiUrlController.text.trim();
    
    if (wikiUrl.isNotEmpty) {
      // Validate URL
      final uri = Uri.tryParse(wikiUrl);
      if (uri == null || !uri.hasScheme) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidUrl),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }
    
    // Validate and save polling interval
    final intervalText = _pollingIntervalController.text.trim();
    if (intervalText.isNotEmpty) {
      final interval = int.tryParse(intervalText);
      if (interval == null || interval < 5 || interval > 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidPollingInterval),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      await storage.setPollingInterval(interval);
    }
    
    await storage.setWikiUrl(wikiUrl.isEmpty ? null : wikiUrl);
    
    // Save market URL
    final marketRepoUrl = _marketRepoUrlController.text.trim();
    if (marketRepoUrl.isNotEmpty) {
      // Validate URL
      final uri = Uri.tryParse(marketRepoUrl);
      if (uri == null || !uri.hasScheme) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidMarketUrl),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }
    await storage.setMarketRepoUrl(marketRepoUrl.isEmpty ? null : marketRepoUrl);
    
    // Bildirim ayarlarını kaydet
    await storage.setNotifyOnFirstAssignment(_notifyOnFirstAssignment);
    await storage.setNotifyOnAllUpdates(_notifyOnAllUpdates);
    await storage.setNotifyOnHotfixOnly(_notifyOnHotfixOnly);
    await storage.setNotifyOnGroupAssignments(_notifyOnGroupAssignments);
    await storage.setNotificationGroups(_notificationGroups);
    
    // Akıllı saat ve mod ayarlarını kaydet
    await storage.setEnableSmartwatchNotifications(_enableSmartwatchNotifications);
    await storage.setOnCallModePhone(_onCallModePhone);
    await storage.setOnCallModeWatch(_onCallModeWatch);
    await storage.setVacationModePhone(_vacationModePhone);
    await storage.setVacationModeWatch(_vacationModeWatch);
    
    // Logo/şirket ayarlarını kaydet
    await storage.setLogoDisplayMode(_logoDisplayMode);
    final companyName = _companyNameController.text.trim();
    await storage.setCompanyName(companyName.isEmpty ? null : companyName);
    final companyLogoUrl = _companyLogoUrlController.text.trim();
    await storage.setCompanyLogoUrl(companyLogoUrl.isEmpty ? null : companyLogoUrl);
    
    // Save theme mode
    await storage.setThemeMode(_themeMode);
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSaved),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _addGroup() {
    final groupName = _groupController.text.trim();
    if (groupName.isNotEmpty && !_notificationGroups.contains(groupName)) {
      setState(() {
        _notificationGroups.add(groupName);
        _groupController.clear();
      });
    }
  }
  
  void _removeGroup(String groupName) {
    setState(() {
      _notificationGroups.remove(groupName);
    });
  }

  /// Browse and select wiki from projects
  Future<void> _browseWikis() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await authService.getAuthToken();
      
      if (token == null || authService.serverUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final wikiService = WikiService();
      
      // Get projects
      final projects = await wikiService.getProjects(
        serverUrl: authService.serverUrl!,
        token: token,
        collection: storage.getCollection(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (projects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No projects found')),
        );
        return;
      }

      // Show project selection dialog
      final selectedProject = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Project'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ListTile(
                  title: Text(project['name'] ?? ''),
                  onTap: () => Navigator.of(context).pop(project),
                );
              },
            ),
          ),
        ),
      );

      if (selectedProject == null || !mounted) return;

      // Get wikis for selected project
      setState(() => _isLoading = true);
      final wikis = await wikiService.getWikis(
        serverUrl: authService.serverUrl!,
        token: token,
        project: selectedProject['name'] ?? '',
        collection: storage.getCollection(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (wikis.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No wikis found in this project')),
        );
        return;
      }

      // Show wiki selection dialog
      final selectedWiki = await showDialog<Wiki>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Wiki (${selectedProject['name']})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: wikis.length,
              itemBuilder: (context, index) {
                final wiki = wikis[index];
                return ListTile(
                  title: Text(wiki.name),
                  subtitle: Text(wiki.projectName),
                  onTap: () => Navigator.of(context).pop(wiki),
                );
              },
            ),
          ),
        ),
      );

      if (selectedWiki == null || !mounted) return;

      // Build wiki URL
      final cleanUrl = authService.serverUrl!.endsWith('/') 
          ? authService.serverUrl!.substring(0, authService.serverUrl!.length - 1) 
          : authService.serverUrl!;
      final collection = storage.getCollection();
      final baseUrl = (collection != null && collection.isNotEmpty)
          ? '$cleanUrl/$collection'
          : cleanUrl;
      
      // Wiki URL format: {baseUrl}/{project}/_wiki/wikis/{wikiName}
      final wikiUrl = '$baseUrl/${selectedWiki.projectName}/_wiki/wikis/${selectedWiki.name}';
      
      setState(() {
        _wikiUrlController.text = wikiUrl;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Settings] Error browsing wikis: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storage = Provider.of<StorageService>(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguage = storage.getSelectedLanguage();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.wikiSettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.wikiSettingsDescription,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wikiUrlController,
                            decoration: InputDecoration(
                              labelText: l10n.wikiUrl,
                              hintText: l10n.wikiUrlHint,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.link),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _browseWikis,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Browse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.save),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Logo/Şirket Ayarları Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          l10n.companySettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.companySettingsDescription,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Logo gösterim modu
                    Text(
                      l10n.logoDisplayMode,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'auto',
                          label: Text(l10n.logoModeAuto),
                          icon: const Icon(Icons.auto_awesome),
                        ),
                        ButtonSegment(
                          value: 'custom',
                          label: Text(l10n.logoModeCustom),
                          icon: const Icon(Icons.edit),
                        ),
                        ButtonSegment(
                          value: 'none',
                          label: Text(l10n.logoModeNone),
                          icon: const Icon(Icons.visibility_off),
                        ),
                      ],
                      selected: {_logoDisplayMode},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _logoDisplayMode = selection.first;
                        });
                      },
                    ),
                    
                    // Otomatik modda tespit edilen şirket adını göster
                    if (_logoDisplayMode == 'auto') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n.detectedCompany}: ${storage.getCompanyNameFromServerUrl().isEmpty ? l10n.notDetected : storage.getCompanyNameFromServerUrl()}',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Özel modda şirket adı ve logo URL girişi
                    if (_logoDisplayMode == 'custom') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: l10n.companyName,
                          hintText: l10n.companyNameHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _companyLogoUrlController,
                        decoration: InputDecoration(
                          labelText: l10n.companyLogoUrl,
                          hintText: l10n.companyLogoUrlHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.image),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      // Logo önizleme
                      if (_companyLogoUrlController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.network(
                                  _companyLogoUrlController.text,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image, color: Colors.red.shade300);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.logoPreview,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Theme Mode Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          'Tema',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Uygulama temasını seçin',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'light',
                          label: const Text('Açık'),
                          icon: const Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: 'dark',
                          label: const Text('Koyu'),
                          icon: const Icon(Icons.dark_mode),
                        ),
                        ButtonSegment(
                          value: 'system',
                          label: const Text('Sistem'),
                          icon: const Icon(Icons.brightness_auto),
                        ),
                      ],
                      selected: {_themeMode},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _themeMode = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.marketSettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.marketSettingsDescription,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _marketRepoUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.marketUrl,
                        hintText: l10n.marketUrlHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notificationSettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Polling Interval
                    Text(
                      l10n.controlFrequency,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pollingIntervalController,
                      decoration: InputDecoration(
                        labelText: l10n.pollingInterval,
                        hintText: '15',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer),
                        helperText: l10n.pollingIntervalHelper,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pollingInterval = 10;
                                _pollingIntervalController.text = '10';
                              });
                            },
                            child: Text(l10n.fast),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pollingInterval = 15;
                                _pollingIntervalController.text = '15';
                              });
                            },
                            child: Text(l10n.normal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pollingInterval = 30;
                                _pollingIntervalController.text = '30';
                              });
                            },
                            child: Text(l10n.slow),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Bildirim Türleri
                    Text(
                      l10n.notificationTypes,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    
                    SwitchListTile(
                      title: Text(l10n.notifyOnFirstAssignment),
                      subtitle: Text(l10n.notifyOnFirstAssignmentDescription),
                      value: _notifyOnFirstAssignment,
                      onChanged: (value) {
                        setState(() => _notifyOnFirstAssignment = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    SwitchListTile(
                      title: Text(l10n.notifyOnAllUpdates),
                      subtitle: Text(l10n.notifyOnAllUpdatesDescription),
                      value: _notifyOnAllUpdates,
                      onChanged: (value) {
                        setState(() => _notifyOnAllUpdates = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    SwitchListTile(
                      title: Text(l10n.notifyOnHotfixOnly),
                      subtitle: Text(l10n.notifyOnHotfixOnlyDescription),
                      value: _notifyOnHotfixOnly,
                      onChanged: (value) {
                        setState(() => _notifyOnHotfixOnly = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const Divider(height: 32),
                    
                    // Grup Bildirimleri
                    SwitchListTile(
                      title: Text(l10n.notifyOnGroupAssignments),
                      subtitle: Text(l10n.notifyOnGroupAssignmentsDescription),
                      value: _notifyOnGroupAssignments,
                      onChanged: (value) {
                        setState(() => _notifyOnGroupAssignments = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    if (_notifyOnGroupAssignments) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _groupController,
                              decoration: InputDecoration(
                                labelText: l10n.groupName,
                                hintText: l10n.groupNameHint,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.group),
                              ),
                              onSubmitted: (_) => _addGroup(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addGroup,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_notificationGroups.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _notificationGroups.map((group) => Chip(
                            label: Text(group),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeGroup(group),
                          )).toList(),
                        ),
                      if (_notificationGroups.isEmpty)
                        Text(
                          l10n.noGroupsAdded,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                    ],
                    
                    const Divider(height: 32),
                    
                    // Akıllı Saat Bildirimleri
                    SwitchListTile(
                      title: Text(l10n.smartwatchNotifications),
                      subtitle: Text(l10n.smartwatchNotificationsDescription),
                      value: _enableSmartwatchNotifications,
                      onChanged: (value) {
                        setState(() => _enableSmartwatchNotifications = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.watch),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Nöbetçi Modu
                    Text(
                      l10n.onCallMode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.onCallModeDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(l10n.onCallModePhone),
                      subtitle: Text(l10n.onCallModePhoneDescription),
                      value: _onCallModePhone,
                      onChanged: (value) {
                        setState(() => _onCallModePhone = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.phone),
                    ),
                    SwitchListTile(
                      title: Text(l10n.onCallModeWatch),
                      subtitle: Text(l10n.onCallModeWatchDescription),
                      value: _onCallModeWatch,
                      onChanged: (value) {
                        setState(() => _onCallModeWatch = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.watch),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Tatil Modu
                    Text(
                      l10n.vacationMode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.vacationModeDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(l10n.vacationModePhone),
                      subtitle: Text(l10n.vacationModePhoneDescription),
                      value: _vacationModePhone,
                      onChanged: (value) {
                        setState(() => _vacationModePhone = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.beach_access),
                    ),
                    SwitchListTile(
                      title: Text(l10n.vacationModeWatch),
                      subtitle: Text(l10n.vacationModeWatchDescription),
                      value: _vacationModeWatch,
                      onChanged: (value) {
                        setState(() => _vacationModeWatch = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.watch_off),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Language Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.languageDescription,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage == 'system' ? null : selectedLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.selectLanguage,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.language),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('${l10n.language} (${Localizations.localeOf(context).languageCode})'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'tr',
                          child: Text('Türkçe'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'en',
                          child: Text('English'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ru',
                          child: Text('Русский'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'hi',
                          child: Text('हिन्दी'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'nl',
                          child: Text('Nederlands'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'de',
                          child: Text('Deutsch'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'fr',
                          child: Text('Français'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ur',
                          child: Text('اردو'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ug',
                          child: Text('ئۇيغۇرچە'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'az',
                          child: Text('Azərbaycan'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ky',
                          child: Text('Кыргызча'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ja',
                          child: Text('日本語'),
                        ),
                      ],
                      onChanged: (value) async {
                        await storage.setSelectedLanguage(value ?? 'system');
                        // Restart app to apply language change
                        // Note: In production, you might want to use a state management solution
                        // that can update the locale without restarting
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.serverUrl),
                subtitle: Text(authService.serverUrl ?? 'N/A'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: Text(l10n.collection),
                subtitle: Text(
                  Provider.of<StorageService>(context).getCollection() ?? 'N/A',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // RDC Services Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_center, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RDC Hizmetleri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hizmetler hakkında destek almak için tıklayınız',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final url = Uri.parse('https://rdc.com.tr');
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.couldNotOpenLink(e.toString())),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('RDC Hizmetleri'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Donate Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          l10n.donate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.donateDescription,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final url = Uri.parse('https://buymeacoffee.com/bilgicalpay');
                            // Open in external browser
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.couldNotOpenLink(e.toString())),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.coffee),
                        label: Text(l10n.donateButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
}

