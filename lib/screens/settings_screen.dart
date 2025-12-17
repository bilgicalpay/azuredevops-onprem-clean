/// Ayarlar ekranı
/// 
/// Uygulama ayarlarını yönetir. Wiki URL'si girişi ve
/// mevcut server bilgilerini gösterir.
/// 
/// @author Alpay Bilgiç

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
  bool _isLoading = false;
  int _pollingInterval = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _wikiUrlController.dispose();
    _pollingIntervalController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final wikiUrl = storage.getWikiUrl();
    _wikiUrlController.text = wikiUrl ?? '';
    
    // Load polling interval
    final interval = await storage.getPollingIntervalAsync();
    setState(() {
      _pollingInterval = interval;
      _pollingIntervalController.text = interval.toString();
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
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayarlar kaydedildi. Uygulama yeniden başlatıldığında geçerli olacaktır.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
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
                      'Bildirim Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Work item kontrolü için polling interval (saniye). Daha kısa interval daha hızlı bildirim sağlar ancak daha fazla pil tüketir.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pollingIntervalController,
                      decoration: const InputDecoration(
                        labelText: 'Polling Interval (saniye)',
                        hintText: '15',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        helperText: '5-300 saniye arası (varsayılan: 15)',
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

