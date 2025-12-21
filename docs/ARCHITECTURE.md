# Mimari Topoloji Dokümantasyonu

**Uygulama:** Azure DevOps Server 2022 Mobile App  
**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.2.0+46  
**Tarih:** 21-12-2025

## Genel Bakış

Bu dokümantasyon, Azure DevOps Server 2022 Mobile App'in mimari topolojisini, bileşenlerini ve bunlar arasındaki ilişkileri açıklar.

## Mimari Katmanlar

### 1. Presentation Layer (UI Layer)
- **Flutter Widgets**: Tüm kullanıcı arayüzü bileşenleri
- **Screens**: Login, Home, Work Item Detail, Settings, Wiki, Market, Documents
- **State Management**: Provider pattern

### 2. Business Logic Layer
- **Services**: İş mantığı ve API iletişimi
- **State Management**: Provider ile state yönetimi

### 3. Data Layer
- **Local Storage**: SharedPreferences, FlutterSecureStorage
- **Network**: HTTP/HTTPS API çağrıları
- **Real-time**: WebSocket bağlantıları

### 4. Platform Layer
- **Android**: Native Android APIs
- **iOS**: Native iOS APIs
- **Security**: Certificate Pinning, Root/Jailbreak Detection

## Mimari Topoloji Diyagramı

```mermaid
graph TB
    subgraph "Mobile Device"
        subgraph "Presentation Layer"
            UI[Flutter UI Widgets]
            SCREENS[Screens:<br/>Login, Home,<br/>Work Items,<br/>Settings, Wiki]
        end
        
        subgraph "Business Logic Layer"
            AUTH[AuthService]
            STORAGE[StorageService]
            WORKITEM[WorkItemService]
            WIKI[WikiService]
            NOTIF[NotificationService]
            BG[BackgroundTaskService]
            REALTIME[RealtimeService]
            MARKET[MarketService]
            TURKISH[TurkishCultureService]
            SECURITY[SecurityService]
            CERT[CertificatePinningService]
        end
        
        subgraph "Data Layer"
            SECURE_STORAGE[(FlutterSecureStorage<br/>Encrypted)]
            PREFERENCES[(SharedPreferences<br/>Plain)]
            HTTP_CLIENT[HTTP Client<br/>Dio]
            WEBSOCKET[WebSocket<br/>Channel]
        end
        
        subgraph "Platform Layer"
            ANDROID[Android APIs]
            IOS[iOS APIs]
            KEYCHAIN[iOS Keychain]
            ENCRYPTED[Android<br/>EncryptedSharedPrefs]
        end
    end
    
    subgraph "Network"
        HTTPS[HTTPS/TLS 1.2+]
        WSS[WSS/WebSocket]
        VPN[VPN<br/>Optional]
    end
    
    subgraph "Azure DevOps Server"
        API[Azure DevOps API<br/>v7.0]
        WIT[Work Item<br/>Tracking API]
        WIKI_API[Wiki API]
        ATTACH[Attachment API]
        COMMENTS[Comments API]
        REALTIME_API[Real-time<br/>Updates API]
    end
    
    subgraph "External Services"
        IIS[IIS Static<br/>Directory<br/>Market Files]
        MDM[MDM System<br/>Intune/Workspace ONE]
    end
    
    UI --> SCREENS
    SCREENS --> AUTH
    SCREENS --> WORKITEM
    SCREENS --> WIKI
    SCREENS --> NOTIF
    SCREENS --> MARKET
    SCREENS --> TURKISH
    
    AUTH --> STORAGE
    AUTH --> HTTP_CLIENT
    WORKITEM --> STORAGE
    WORKITEM --> HTTP_CLIENT
    WIKI --> STORAGE
    WIKI --> HTTP_CLIENT
    NOTIF --> STORAGE
    BG --> STORAGE
    BG --> HTTP_CLIENT
    REALTIME --> STORAGE
    REALTIME --> WEBSOCKET
    MARKET --> HTTP_CLIENT
    SECURITY --> STORAGE
    
    STORAGE --> SECURE_STORAGE
    STORAGE --> PREFERENCES
    HTTP_CLIENT --> CERT
    CERT --> HTTPS
    WEBSOCKET --> WSS
    
    SECURE_STORAGE --> KEYCHAIN
    SECURE_STORAGE --> ENCRYPTED
    PREFERENCES --> ANDROID
    PREFERENCES --> IOS
    
    HTTPS --> VPN
    WSS --> VPN
    VPN --> API
    
    API --> WIT
    API --> WIKI_API
    API --> ATTACH
    API --> COMMENTS
    REALTIME_API --> WSS
    
    MARKET --> HTTPS
    HTTPS --> IIS
    
    MDM -.->|Configuration| ANDROID
    MDM -.->|Configuration| IOS
```

