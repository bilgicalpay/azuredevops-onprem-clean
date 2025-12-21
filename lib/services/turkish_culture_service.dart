/// Turkish Culture Service
/// 
/// Provides random information about Turkish history, science, art, and historical Turkish states
/// 
/// @author Alpay Bilgiç
library;

import 'dart:math';

/// Turkish culture information data
class TurkishCultureService {
  static final Random _random = Random();
  
  // Track shown information to avoid duplicates
  static final Set<String> _shownInfoKeys = <String>{};
  
  /// Turkish historical figures and achievements in science and art
  static final List<Map<String, String>> _turkishFigures = [
    {
      'name': 'İbn-i Sina',
      'info': 'Tıp alanında "El-Kanun fi\'t-Tıb" adlı eseriyle Orta Çağ\'ın en önemli tıp ansiklopedisini yazdı. Avicenna olarak bilinen bu büyük bilim insanı, modern tıbbın temellerini attı.',
    },
    {
      'name': 'Ali Kuşçu',
      'info': '15. yüzyılda matematik ve astronomi alanında çığır açan çalışmalar yaptı. Fatih Sultan Mehmet\'in davetiyle İstanbul\'a geldi ve medreselerde ders verdi.',
    },
    {
      'name': 'Uluğ Bey',
      'info': 'Timur İmparatorluğu\'nun hükümdarı ve büyük bir astronom. Semerkant\'ta kurduğu rasathanede yıldız katalogları hazırladı. "Zic-i Uluğ Bey" adlı eseri yüzyıllarca kullanıldı.',
    },
    {
      'name': 'Farabi',
      'info': 'İslam felsefesinin kurucularından. "İkinci Öğretmen" unvanıyla anıldı. Müzik teorisi, mantık ve siyaset felsefesi alanlarında önemli eserler verdi.',
    },
    {
      'name': 'Mimar Sinan',
      'info': 'Osmanlı İmparatorluğu\'nun baş mimarı. 300\'den fazla eser verdi. Süleymaniye ve Selimiye camileri gibi dünya mimarlık tarihine geçen eserler yarattı.',
    },
    {
      'name': 'Evliya Çelebi',
      'info': '17. yüzyılın büyük seyyahı. "Seyahatname" adlı 10 ciltlik eseriyle Osmanlı coğrafyasını ve kültürünü kayıt altına aldı. Dünya seyahat edebiyatının önemli isimlerinden.',
    },
    {
      'name': 'Katip Çelebi',
      'info': 'Osmanlı\'nın önemli coğrafyacı ve tarihçisi. "Cihannüma" adlı coğrafya eseri ve "Keşfü\'z-Zünun" bibliyografya eseriyle tanınır.',
    },
    {
      'name': 'Piri Reis',
      'info': 'Osmanlı denizcisi ve haritacı. 1513 yılında çizdiği dünya haritası, Amerika kıtasının en eski haritalarından biri olarak kabul edilir.',
    },
    {
      'name': 'Cahit Arf',
      'info': 'Türk matematikçi. "Arf Sabiti" ve "Arf Halkaları" teorisiyle matematik dünyasında önemli bir yer edindi. Modern cebir ve sayılar teorisine katkıları büyüktür.',
    },
    {
      'name': 'Aziz Sancar',
      'info': '2015 Nobel Kimya Ödülü sahibi. DNA onarım mekanizmalarını keşfetti. Türkiye\'den Nobel alan ilk bilim insanı.',
    },
    {
      'name': 'Fazıl Say',
      'info': 'Dünya çapında tanınan piyanist ve besteci. Klasik müzik alanında önemli eserler verdi ve birçok uluslararası ödül kazandı.',
    },
    {
      'name': 'Yunus Emre',
      'info': '13. yüzyıl Türk şairi ve mutasavvıf. Türkçe şiirin öncülerinden. "Risaletü\'n-Nushiyye" ve "Divan" adlı eserleriyle tanınır.',
    },
    {
      'name': 'Mehmet Akif Ersoy',
      'info': 'İstiklal Marşı\'nın şairi. Milli mücadele döneminde yazdığı şiirlerle Türk edebiyatının önemli isimlerinden biri oldu.',
    },
    {
      'name': 'Nazım Hikmet',
      'info': '20. yüzyılın önemli şairlerinden. Türk şiirinde serbest ölçüyü yaygınlaştırdı. "Memleketimden İnsan Manzaraları" gibi büyük eserler verdi.',
    },
    {
      'name': 'Osman Hamdi Bey',
      'info': 'Türk ressam, arkeolog ve müzeci. İlk Türk arkeoloğu. "Kaplumbağa Terbiyecisi" gibi ünlü tablolarıyla tanınır.',
    },
    {
      'name': 'Harezmi',
      'info': '9. yüzyıl matematikçi ve astronom. Cebir biliminin kurucusu. "Hisab el-Cebr ve\'l-Mukabele" adlı eseriyle cebir terimini ilk kullandı.',
    },
    {
      'name': 'Biruni',
      'info': '11. yüzyıl bilim insanı. Astronomi, matematik, coğrafya ve tarih alanlarında çalıştı. Dünya\'nın çevresini hesaplayan ilk bilim insanlarından.',
    },
    {
      'name': 'İbn-i Heysem',
      'info': 'Optik biliminin kurucusu. "Kitab el-Menazır" adlı eseriyle modern optik biliminin temellerini attı. Kamera obscura prensibini keşfetti.',
    },
    {
      'name': 'Takiyüddin',
      'info': '16. yüzyıl Osmanlı astronomu ve matematikçisi. İstanbul\'da rasathane kurdu. Trigonometri tabloları hazırladı.',
    },
    {
      'name': 'Gelenbevi İsmail Efendi',
      'info': '18. yüzyıl Osmanlı matematikçisi. Logaritma ve cebir alanında önemli çalışmalar yaptı. Osmanlı\'da modern matematiğin öncülerinden.',
    },
    {
      'name': 'Salih Zeki',
      'info': '19. yüzyıl Türk matematikçi ve eğitimci. "Kamus-ı Riyaziyat" adlı matematik ansiklopedisini yazdı. Darülfünun\'da ders verdi.',
    },
    {
      'name': 'Kerim Erim',
      'info': 'Türk matematikçi. İstanbul Üniversitesi\'nde profesör. Analiz ve diferansiyel geometri alanında önemli çalışmalar yaptı.',
    },
    {
      'name': 'Feza Gürsey',
      'info': 'Türk teorik fizikçi. Parçacık fiziği ve simetri teorileri üzerine çalıştı. Yale Üniversitesi\'nde profesörlük yaptı.',
    },
    {
      'name': 'Ratip Berker',
      'info': 'Türk matematikçi ve mühendis. İTÜ\'de rektörlük yaptı. Türkiye\'de mühendislik eğitiminin gelişmesine katkıda bulundu.',
    },
    {
      'name': 'Behram Kurşunoğlu',
      'info': 'Türk teorik fizikçi. Genel görelilik teorisi üzerine çalıştı. Miami Üniversitesi\'nde profesörlük yaptı.',
    },
    {
      'name': 'Gazi Yaşargil',
      'info': 'Türk nöroşirürji uzmanı. Mikrocerrahi tekniklerinin öncülerinden. Dünya çapında tanınan beyin cerrahı.',
    },
    {
      'name': 'Erdal İnönü',
      'info': 'Türk fizikçi ve siyasetçi. Teorik fizik alanında çalıştı. TÜBİTAK başkanlığı ve başbakan yardımcılığı yaptı.',
    },
    {
      'name': 'Asım Orhan Barut',
      'info': 'Türk teorik fizikçi. Kuantum mekaniği ve parçacık fiziği üzerine çalıştı. Colorado Üniversitesi\'nde profesörlük yaptı.',
    },
    {
      'name': 'Mehmet Öz',
      'info': 'Türk-Amerikalı kalp cerrahı. Televizyon programlarıyla sağlık konularında halkı bilinçlendirdi. Columbia Üniversitesi\'nde profesör.',
    },
    {
      'name': 'Canan Dağdeviren',
      'info': 'Türk fizik mühendisi. Esnek elektronik cihazlar geliştirdi. MIT\'de araştırmacı. Forbes\'un "30 Under 30" listesinde yer aldı.',
    },
    {
      'name': 'Yaşar Kemal',
      'info': 'Türk yazar. "İnce Memed" serisiyle tanınır. Edebiyat dünyasında önemli bir yere sahip.',
    },
    {
      'name': 'Sabahattin Ali',
      'info': 'Türk yazar ve şair. "Kuyucaklı Yusuf" ve "Kürk Mantolu Madonna" gibi eserleriyle tanınır.',
    },
    {
      'name': 'Ahmet Hamdi Tanpınar',
      'info': 'Türk yazar ve şair. "Saatleri Ayarlama Enstitüsü" ve "Huzur" gibi eserleriyle tanınır.',
    },
    {
      'name': 'Zeki Müren',
      'info': 'Türk sanat müziği sanatçısı. "Sanat Güneşi" unvanıyla anıldı. Türk müziğinin önemli isimlerinden.',
    },
    {
      'name': 'Münir Nurettin Selçuk',
      'info': 'Türk sanat müziği bestekarı ve yorumcusu. Klasik Türk müziğinin önemli temsilcilerinden.',
    },
    {
      'name': 'Neşet Ertaş',
      'info': 'Türk halk müziği sanatçısı. "Bozlak" türünün önemli temsilcisi. "Baba" unvanıyla anıldı.',
    },
  ];
  
