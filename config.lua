Config = {}

Config.SaveInterval = 10 -- dakikada bir (Dışarıdaki tüm araçları otomatik kaydeder)
Config.Debug = true -- Konsolda detaylı log gösterir


Config.InactivityHours = 48 -- Kaç saat binilmeyen araçlar depoya kaldırılsın?
Config.DepotPrice = 500 -- Dünyadan silinen/patlayan araçlar depoya ne kadar borçla gitsin?

-- Özellik Ayarları
Config.SaveFuel = true -- Yakıtı kaydet
Config.SaveHealth = true -- Motor ve gövde sağlığını kaydet
Config.SaveVisualDamage = true -- Kapı, cam ve lastik hasarlarını kaydet

-- Komutlar
Config.WipeCommand = "wipevehicles" -- Tüm kalıcı araçları silme komutu (Admin)