## Detaylı Bileşen Mimarisi

### Service Layer Detayları

```mermaid
graph LR
    subgraph "Service Layer"
        AUTH_SVC[AuthService<br/>- PAT Authentication<br/>- AD Authentication<br/>- Token Management]
        STORAGE_SVC[StorageService<br/>- Secure Storage<br/>- Preferences<br/>- Settings]
        WORKITEM_SVC[WorkItemService<br/>- CRUD Operations<br/>- Custom Fields<br/>- Attachments<br/>- Comments]
        WIKI_SVC[WikiService<br/>- Wiki Content<br/>- Markdown Rendering]
        NOTIF_SVC[NotificationService<br/>- Local Notifications<br/>- Push Notifications]
        BG_SVC[BackgroundTaskService<br/>- Periodic Checks<br/>- Notification Filtering]
        REALTIME_SVC[RealtimeService<br/>- WebSocket Connection<br/>- Real-time Updates]
        MARKET_SVC[MarketService<br/>- File Listing<br/>- File Download]
        TURKISH_SVC[TurkishCultureService<br/>- Random Info<br/>- Culture Data]
        SECURITY_SVC[SecurityService<br/>- Root Detection<br/>- Security Logging]
        CERT_SVC[CertificatePinningService<br/>- SHA-256 Pinning<br/>- Certificate Validation]
    end
```

### Data Flow Diyagramı

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant Service
    participant Storage
    participant Network
    participant AzureDevOps
    
    User->>UI: Login Action
    UI->>Service: loginWithPAT()
    Service->>Network: HTTPS Request
    Network->>AzureDevOps: API Call
    AzureDevOps-->>Network: Token Response
    Network-->>Service: Token
    Service->>Storage: Save Token (Encrypted)
    Storage-->>Service: Success
    Service-->>UI: Auth Success
    UI-->>User: Show Home Screen
    
    User->>UI: View Work Items
    UI->>Service: getWorkItems()
    Service->>Storage: Get Token
    Storage-->>Service: Token
    Service->>Network: HTTPS Request (with Token)
    Network->>AzureDevOps: API Call
    AzureDevOps-->>Network: Work Items
    Network-->>Service: Work Items Data
    Service-->>UI: Work Items List
    UI-->>User: Display Work Items
```

### Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        APP_SEC[Application Security]
        NET_SEC[Network Security]
        DATA_SEC[Data Security]
        DEV_SEC[Device Security]
    end
    
    subgraph "Application Security"
        CERT_PIN[Certificate Pinning<br/>SHA-256]
        ROOT_DET[Root/Jailbreak<br/>Detection]
        SEC_LOG[Security Logging]
        AUTO_LOGOUT[Auto Logout<br/>30 days]
    end
    
    subgraph "Network Security"
        HTTPS_ONLY[HTTPS Only<br/>TLS 1.2+]
        CERT_VALID[Certificate<br/>Validation]
        VPN_SUPPORT[VPN Support]
    end
    
    subgraph "Data Security"
        ENCRYPT_STOR[Encrypted Storage<br/>AES-256]
        SECURE_TOKEN[Secure Token<br/>Storage]
        NO_PLAIN[No Plain Text<br/>Credentials]
    end
    
    subgraph "Device Security"
        MDM_INT[MDM Integration]
        REMOTE_WIPE[Remote Wipe]
        DEVICE_ENCRYPT[Device Encryption<br/>Required]
    end
    
    APP_SEC --> CERT_PIN
    APP_SEC --> ROOT_DET
    APP_SEC --> SEC_LOG
    APP_SEC --> AUTO_LOGOUT
    
    NET_SEC --> HTTPS_ONLY
    NET_SEC --> CERT_VALID
    NET_SEC --> VPN_SUPPORT
    
    DATA_SEC --> ENCRYPT_STOR
    DATA_SEC --> SECURE_TOKEN
    DATA_SEC --> NO_PLAIN
    
    DEV_SEC --> MDM_INT
    DEV_SEC --> REMOTE_WIPE
    DEV_SEC --> DEVICE_ENCRYPT
```

## Bileşen Açıklamaları

### Presentation Layer