  /// Historical Turkish states with years and flag emojis
  static final List<Map<String, String>> _turkishStates = [
    {
      'name': 'Göktürk Kağanlığı',
      'years': '552-744',
      'flag': '🏹',
      'info': 'Orta Asya\'da kurulan ilk Türk devleti. Türk adını kullanan ilk devlet. Doğu ve Batı olmak üzere ikiye ayrıldı.',
    },
    {
      'name': 'Uygur Kağanlığı',
      'years': '744-840',
      'flag': '🦅',
      'info': 'Göktürklerden sonra Orta Asya\'da kurulan Türk devleti. Tarım ve ticaretle gelişti. Maniheizm dinini benimsedi.',
    },
    {
      'name': 'Karahanlılar',
      'years': '840-1212',
      'flag': '⚔️',
      'info': 'İslam\'ı kabul eden ilk Türk devleti. Türk-İslam kültürünün gelişmesinde önemli rol oynadı. Kaşgar ve Semerkant merkezliydi.',
    },
    {
      'name': 'Gazneliler',
      'years': '963-1186',
      'flag': '🛡️',
      'info': 'Hindistan\'a kadar genişleyen Türk devleti. Sultan Mahmud döneminde en parlak çağını yaşadı. Fars ve Türk kültürünü birleştirdi.',
    },
    {
      'name': 'Büyük Selçuklu İmparatorluğu',
      'years': '1037-1194',
      'flag': '👑',
      'info': 'Anadolu\'nun kapılarını Türklere açan devlet. Malazgirt Zaferi ile Anadolu\'nun fethi başladı. Nizamiye Medreseleri kuruldu.',
    },
    {
      'name': 'Anadolu Selçuklu Devleti',
      'years': '1077-1308',
      'flag': '🏛️',
      'info': 'Anadolu\'da kurulan ilk Türk devleti. Konya merkezli. Çifte Minareli Medrese, İnce Minareli Medrese gibi eserler bıraktı.',
    },
    {
      'name': 'Osmanlı İmparatorluğu',
      'years': '1299-1922',
      'flag': '🌙',
      'info': 'Üç kıtaya yayılan büyük imparatorluk. 600 yıldan fazla hüküm sürdü. İstanbul\'un fethi ile Orta Çağ\'ı kapattı, Yeni Çağ\'ı açtı.',
    },
    {
      'name': 'Timur İmparatorluğu',
      'years': '1370-1507',
      'flag': '⚡',
      'info': 'Timur tarafından kurulan devlet. Semerkant merkezli. Bilim ve sanat alanında büyük gelişmeler gösterdi.',
    },
    {
      'name': 'Babür İmparatorluğu',
      'years': '1526-1858',
      'flag': '🐘',
      'info': 'Hindistan\'da kurulan Türk devleti. Babür Şah tarafından kuruldu. Tac Mahal gibi dünya çapında eserler bıraktı.',
    },
    {
      'name': 'Altın Orda Devleti',
      'years': '1242-1502',
      'flag': '🐎',
      'info': 'Cengiz Han\'ın torunları tarafından kurulan devlet. Volga bölgesinde hüküm sürdü. Rus prensliklerini etkisi altına aldı.',
    },
    {
      'name': 'Harezmşahlar',
      'years': '1077-1231',
      'flag': '🗡️',
      'info': 'Orta Asya\'da kurulan Türk devleti. Harzem bölgesinde hüküm sürdü. Moğol istilasına kadar güçlü bir devletti.',
    },
    {
      'name': 'Akkoyunlular',
      'years': '1378-1508',
      'flag': '🐑',
      'info': 'Doğu Anadolu ve İran\'da hüküm süren Türk devleti. Uzun Hasan döneminde en güçlü çağını yaşadı.',
    },
  ];
  
