lane :upload_closed_only do |options|
  aab_path = File.expand_path("../build/app/outputs/bundle/release/app-release.aab", __dir__)
  json_key = File.expand_path("service-account-key.json", __dir__)
  
  upload_to_play_store(
    track: "closed",
    aab: aab_path,
    json_key: json_key,
    skip_upload_metadata: true,
    skip_upload_images: true,
    skip_upload_screenshots: true,
    skip_upload_changelogs: true,
  )
  
  UI.success("✅ Closed Testing track'ine yüklendi!")
end