#### Screens
- **LoginScreen**: Kullanıcı kimlik doğrulama
- **HomeScreen**: Ana dashboard, work items listesi, wiki özeti, Türk kültürü popup
- **WorkItemDetailScreen**: Work item detayları, custom fields, attachments, comments
- **WorkItemListScreen**: Work items listesi ve filtreleme
- **QueriesScreen**: Query çalıştırma ve sonuç görüntüleme
- **WikiViewerScreen**: Wiki içerik görüntüleme
- **SettingsScreen**: Uygulama ayarları, bildirim ayarları
- **MarketScreen**: APK/IPA dosyalarını indirme
- **DocumentsScreen**: Dokümantasyon görüntüleme

### Business Logic Layer

#### Services

**AuthService**
- PAT ve AD kimlik doğrulama
- Token yönetimi
- Oturum yönetimi
- Logout işlemleri

**StorageService**
- Güvenli veri saklama (FlutterSecureStorage)
- Genel ayarlar (SharedPreferences)
- Token ve kimlik bilgileri yönetimi
- Bildirim ayarları yönetimi
- Akıllı saat bildirim ayarları
- Nöbetçi modu ayarları (telefon ve akıllı saat için ayrı)
- Tatil modu ayarları (telefon ve akıllı saat için ayrı)
- Okunmayan bildirim retry takibi

**WorkItemService**
- Work item CRUD işlemleri
- Custom field yönetimi
- Attachment yükleme ve görüntüleme
- Comments/Discussion yönetimi
- Field definition'ları alma

**WikiService**
- Wiki içerik çekme
- Markdown rendering

**NotificationService**
- Local notification gönderme
- Bildirim ayarlarına göre filtreleme
- Akıllı saat bildirimleri (Wear OS ve watchOS)
- Etkileşimli butonlar ile state değiştirme
- Nöbetçi modu için agresif bildirimler
- Tatil modu kontrolü

**BackgroundTaskService**
- Periyodik work item kontrolü
- Bildirim gönderme
- Bildirim filtreleme mantığı
- Nöbetçi modu kontrolü
- Tatil modu kontrolü
- Okunmayan bildirimleri 3 kez yenileme (nöbetçi modunda)

**RealtimeService**
- WebSocket bağlantısı
- Gerçek zamanlı güncellemeler
- Bildirim gönderme
- Nöbetçi modu kontrolü
- Tatil modu kontrolü

**MarketService**
- IIS static dizin listeleme
- APK/IPA dosyalarını indirme

**TurkishCultureService**
- Rastgele Türk kültürü bilgileri
- Tarihi figürler ve devletler

**SecurityService**
- Root/jailbreak tespiti
- Güvenlik loglama

**CertificatePinningService**
- SHA-256 certificate pinning
- Certificate validation

### Data Layer

