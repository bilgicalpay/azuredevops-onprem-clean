# Azure DevOps Demo Project Oluşturma Rehberi

## Otomatik Demo Proje Oluşturucu

Bu script Azure DevOps projenize örnek work item'lar oluşturur.

## Kullanım

```bash
python3 scripts/create_demo_project.py
```

## Oluşturulan Work Item'lar

Script aşağıdaki work item'ları oluşturur:

### Epic'ler
1. Mobile Application Development Platform
2. CI/CD Pipeline Implementation

### Feature'lar
1. User Authentication & Authorization (Epic 1'e bağlı)
2. Work Item Management (Epic 1'e bağlı)
3. Build Automation Pipeline (Epic 2'ye bağlı)

### Product Backlog Items (PBI)
1. Login Screen Implementation (Feature 1'e bağlı)
2. Work Item List View (Feature 2'ye bağlı)

### Task'lar
1. Design Login UI (PBI 1'e bağlı)
2. Implement PAT Authentication (PBI 1'e bağlı)

### Test Case'ler
1. Login Screen Test: Valid PAT (PBI 1'e bağlı)

### Bug'lar
1. Login screen crashes on invalid token (PBI 1'e bağlı)

## Alternatif: Azure DevOps Demo Generator

Daha kapsamlı demo projeler için Azure DevOps Demo Generator kullanabilirsiniz:

1. **Web UI ile:**
   - https://azuredevopsdemogenerator.azurewebsites.net/ adresine gidin
   - Organization'ı seçin
   - Demo proje template'ini seçin (örn: "Parts Unlimited", "MyShuttle", "SmartHotel360")
   - Proje adını girin ve oluşturun

2. **API ile (Gelişmiş):**
   - Azure DevOps Demo Generator REST API kullanarak programatik olarak demo proje oluşturabilirsiniz
   - Detaylar: https://docs.microsoft.com/en-us/azure/devops/demo-gen/

## Özelleştirme

Script'i özelleştirmek için `scripts/create_demo_project.py` dosyasını düzenleyebilirsiniz:
- Daha fazla Epic, Feature, PBI, Task ekleyin
- Sprint'ler oluşturun
- Work item'lar arası ilişkileri güçlendirin
- Özel alan değerleri ekleyin

## Notlar

- Script PAT token kullanır (TOKEN değişkeni)
- Organization ve Project adlarını script içinde güncelleyin
- API version 7.0 kullanılır (Azure DevOps Server 2022 uyumlu)