  /// Modern Turkish Republics and active Turkish states
  static final List<Map<String, String>> _modernTurkishStates = [
    {
      'name': 'Türkiye Cumhuriyeti',
      'years': '1923-',
      'flag': '🇹🇷',
      'info': 'Mustafa Kemal Atatürk önderliğinde kurulan modern Türk devleti. Laik, demokratik ve sosyal hukuk devleti. NATO ve AB üyesi.',
    },
    {
      'name': 'Azerbaycan Cumhuriyeti',
      'years': '1991-',
      'flag': '🇦🇿',
      'info': 'Kafkasya\'da bağımsız Türk devleti. Bakü başkent. Petrol ve doğalgaz zengini. Türkiye ile kardeş ülke.',
    },
    {
      'name': 'Kazakistan Cumhuriyeti',
      'years': '1991-',
      'flag': '🇰🇿',
      'info': 'Orta Asya\'nın en büyük Türk devleti. Astana başkent. Zengin doğal kaynaklara sahip. Türk Konseyi üyesi.',
    },
    {
      'name': 'Kırgızistan Cumhuriyeti',
      'years': '1991-',
      'flag': '🇰🇬',
      'info': 'Orta Asya\'da bağımsız Türk devleti. Bişkek başkent. Manas Destanı\'nın vatanı. Türk Konseyi üyesi.',
    },
    {
      'name': 'Özbekistan Cumhuriyeti',
      'years': '1991-',
      'flag': '🇺🇿',
      'info': 'Orta Asya\'da nüfusu en fazla Türk devleti. Taşkent başkent. Semerkant ve Buhara gibi tarihi şehirlere sahip.',
    },
    {
      'name': 'Türkmenistan',
      'years': '1991-',
      'flag': '🇹🇲',
      'info': 'Orta Asya\'da bağımsız Türk devleti. Aşkabat başkent. Doğalgaz zengini. Tarafsızlık statüsüne sahip.',
    },
    {
      'name': 'Doğu Türkistan (Uygur Özerk Bölgesi)',
      'years': '1955-',
      'flag': '🌙',
      'info': 'Çin\'in Sincan Uygur Özerk Bölgesi. Uygur Türklerinin anavatanı. Kaşgar ve Hotan gibi tarihi şehirlere sahip.',
    },
    {
      'name': 'Kuzey Kıbrıs Türk Cumhuriyeti',
      'years': '1983-',
      'flag': '🇹🇷',
      'info': 'Kıbrıs adasında kurulan Türk devleti. Lefkoşa başkent. Sadece Türkiye tarafından tanınan devlet.',
    },
    {
      'name': 'Tataristan Cumhuriyeti',
      'years': '1992-',
      'flag': '🏛️',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Kazan başkent. Tatar Türklerinin anavatanı.',
    },
    {
      'name': 'Başkurdistan Cumhuriyeti',
      'years': '1992-',
      'flag': '🐝',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Ufa başkent. Başkurt Türklerinin anavatanı.',
    },
    {
      'name': 'Çuvaşistan Cumhuriyeti',
      'years': '1992-',
      'flag': '⭐',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Çeboksarı başkent. Çuvaş Türklerinin anavatanı.',
    },
    {
      'name': 'Saha (Yakut) Cumhuriyeti',
      'years': '1992-',
      'flag': '❄️',
      'info': 'Rusya Federasyonu içinde en büyük özerk cumhuriyet. Yakutsk başkent. Yakut Türklerinin anavatanı.',
    },
    {
      'name': 'Tuva Cumhuriyeti',
      'years': '1993-',
      'flag': '🏔️',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Kızıl başkent. Tuva Türklerinin anavatanı.',
    },
    {
      'name': 'Altay Cumhuriyeti',
      'years': '1992-',
      'flag': '⛰️',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Gorno-Altaysk başkent. Altay Türklerinin anavatanı.',
    },
    {
      'name': 'Hakasya Cumhuriyeti',
      'years': '1992-',
      'flag': '🌲',
      'info': 'Rusya Federasyonu içinde özerk Türk cumhuriyeti. Abakan başkent. Hakas Türklerinin anavatanı.',
    },
  ];
  