#### Storage
- **FlutterSecureStorage**: Şifrelenmiş veri saklama (token'lar, kimlik bilgileri)
- **SharedPreferences**: Genel ayarlar (server URL, collection, vb.)

#### Network
- **Dio**: HTTP client (HTTPS istekleri)
- **WebSocket Channel**: Gerçek zamanlı güncellemeler

### Platform Layer

#### Android
- EncryptedSharedPreferences (FlutterSecureStorage)
- Android Auto Backup
- Root detection

#### iOS
- Keychain Services (FlutterSecureStorage)
- iCloud Backup
- Jailbreak detection

## Veri Akışı

### Authentication Flow
1. Kullanıcı kimlik bilgilerini girer
2. AuthService API'ye istek gönderir
3. Token alınır ve FlutterSecureStorage'da saklanır
4. Token tüm API isteklerinde kullanılır

### Work Item Flow
1. Kullanıcı work item listesini görüntüler
2. WorkItemService API'den work item'ları çeker
3. Custom field definition'ları alınır
4. Veriler UI'da gösterilir
5. Kullanıcı değişiklik yaparsa API'ye gönderilir

### Notification Flow
1. BackgroundTaskService periyodik olarak çalışır
2. Yeni/ güncellenmiş work item'lar kontrol edilir
3. Bildirim ayarlarına göre filtreleme yapılır:
   - İlk atamada bildirim kontrolü
   - Tüm güncellemelerde bildirim kontrolü
   - Hotfix filtresi
   - Grup bildirimleri
   - Nöbetçi modu kontrolü (telefon ve akıllı saat için ayrı)
   - Tatil modu kontrolü (telefon ve akıllı saat için ayrı)
4. Uygun bildirimler gönderilir:
   - Telefon bildirimleri (normal veya nöbetçi modu)
   - Akıllı saat bildirimleri (sadece ilk atamada, etkileşimli butonlarla)
5. Nöbetçi modunda okunmayan bildirimler 3 kez yenilenir (30 saniye aralıklarla)

### Real-time Update Flow
1. RealtimeService WebSocket bağlantısı kurar
2. Azure DevOps Server'dan güncellemeler alınır
3. Bildirim ayarlarına göre filtreleme yapılır:
   - İlk atamada bildirim kontrolü
   - Tüm güncellemelerde bildirim kontrolü
   - Hotfix filtresi
   - Grup bildirimleri
   - Nöbetçi modu kontrolü (telefon ve akıllı saat için ayrı)
   - Tatil modu kontrolü (telefon ve akıllı saat için ayrı)
4. UI güncellenir ve bildirimler gönderilir:
   - Telefon bildirimleri (normal veya nöbetçi modu)
   - Akıllı saat bildirimleri (sadece ilk atamada, etkileşimli butonlarla)

## Güvenlik Mimarisi

### Katmanlar
1. **Application Layer**: Certificate pinning, root detection
2. **Network Layer**: HTTPS/TLS, VPN support
3. **Data Layer**: Encrypted storage, secure token management
4. **Device Layer**: MDM integration, device encryption

### Güvenlik Özellikleri
- ✅ Certificate Pinning (SHA-256)
- ✅ Encrypted Storage (AES-256)
- ✅ Root/Jailbreak Detection
- ✅ Security Logging
- ✅ Auto Logout (30 days)
- ✅ MDM Integration
- ✅ Remote Wipe Support

## Deployment Topology

```mermaid
graph TB
    subgraph "Development"
        DEV[Developer<br/>Machine]
        GIT[Git Repository<br/>GitHub]
    end
    
    subgraph "CI/CD Pipeline"
        GITHUB_ACTIONS[GitHub Actions]
        BUILD[Build Process]
        TEST[Tests]
        SEC_SCAN[Security Scan]
        SBOM[SBOM Generation]
    end
    
    subgraph "Artifact Storage"
        RELEASE[GitHub Releases]
        APK[Android APK]
        IPA[iOS IPA]
        SIG[Signatures]
    end
    
    subgraph "Distribution"
        MDM[MDM System]
        IIS[IIS Market]
    end
    
    subgraph "End Users"
        ANDROID_DEV[Android Devices]
        IOS_DEV[iOS Devices]
    end
    
    DEV --> GIT
    GIT --> GITHUB_ACTIONS
    GITHUB_ACTIONS --> BUILD
    BUILD --> TEST
    TEST --> SEC_SCAN
    SEC_SCAN --> SBOM
    SBOM --> RELEASE
    RELEASE --> APK
    RELEASE --> IPA
    RELEASE --> SIG
    RELEASE --> MDM
    RELEASE --> IIS
    MDM --> ANDROID_DEV
    MDM --> IOS_DEV
    IIS --> ANDROID_DEV
    IIS --> IOS_DEV
```

## Teknoloji Stack

### Frontend
- **Framework**: Flutter 3.24.0
- **Language**: Dart
- **State Management**: Provider
- **UI Components**: Material Design, Cupertino

### Backend Integration
- **API**: Azure DevOps Server REST API v7.0
- **Protocol**: HTTPS/TLS 1.2+
- **Real-time**: WebSocket (WSS)

### Storage
- **Secure**: FlutterSecureStorage (AES-256)
- **General**: SharedPreferences

### Security
- **Certificate Pinning**: SHA-256 fingerprints
- **Encryption**: AES-256
- **Root Detection**: root_detector package

### Platform
- **Android**: Minimum SDK 21, Target SDK 34
- **iOS**: Minimum iOS 12.0, Target iOS 17.0

## İlgili Dokümantasyon

- **Güvenlik**: [docs/SECURITY.md](SECURITY.md)
- **Altyapı**: [docs/INFRASTRUCTURE.md](INFRASTRUCTURE.md)
- **MDM Entegrasyonu**: [docs/MDM_INTEGRATION.md](MDM_INTEGRATION.md)
- **Güvenlik Özellikleri**: [docs/SECURITY_FEATURES.md](SECURITY_FEATURES.md)

---

**Son Güncelleme:** 21-12-2025  
**Dokümantasyon Versiyonu:** 1.2.0

