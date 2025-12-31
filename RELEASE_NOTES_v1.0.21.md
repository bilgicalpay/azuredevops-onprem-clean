# Release Notes - Version 1.0.21 (119)

## Yeni Özellikler

### 1. Work Item Attachment Açma
- Work item'lardaki attachment'lar artık açılabiliyor
- Resimler dialog içinde InteractiveViewer ile gösteriliyor (zoom ve pan desteği)
- Diğer dosyalar sistem varsayılan uygulamasıyla açılıyor
- Dosyalar geçici klasöre indirilip gösteriliyor

### 2. Dark/Light Tema Seçimi
- Settings ekranına tema seçimi kartı eklendi
- Kullanıcılar Light, Dark veya System (cihaz ayarı) temalarını seçebilir
- Tema değişikliği anında uygulanıyor
- Tema tercihi kalıcı olarak saklanıyor

### 3. Wiki Browse Özelliği
- Settings ekranında Wiki URL alanının yanına "Browse" butonu eklendi
- Kullanıcılar yetkili oldukları projelerden wiki seçebilir
- Proje seçimi sonrası o projenin wikileri listeleniyor
- Seçilen wiki URL'i otomatik olarak alana yazılıyor

### 4. Wiki Görüntüleme İyileştirmesi
- Wiki içerikleri artık HTML formatında gösteriliyor
- Sadece içerik kısmı gösteriliyor (navigasyon ve diğer UI elementleri kaldırıldı)
- Web arayüzündeki gibi temiz bir görünüm
- HTML içeriği düzgün formatlanmış şekilde render ediliyor

## İyileştirmeler

- Wiki viewer performansı artırıldı
- Attachment açma işlemi daha kullanıcı dostu hale getirildi
- Tema sistemi Material 3 ile uyumlu

## Teknik Detaylar

- `WorkItemService.downloadAttachment()` metodu eklendi
- `StorageService.getThemeMode()` ve `setThemeMode()` metodları eklendi
- `WikiService.getProjects()` ve `getWikis()` metodları eklendi
- Wiki HTML endpoint'i kullanılmaya başlandı
- `WikiViewerScreen` flutter_html kullanıyor

## Versiyon

- **Version:** 1.0.21
- **Build:** 119
- **Tarih:** 2025-01-27

