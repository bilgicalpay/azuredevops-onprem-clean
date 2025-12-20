/// Giriş ekranı
/// 
/// Kullanıcının Azure DevOps Server'a bağlanmasını sağlar.
/// PAT (Personal Access Token) veya AD (Active Directory) kimlik doğrulama destekler.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// Giriş ekranı widget'ı
/// Kullanıcı kimlik doğrulama işlemlerini yönetir
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collectionController = TextEditingController();
  
  bool _isTokenAuth = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    bool success = false;
    
    if (_isTokenAuth) {
      success = await authService.loginWithToken(
        serverUrl: _serverUrlController.text.trim(),
        token: _tokenController.text.trim(),
        collection: _collectionController.text.trim().isEmpty 
            ? null 
            : _collectionController.text.trim(),
      );
    } else {
      success = await authService.loginWithAD(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        collection: _collectionController.text.trim().isEmpty 
            ? null 
            : _collectionController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AzureDevOPS'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo not found
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 64,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
              const Text(
                'Azure DevOps Server 2022',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Server URL
              TextFormField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://tfs.example.com/tfs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Server URL gerekli';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'Geçerli bir URL girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Collection (optional)
              TextFormField(
                controller: _collectionController,
                decoration: const InputDecoration(
                  labelText: 'Collection (Opsiyonel)',
                  hintText: 'DefaultCollection',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
              ),
              const SizedBox(height: 24),
              
              // Auth Type Toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Token'),
                    icon: Icon(Icons.key),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Active Directory'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_isTokenAuth},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isTokenAuth = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Token or AD fields
              if (_isTokenAuth) ...[
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Personal Access Token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Token gerekli';
                    }
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kullanıcı adı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

