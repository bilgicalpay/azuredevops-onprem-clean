/// Ayarlar ekranı
/// 
/// Uygulama ayarlarını yönetir. Wiki URL'si girişi ve
/// mevcut server bilgilerini gösterir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

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
    
    setState(() {
      _pollingInterval = interval;
      _pollingIntervalController.text = interval.toString();
      _notifyOnFirstAssignment = notifyOnFirstAssignment;
      _notifyOnAllUpdates = notifyOnAllUpdates;
      _notifyOnHotfixOnly = notifyOnHotfixOnly;
      _notifyOnGroupAssignments = notifyOnGroupAssignments;
      _notificationGroups = notificationGroups;
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Server URL'),
                subtitle: Text(authService.serverUrl ?? 'N/A'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Collection'),
                subtitle: Text(
                  Provider.of<StorageService>(context).getCollection() ?? 'N/A',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

