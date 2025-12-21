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
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'dart:ui' show Locale;

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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final wikiUrl = storage.getWikiUrl();
    _wikiUrlController.text = wikiUrl ?? '';
    
    final marketRepoUrl = storage.getMarketRepoUrl();
    _marketRepoUrlController.text = marketRepoUrl ?? '';
    
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
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    final storage = Provider.of<StorageService>(context, listen: false);
    final wikiUrl = _wikiUrlController.text.trim();
    
    if (wikiUrl.isNotEmpty) {
      // Validate URL
      final uri = Uri.tryParse(wikiUrl);
      if (uri == null || !uri.hasScheme) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçerli bir URL girin'),
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
          const SnackBar(
            content: Text('Polling interval 5-300 saniye arasında olmalıdır'),
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
          const SnackBar(
            content: Text('Geçerli bir Market URL girin (örn: https://devops.higgscloud.com/_static/market/)'),
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
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayarlar kaydedildi'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
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
                    const Text(
                      'Wiki Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Azure DevOps wiki dosyasının URL\'sini girin. Bu wiki içeriği ana sayfada gösterilecektir.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _wikiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Wiki URL',
                        hintText: 'https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
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
                          : const Text('Kaydet'),
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
                    const Text(
                      'Market Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'IIS static dizin URL\'sini girin. Bu dizinden APK ve IPA dosyaları listelenecek ve indirilebilecektir.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _marketRepoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Market URL',
                        hintText: 'https://devops.higgscloud.com/_static/market/',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
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
                    const Text(
                      'Bildirim Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Polling Interval
                    const Text(
                      'Kontrol Sıklığı',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pollingIntervalController,
                      decoration: const InputDecoration(
                        labelText: 'Polling Interval (saniye)',
                        hintText: '15',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        helperText: '5-300 saniye arası',
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
                            child: const Text('Hızlı (10s)'),
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
                            child: const Text('Normal (15s)'),
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
                            child: const Text('Yavaş (30s)'),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Bildirim Türleri
                    const Text(
                      'Bildirim Türleri',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    
                    SwitchListTile(
                      title: const Text('İlk Atamada Bildirim'),
                      subtitle: const Text('Sadece bana ilk atandığında bildirim gönder'),
                      value: _notifyOnFirstAssignment,
                      onChanged: (value) {
                        setState(() => _notifyOnFirstAssignment = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Tüm Güncellemelerde Bildirim'),
                      subtitle: const Text('Bana atanmış work item\'lar güncellendiğinde bildirim gönder'),
                      value: _notifyOnAllUpdates,
                      onChanged: (value) {
                        setState(() => _notifyOnAllUpdates = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Sadece Hotfix'),
                      subtitle: const Text('Sadece Hotfix tipindeki work item\'lar için bildirim'),
                      value: _notifyOnHotfixOnly,
                      onChanged: (value) {
                        setState(() => _notifyOnHotfixOnly = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const Divider(height: 32),
                    
                    // Grup Bildirimleri
                    SwitchListTile(
                      title: const Text('Grup Atamalarında Bildirim'),
                      subtitle: const Text('Belirtilen gruplara atama yapıldığında bildirim gönder'),
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
                              decoration: const InputDecoration(
                                labelText: 'Grup Adı',
                                hintText: 'Örn: Developers, QA Team',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
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
                        const Text(
                          'Henüz grup eklenmedi. Yukarıdan grup adı girerek ekleyin.',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                    ],
                    
                    const Divider(height: 32),
                    
                    // Akıllı Saat Bildirimleri
                    SwitchListTile(
                      title: const Text('Akıllı Saat Bildirimleri'),
                      subtitle: const Text('Akıllı saatlere bildirim gönder (sadece ilk atamada)'),
                      value: _enableSmartwatchNotifications,
                      onChanged: (value) {
                        setState(() => _enableSmartwatchNotifications = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.watch),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Nöbetçi Modu
                    const Text(
                      'Nöbetçi Modu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nöbetçi modunda bildirimler daha agresif olur ve okunmayan bildirimler 3 kez yenilenir.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Telefon için Nöbetçi Modu'),
                      subtitle: const Text('Telefonda agresif bildirimler'),
                      value: _onCallModePhone,
                      onChanged: (value) {
                        setState(() => _onCallModePhone = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.phone),
                    ),
                    SwitchListTile(
                      title: const Text('Akıllı Saat için Nöbetçi Modu'),
                      subtitle: const Text('Akıllı saatte agresif bildirimler'),
                      value: _onCallModeWatch,
                      onChanged: (value) {
                        setState(() => _onCallModeWatch = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.watch),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Tatil Modu
                    const Text(
                      'Tatil Modu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tatil modunda hiçbir bildirim gelmez.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Telefon için Tatil Modu'),
                      subtitle: const Text('Telefonda bildirimleri devre dışı bırak'),
                      value: _vacationModePhone,
                      onChanged: (value) {
                        setState(() => _vacationModePhone = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.beach_access),
                    ),
                    SwitchListTile(
                      title: const Text('Akıllı Saat için Tatil Modu'),
                      subtitle: const Text('Akıllı saatte bildirimleri devre dışı bırak'),
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
                                  content: Text('Could not open link: $e'),
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

