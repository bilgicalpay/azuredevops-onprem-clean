#!/usr/bin/env python3
"""
Google Play Console API ile AAB dosyasını Alpha ve Closed Testing track'lerine yükler
Gereksinimler:
- pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
- Google Cloud Console'da service account oluşturulmalı
- Service account key JSON dosyası olmalı
- Google Play Console'da service account'a erişim verilmeli
"""

import os
import sys
import json
from pathlib import Path

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from googleapiclient.http import MediaFileUpload
except ImportError:
    print("❌ Google API kütüphaneleri yüklü değil!")
    print("Yüklemek için: pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib")
    sys.exit(1)

# Konfigürasyon
PACKAGE_NAME = "com.higgscloud.azuredevops"
SERVICE_ACCOUNT_FILE = os.environ.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "service-account-key.json")
AAB_FILE = "build/app/outputs/bundle/release/app-release.aab"
TRACKS = ["alpha", "closed"]  # Alpha ve Closed Testing track'leri

def get_service():
    """Google Play Console API servisini oluşturur"""
    if not os.path.exists(SERVICE_ACCOUNT_FILE):
        print(f"❌ Service account key dosyası bulunamadı: {SERVICE_ACCOUNT_FILE}")
        print("Lütfen Google Cloud Console'dan service account key JSON dosyasını indirin")
        sys.exit(1)
    
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    service = build('androidpublisher', 'v3', credentials=credentials)
    return service

def upload_aab(service, package_name, aab_file, track='alpha'):
    """AAB dosyasını belirtilen track'e yükler"""
    if not os.path.exists(aab_file):
        print(f"❌ AAB dosyası bulunamadı: {aab_file}")
        return False
    
    try:
        print(f"📦 AAB dosyası yükleniyor: {aab_file}")
        print(f"📱 Package: {package_name}")
        print(f"🎯 Track: {track}")
        
        # Edit oluştur
        edit_request = service.edits().insert(body={}, packageName=package_name)
        edit_response = edit_request.execute()
        edit_id = edit_response['id']
        
        print(f"✅ Edit oluşturuldu: {edit_id}")
        
        # AAB yükle
        media = MediaFileUpload(aab_file, mimetype='application/octet-stream', resumable=True)
        bundle_response = service.edits().bundles().upload(
            editId=edit_id,
            packageName=package_name,
            media_body=media
        ).execute()
        
        version_code = bundle_response['versionCode']
        print(f"✅ AAB yüklendi. Version Code: {version_code}")
        
        # Track'e assign et
        track_response = service.edits().tracks().update(
            editId=edit_id,
            track=track,
            packageName=package_name,
            body={
                'releases': [{
                    'versionCodes': [str(version_code)],
                    'status': 'draft',
                }]
            }
        ).execute()
        
        print(f"✅ Track'e assign edildi: {track}")
        
        # Edit'i commit et
        commit_request = service.edits().commit(
            editId=edit_id,
            packageName=package_name
        )
        commit_response = commit_request.execute()
        
        print(f"✅ Release commit edildi!")
        print(f"📋 Release ID: {commit_response.get('id', 'N/A')}")
        
        return True
        
    except HttpError as error:
        print(f"❌ HTTP Hata: {error.resp.status} - {error.content.decode()}")
        try:
            error_details = json.loads(error.content.decode())
            if 'error' in error_details:
                print(f"📋 Hata detayları: {error_details['error']}")
        except:
            pass
        return False
    except Exception as e:
        print(f"❌ Hata: {str(e)}")
        return False

def main():
    """Ana fonksiyon"""
    print("🚀 Google Play Console API ile AAB yükleme başlıyor...")
    print("=" * 60)
    
    # Service oluştur
    try:
        service = get_service()
    except Exception as e:
        print(f"❌ Service oluşturulamadı: {str(e)}")
        sys.exit(1)
    
    # Her track için yükle
    success_count = 0
    for track in TRACKS:
        print(f"\n📤 {track.upper()} track'ine yükleniyor...")
        print("-" * 60)
        
        if upload_aab(service, PACKAGE_NAME, AAB_FILE, track):
            success_count += 1
            print(f"✅ {track} track'i başarılı!")
        else:
            print(f"❌ {track} track'i başarısız!")
        
        print()
    
    print("=" * 60)
    print(f"📊 Sonuç: {success_count}/{len(TRACKS)} track başarılı")
    
    if success_count == len(TRACKS):
        print("✅ Tüm track'lere başarıyla yüklendi!")
        return 0
    else:
        print("⚠️ Bazı track'lerde sorun var, lütfen kontrol edin")
        return 1

if __name__ == "__main__":
    sys.exit(main())

