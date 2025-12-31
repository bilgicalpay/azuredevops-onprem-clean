# Azure DevOps Demo Project Oluşturma - Azure DevOps Demo Generator Kullanımı

## 🌟 En Kolay Yöntem: Azure DevOps Demo Generator

Azure DevOps Demo Generator, hazır demo projeleri ile Azure DevOps projenizi otomatik olarak doldurur.

### Adım 1: Azure DevOps Demo Generator'a Gidin

🔗 **Link:** https://azuredevopsdemogenerator.azurewebsites.net/

### Adım 2: Giriş Yapın

- "Sign in with Microsoft" butonuna tıklayın
- Azure DevOps hesabınızla giriş yapın

### Adım 3: Demo Proje Oluşturun

1. **Select Organization:** `hygieia-devops` seçin
2. **Select Template:** Demo template seçin:
   - **Parts Unlimited** - E-ticaret demo projesi
   - **MyShuttle** - Ulaşım demo projesi  
   - **SmartHotel360** - Otel yönetim demo projesi
   - **DevOps Toolchain** - DevOps araç zinciri demo projesi
3. **Project Name:** Yeni bir proje adı girin (veya mevcut projeyi seçin)
4. **Select Team:** İlgili team'i seçin
5. **Create Project** butonuna tıklayın

### Adım 4: Bekleyin

- Demo Generator projeyi doldurmaya başlar (5-10 dakika sürebilir)
- Epic, Feature, PBI, Task, Test, Bug gibi tüm work item'lar otomatik oluşturulur
- Sprint'ler ve ilişkiler kurulur

## 📋 Oluşturulan İçerik

Her demo template şunları içerir:
- ✅ Epic'ler
- ✅ Feature'lar
- ✅ Product Backlog Items (PBI)
- ✅ Task'lar
- ✅ Test Case'ler
- ✅ Bug'lar
- ✅ Sprint'ler (1 yıl boyunca)
- ✅ Work item'lar arası ilişkiler (parent-child, related)
- ✅ Kanban board'ları
- ✅ Build ve Release pipeline'ları (bazı template'lerde)

## 🔧 Alternatif: Manuel Script Kullanımı

Eğer Azure DevOps Demo Generator kullanmak istemiyorsanız:

```bash
python3 scripts/create_demo_project_fixed.py
```

Bu script temel bir demo proje oluşturur ancak Azure DevOps Demo Generator kadar kapsamlı değildir.

## 📚 Daha Fazla Bilgi

- **Azure DevOps Demo Generator Docs:** https://azuredevopsdemogenerator.azurewebsites.net/
- **Template Listesi:** https://azuredevopsdemogenerator.azurewebsites.net/KnowledgeBase
