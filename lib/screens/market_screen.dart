/// Market Ekranı
/// 
/// Azure DevOps Git repository'den release'leri ve artifact'ları gösterir.
/// Kullanıcılar APK ve IPA dosyalarını indirebilir.
/// 
/// @author Alpay Bilgiç

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/market_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

/// Market ekranı widget'ı
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  MarketService? _marketService;
  List<Release> _releases = [];
  bool _isLoading = false;
  String? _error;
  String? _downloadingArtifact;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadReleases();
  }

  void _initializeService() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      authService.setStorage(storage);
      setState(() {
        _marketService = MarketService(authService);
      });
    });
  }

  Future<void> _loadReleases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final repoUrl = storage.getMarketRepoUrl();

      if (repoUrl == null || repoUrl.isEmpty) {
        setState(() {
          _error = 'Market repository URL ayarlanmamış. Lütfen Ayarlar\'dan repository URL\'sini girin.';
          _isLoading = false;
        });
        return;
      }

      if (_marketService == null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final storage = Provider.of<StorageService>(context, listen: false);
        authService.setStorage(storage);
        _marketService = MarketService(authService);
      }

      final releases = await _marketService!.getReleases(repoUrl);
      
      setState(() {
        _releases = releases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Release\'ler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadArtifact(Artifact artifact) async {
    if (_downloadingArtifact == artifact.name) {
      return; // Already downloading
    }

    setState(() {
      _downloadingArtifact = artifact.name;
    });

    try {
      // For mobile apps, we'll open the download URL directly
      // The browser/download manager will handle the download
      // Add authentication token to URL if needed
      final uri = Uri.parse(artifact.downloadUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${artifact.name} indiriliyor...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('URL açılamadı');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _downloadingArtifact = null;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih bilgisi yok';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _formatSize(int? size) {
    if (size == null) return 'Bilinmiyor';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReleases,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                          child: const Text('Ayarlara Git'),
                        ),
                      ],
                    ),
                  ),
                )
              : _releases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz release bulunamadı',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadReleases,
                            child: const Text('Yenile'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReleases,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _releases.length,
                        itemBuilder: (context, index) {
                          final release = _releases[index];
                          final apkArtifacts = release.artifacts.where((a) => a.isApk).toList();
                          final ipaArtifacts = release.artifacts.where((a) => a.isIpa).toList();
                          final aabArtifacts = release.artifacts.where((a) => a.isAab).toList();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.tag, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          release.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (release.publishedAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDate(release.publishedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (release.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      release.description!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  if (apkArtifacts.isNotEmpty || ipaArtifacts.isNotEmpty || aabArtifacts.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'İndirilebilir Dosyalar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...apkArtifacts.map((artifact) => _buildArtifactTile(
                                          artifact,
                                          Icons.android,
                                          Colors.green,
                                        )),
                                    ...ipaArtifacts.map((artifact) => _buildArtifactTile(
                                          artifact,
                                          Icons.phone_iphone,
                                          Colors.blue,
                                        )),
                                    ...aabArtifacts.map((artifact) => _buildArtifactTile(
                                          artifact,
                                          Icons.android,
                                          Colors.orange,
                                        )),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildArtifactTile(Artifact artifact, IconData icon, Color color) {
    final isDownloading = _downloadingArtifact == artifact.name;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(artifact.name),
      subtitle: Text(_formatSize(artifact.size)),
      trailing: isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadArtifact(artifact),
              tooltip: 'İndir',
            ),
      onTap: () => _downloadArtifact(artifact),
    );
  }
}