  /// Get random Turkish culture information
  /// Returns either a historical figure, historical Turkish state, or modern Turkish state
  /// Ensures no duplicate information is shown until all have been shown
  static Map<String, String> getRandomInfo() {
    final rand = _random.nextDouble();
    
    // Check if all info has been shown, if so reset
    final totalInfoCount = _turkishFigures.length + _turkishStates.length + _modernTurkishStates.length;
    if (_shownInfoKeys.length >= totalInfoCount) {
      _shownInfoKeys.clear();
    }
    
    Map<String, String>? selectedInfo;
    String? infoKey;
    int attempts = 0;
    const maxAttempts = 100; // Prevent infinite loop
    
    // 50% chance for historical figure, 25% for historical state, 25% for modern state
    while (selectedInfo == null && attempts < maxAttempts) {
      attempts++;
      
      if (rand < 0.5) {
        // Try to get a figure that hasn't been shown
        final availableFigures = _turkishFigures.where((f) {
          final key = 'figure_${f['name']}';
          return !_shownInfoKeys.contains(key);
        }).toList();
        
        if (availableFigures.isEmpty) {
          // All figures shown, reset and try again
          _shownInfoKeys.removeWhere((key) => key.startsWith('figure_'));
          if (_turkishFigures.isNotEmpty) {
            final figure = _turkishFigures[_random.nextInt(_turkishFigures.length)];
            infoKey = 'figure_${figure['name']}';
            selectedInfo = {
              'type': 'figure',
              'title': figure['name']!,
              'content': figure['info']!,
            };
          }
        } else {
          final figure = availableFigures[_random.nextInt(availableFigures.length)];
          infoKey = 'figure_${figure['name']}';
          selectedInfo = {
            'type': 'figure',
            'title': figure['name']!,
            'content': figure['info']!,
          };
        }
      } else if (rand < 0.75) {
        // Try to get a historical state that hasn't been shown
        final availableStates = _turkishStates.where((s) {
          final key = 'state_${s['name']}';
          return !_shownInfoKeys.contains(key);
        }).toList();
        
        if (availableStates.isEmpty) {
          // All states shown, reset and try again
          _shownInfoKeys.removeWhere((key) => key.startsWith('state_'));
          if (_turkishStates.isNotEmpty) {
            final state = _turkishStates[_random.nextInt(_turkishStates.length)];
            infoKey = 'state_${state['name']}';
            selectedInfo = {
              'type': 'state',
              'title': '${state['flag']} ${state['name']}',
              'content': '${state['info']!}\n\nYıllar: ${state['years']}',
            };
          }
        } else {
          final state = availableStates[_random.nextInt(availableStates.length)];
          infoKey = 'state_${state['name']}';
          selectedInfo = {
            'type': 'state',
            'title': '${state['flag']} ${state['name']}',
            'content': '${state['info']!}\n\nYıllar: ${state['years']}',
          };
        }
      } else {
        // Try to get a modern state that hasn't been shown
        final availableModernStates = _modernTurkishStates.where((s) {
          final key = 'modern_state_${s['name']}';
          return !_shownInfoKeys.contains(key);
        }).toList();
        
        if (availableModernStates.isEmpty) {
          // All modern states shown, reset and try again
          _shownInfoKeys.removeWhere((key) => key.startsWith('modern_state_'));
          if (_modernTurkishStates.isNotEmpty) {
            final modernState = _modernTurkishStates[_random.nextInt(_modernTurkishStates.length)];
            infoKey = 'modern_state_${modernState['name']}';
            selectedInfo = {
              'type': 'modern_state',
              'title': '${modernState['flag']} ${modernState['name']}',
              'content': '${modernState['info']!}\n\nYıllar: ${modernState['years']}',
            };
          }
        } else {
          final modernState = availableModernStates[_random.nextInt(availableModernStates.length)];
          infoKey = 'modern_state_${modernState['name']}';
          selectedInfo = {
            'type': 'modern_state',
            'title': '${modernState['flag']} ${modernState['name']}',
            'content': '${modernState['info']!}\n\nYıllar: ${modernState['years']}',
          };
        }
      }
    }
    
    // Fallback if no info was selected (shouldn't happen)
    if (selectedInfo == null) {
      final figure = _turkishFigures[_random.nextInt(_turkishFigures.length)];
      infoKey = 'figure_${figure['name']}';
      selectedInfo = {
        'type': 'figure',
        'title': figure['name']!,
        'content': figure['info']!,
      };
    }
    
    // Mark this info as shown
    if (infoKey != null) {
      _shownInfoKeys.add(infoKey);
    }
    
    return selectedInfo;
  }
}

