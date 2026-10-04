import 'package:flutter/widgets.dart';

import '../models/environment.dart';
import '../models/game_config.dart';
import '../models/game_object.dart';
import '../utils/format.dart';
import 'app_language.dart';

/// Every piece of text the player sees, in English and Turkish.
///
/// English is the default and the fallback. The English wording of the hints
/// and of the object / environment names is the source text kept next to the
/// data (`ObjectDefinition.label`, `Environment.ruleHint`...).
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) =>
      AppStrings(LanguageScope.controllerOf(context).value);

  bool get isTr => language == AppLanguage.tr;

  String _t(String en, String tr) => isTr ? tr : en;

  // --- Home -----------------------------------------------------------------

  String get appTitle => _t('Spatial Memory', 'Mekânsal Hafıza');
  String get titleTop => _t('SPATIAL', 'MEKÂNSAL');
  String get titleBottom => _t('MEMORY', 'HAFIZA');
  String get languageLabel => _t('Language', 'Dil');
  String get play => _t('PLAY', 'OYNA');

  String levelInfo(GameConfig config) {
    final fakes = config.fakeCount;
    if (isTr) {
      return '${config.objectCount} nesne · '
          '${config.memorizeSeconds} sn ezberleme · '
          '${config.placementSeconds} sn yerleştirme'
          '${fakes > 0 ? ' · $fakes sahte' : ''}';
    }
    return '${config.objectCount} objects · '
        '${config.memorizeSeconds}s to memorize · '
        '${config.placementSeconds}s to place'
        '${fakes > 0 ? ' · $fakes fake' : ''}';
  }

  // --- Difficulty -----------------------------------------------------------

  String difficultyName(GameConfig config) {
    if (!isTr) return config.name;
    return switch (config.id) {
      'easy' => 'Kolay',
      'medium' => 'Orta',
      'hard' => 'Zor',
      'expert' => 'Uzman',
      'extreme' => 'Ekstrem',
      _ => config.name,
    };
  }

  // --- Environments -----------------------------------------------------------

  String environmentName(Environment environment) {
    if (!isTr) return environment.name;
    return switch (environment.id) {
      'space_station' => 'Uzay İstasyonu',
      'island' => 'Ada',
      'laboratory' => 'Laboratuvar',
      'city' => 'Şehir',
      'camp' => 'Kamp',
      _ => environment.name,
    };
  }

  bool _noRotation(Environment environment, GameConfig config) =>
      environment.mechanic == EnvironmentMechanic.direction &&
      !config.rotationEnabled;

  String ruleHint(Environment environment, GameConfig config) {
    if (!isTr) return environment.ruleHintFor(config);
    if (_noRotation(environment, config)) {
      return config.id == 'survival'
          ? 'Her nesnenin yerini aklında tut. '
              'Nesneleri çevirme sonraki turlarda başlar.'
          : 'Her nesnenin yerini aklında tut. '
              'Nesneleri çevirme Zor seviyede başlar.';
    }
    return switch (environment.id) {
      'space_station' =>
        'Antenler ve çanaklar bir yöne bakar. Nereye baktıklarını aklında tut.',
      'island' =>
        'Bazı nesneler başka bir nesneden belirli uzaklıkta durur. '
            'Bunu aklında tut.',
      'laboratory' =>
        'Şekil aynı, renk farklı. Hangi rengin nerede olduğunu aklında tut.',
      'city' =>
        'Araçların bir yönü var. Her birinin hangi yöne baktığını aklında tut.',
      'camp' =>
        'Bazı nesneler birbirine aittir. Hangilerinin yakın durduğunu '
            'aklında tut.',
      _ => environment.ruleHint,
    };
  }

  String placeHint(Environment environment, GameConfig config) {
    if (!isTr) return environment.placeHintFor(config);
    if (_noRotation(environment, config)) {
      return 'Her nesneyi yerine sürükle.';
    }
    return switch (environment.id) {
      'space_station' =>
        'Okla işaretli bir nesneyi çevirmek için yerleştirdikten sonra '
            'ona dokun.',
      'island' => 'Eş nesneler birbirine olan uzaklıklarıyla da puanlanır.',
      'laboratory' => 'Her şişenin kendi yeri var. Etiketlere bak.',
      'city' => 'Yerleştirdiğin aracı çevirmek için ona dokun.',
      'camp' => 'Birbirine ait nesneleri eskisi gibi yakın tut.',
      _ => environment.placeHint,
    };
  }

  // --- Objects ------------------------------------------------------------------

  /// Turkish names by object id. Ids that appear in several environments
  /// (camera, map, campfire...) share one name.
  static const Map<String, String> objectLabelsTr = {
    // Space station
    'computer': 'Bilgisayar',
    'battery': 'Pil',
    'helmet': 'Kask',
    'toolbox': 'Alet çantası',
    'satellite': 'Uydu',
    'book': 'Kitap',
    'coffee': 'Kahve',
    'cable': 'Kablo',
    'monitor': 'Monitör',
    'antenna': 'Anten',
    'flashlight': 'El feneri',
    'camera': 'Kamera',
    'headset': 'Kulaklık',
    'keyboard': 'Klavye',
    'chip': 'Çip',
    'watch': 'Saat',
    'rocket': 'Roket',
    'solar_panel': 'Güneş paneli',
    // Island
    'palm_tree': 'Palmiye ağacı',
    'treasure_chest': 'Hazine sandığı',
    'boat': 'Tekne',
    'anchor': 'Çapa',
    'umbrella': 'Şemsiye',
    'compass': 'Pusula',
    'flag': 'Bayrak',
    'map': 'Harita',
    'rock': 'Kaya',
    'campfire': 'Kamp ateşi',
    'fish': 'Balık',
    'surfboard': 'Sörf tahtası',
    'sun': 'Güneş',
    'bottle': 'Şişe',
    'lantern': 'Fener',
    'waves': 'Dalgalar',
    'binoculars': 'Dürbün',
    // Laboratory
    'bottle_red': 'Kırmızı şişe',
    'bottle_blue': 'Mavi şişe',
    'bottle_green': 'Yeşil şişe',
    'microscope': 'Mikroskop',
    'syringe': 'Şırınga',
    'thermometer': 'Termometre',
    'notebook': 'Defter',
    'lamp': 'Lamba',
    'scale': 'Terazi',
    'timer': 'Kronometre',
    'droplet': 'Damla',
    'calculator': 'Hesap makinesi',
    'magnifier': 'Büyüteç',
    'clipboard': 'Not panosu',
    'burner': 'Bunsen beki',
    'gloves': 'Eldiven',
    // City
    'car': 'Araba',
    'bus': 'Otobüs',
    'taxi': 'Taksi',
    'truck': 'Kamyon',
    'bicycle': 'Bisiklet',
    'scooter': 'Skuter',
    'traffic_light': 'Trafik ışığı',
    'building': 'Bina',
    'hydrant': 'Yangın musluğu',
    'parking': 'Otopark',
    'tree': 'Ağaç',
    'motorcycle': 'Motosiklet',
    'shuttle': 'Minibüs',
    'gas_station': 'Akaryakıt istasyonu',
    'bench': 'Bank',
    'cafe': 'Kafe',
    'stop_sign': 'Dur tabelası',
    'mailbox': 'Posta kutusu',
    // Camp
    'tent': 'Çadır',
    'backpack': 'Sırt çantası',
    'firewood': 'Odun',
    'fishing_rod': 'Olta',
    'cooler': 'Soğutucu',
    'boots': 'Bot',
    'sleeping_bag': 'Uyku tulumu',
    'water_bottle': 'Su matarası',
    'radio': 'Radyo',
    'music': 'Müzik',
    'saw': 'Testere',
    'cookie': 'Kurabiye',
  };

  String objectName(ObjectDefinition definition) =>
      isTr ? (objectLabelsTr[definition.id] ?? definition.label) : definition.label;

  // --- Memorize phase -----------------------------------------------------------

  String get rememberScene => _t('Remember the scene', 'Sahneyi aklında tut');
  String get placeObjects => _t('Place the objects', 'Nesneleri yerleştir');
  String get skipMemorize =>
      _t("I'm ready, start placing", 'Hazırım, yerleştirmeye geç');
  String get defaultHint => _t(
        'Study the positions. The objects will disappear.',
        'Konumları incele. Nesneler kaybolacak.',
      );

  String relationHint(
    ObjectDefinition child,
    ObjectDefinition anchor,
    String meters,
    OffsetSide side,
  ) {
    if (isTr) {
      final place = switch (side) {
        OffsetSide.right => 'sağında',
        OffsetSide.left => 'solunda',
        OffsetSide.below => 'altında',
        OffsetSide.above => 'üstünde',
      };
      // "nesnesinin" keeps the sentence correct for every object name.
      return '${objectName(child)}, ${objectName(anchor)} nesnesinin '
          '$meters $place.';
    }
    final phrase = switch (side) {
      OffsetSide.right => 'to the right of',
      OffsetSide.left => 'to the left of',
      OffsetSide.below => 'below',
      OffsetSide.above => 'above',
    };
    return 'The ${child.label.toLowerCase()} is $meters $phrase '
        'the ${anchor.label.toLowerCase()}.';
  }

  String clusterHint(List<ObjectDefinition> members) {
    if (isTr) {
      final names = [for (final m in members) objectName(m)];
      final joined = names.length <= 1
          ? names.join()
          : '${names.sublist(0, names.length - 1).join(', ')} ve ${names.last}';
      return '$joined birbirine yakındı.';
    }
    final names = [for (final m in members) m.label.toLowerCase()];
    final joined = names.length <= 1
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    return 'The $joined were close together.';
  }

  String fakeWarning(int count) => isTr
      ? '$count sahte nesne tepsiye karışacak. Onları yerleştirme.'
      : '$count fake ${count == 1 ? 'object' : 'objects'} will be mixed into '
          "the tray. Don't place them.";

  // --- Place phase --------------------------------------------------------------

  String get fakePlaceNote => _t(
        'Some objects in the tray are fake.',
        'Tepsideki bazı nesneler sahte.',
      );
  String get allPlaced => _t(
        'All placed. Tap Finish when ready.',
        'Hepsi yerleştirildi. Hazır olunca Bitir\'e dokun.',
      );
  String finish(int placed, int total) =>
      _t('Finish ($placed/$total)', 'Bitir ($placed/$total)');


  // --- Progress, stars, records -----------------------------------------------

  String get roundPerfect => _t('PERFECT!', 'MÜKEMMEL!');
  String get bonusStarGift => _t('Bonus star!', 'Hediye yıldız!');

  String get newRecord => _t('NEW RECORD!', 'YENİ REKOR!');
  String levelUnlocked(String name) =>
      _t('$name unlocked', '$name seviyesi açıldı');
  String nextLevel(String name) =>
      _t('Next level ($name)', 'Sonraki seviye ($name)');

  String starsTotal(int stars) => '★ $stars';

  /// Stats under the level picker. [rounds] == 0 means never played.
  String levelStats(int bestScore, int averagePercent, int rounds) {
    if (rounds == 0) return _t('Not played yet', 'Henüz oynanmadı');
    return _t(
      'Best $bestScore · Avg $averagePercent% · $rounds rounds',
      'En iyi $bestScore · Ort. %$averagePercent · $rounds tur',
    );
  }

  String levelLocked(String previous, int stars) => _t(
        'Earn $stars ★ on $previous to unlock',
        'Açmak için $previous seviyesinde $stars ★ kazan',
      );
  String environmentLocked(int starsNeeded, int starsHave) => _t(
        'Locked: collect $starsNeeded ★ in total ($starsHave so far)',
        'Kilitli: toplam $starsNeeded ★ topla (şu an $starsHave)',
      );
  String get soundOn =>
      _t('Music, sound & vibration: on', 'Müzik, ses ve titreşim: açık');
  String get soundOff =>
      _t('Music, sound & vibration: off', 'Müzik, ses ve titreşim: kapalı');

  String get soundSettings => _t('Sound settings', 'Ses ayarları');
  String get soundSwitchLabel =>
      _t('Sound, music & vibration', 'Ses, müzik ve titreşim');
  String get musicVolumeLabel => _t('Music volume', 'Müzik seviyesi');
  String get close => _t('Close', 'Kapat');

  // --- Survival ---------------------------------------------------------------

  String get continueRun => _t('CONTINUE', 'DEVAM ET');
  String continueRunInfo(int round, int score) => _t(
        'Saved run: round $round · $score points',
        'Kayıtlı oyun: tur $round · $score puan',
      );
  String get newRun => _t('Start over', 'Baştan başla');
  String get runSaved => _t(
        'Progress saved. You can continue next time.',
        'İlerleme kaydedildi. Bir sonraki sefer kaldığın yerden devam edebilirsin.',
      );
  String get scoreboardTitle => _t('SCOREBOARD', 'SKOR TABLOSU');
  String get scoreLabel => _t('SCORE', 'PUAN');
  String get roundLabel => _t('ROUND', 'TUR');
  String get bestLabel => _t('BEST', 'EN İYİ');

  String get survival => _t('SURVIVAL', 'HAYATTA KALMA');
  String survivalInfo(int startObjects, int rampObjects, int minPercent) => _t(
        'Starts with $startObjects object and grows to $rampObjects, then '
            'objects start turning. After that every round adds an object or '
            'turns one more. The run ends when accuracy falls below '
            '$minPercent%.',
        '$startObjects nesneyle başlar, $rampObjects nesneye kadar çıkar, '
            'sonra nesneler dönmeye başlar. Sonrasında her tur ya bir nesne '
            'eklenir ya da bir nesne daha döner. Doğruluk %$minPercent '
            'altına düşünce oyun biter.',
      );
  String survivalRecord(int bestRound, int bestScore) {
    if (bestRound == 0 && bestScore == 0) {
      return _t('No run yet', 'Henüz oynanmadı');
    }
    return _t(
      'Best: $bestRound rounds · $bestScore points',
      'En iyi: $bestRound tur · $bestScore puan',
    );
  }

  String survivalRound(int round, int objects, [int rotated = 0]) => _t(
        'Round $round · $objects ${objects == 1 ? 'object' : 'objects'}'
            '${rotated > 0 ? ' · $rotated rotating' : ''}',
        'Tur $round · $objects nesne'
            '${rotated > 0 ? ' · $rotated dönen' : ''}',
      );
  String survivalTotal(int total) =>
      _t('Total $total', 'Toplam $total');
  String get survivalCleared => _t('Round cleared!', 'Tur geçildi!');
  String get survivalOver => _t('GAME OVER', 'OYUN BİTTİ');
  String survivalOverDetail(int cleared, int total, int minPercent) => _t(
        'Accuracy fell below $minPercent%. You cleared $cleared '
            '${cleared == 1 ? 'round' : 'rounds'} · $total points.',
        'Doğruluk %$minPercent altına düştü. $cleared tur geçtin · '
            '$total puan.',
      );
  String survivalNextInfo(int objects, [int rotated = 0]) => _t(
        'Next round: $objects ${objects == 1 ? 'object' : 'objects'}'
            '${rotated > 0 ? ', $rotated of them rotating' : ''}',
        'Sonraki tur: $objects nesne'
            '${rotated > 0 ? ', $rotated tanesi dönüyor' : ''}',
      );
  String get survivalMaxInfo => _t(
        'Maximum size reached. Keep going!',
        'En büyük boyuta ulaşıldı. Devam et!',
      );
  String nextRound(int round) => _t('Next round ($round)', 'Sonraki tur ($round)');
  String get endRun => _t('End run', 'Oyunu bitir');

  // --- Tutorial ---------------------------------------------------------------

  String get howToPlay => _t('How to play', 'Nasıl oynanır');
  String get tutorialSkip => _t('Skip', 'Geç');
  String tutorialStep(int step, int total) => '$step/$total';
  String get tutorialMemorize => _t(
        'Memorize where each object stands and where its arrow points. '
            'There is no timer here. Tap the button when you are ready.',
        'Her nesnenin yerini ve okunun yönünü aklında tut. '
            'Burada süre yok. Hazır olunca düğmeye dokun.',
      );
  String get tutorialDrag => _t(
        'Drag each object from the tray back to where it was.',
        'Her nesneyi tepsiden alıp eski yerine sürükle.',
      );
  String get tutorialRotate => _t(
        'Objects with an arrow also have a direction. Tap a placed object '
            'to turn it until the arrow points the right way.',
        'Okla işaretli nesnelerin bir yönü de var. Yerleştirdiğin nesneye '
            'dokunarak okunu doğru yöne çevir.',
      );
  String get tutorialFake => _t(
        'Anything still in the tray was never in the scene. It is a fake! '
            'Leave it there, then tap Finish.',
        'Tepside kalan nesne sahnede hiç yoktu. Sahte! '
            'Onu yerleştirme ve Bitir\'e dokun.',
      );
  String get tutorialDoneTitle => _t('You are ready!', 'Hazırsın!');
  String get tutorialDoneBody => _t(
        'Every place has its own rule. Here is a reminder:',
        'Her mekânın kendi kuralı var. Kısa bir hatırlatma:',
      );
  String get startPlaying => _t('Start playing', 'Oynamaya başla');

  // --- Result ---------------------------------------------------------------------

  String get resultTitle => _t('MEMORY RESULT', 'HAFIZA SONUCU');
  String objectsPlaced(int placed, int total) => _t(
        '$placed / $total objects placed',
        '$placed / $total nesne yerleştirildi',
      );
  String flawless(int total) => _t(
        'FLAWLESS! All $total perfect',
        'KUSURSUZ! $total nesnenin hepsi mükemmel',
      );
  String perfectSummary(int perfect, int total, int percent) => _t(
        '$perfect / $total perfect ($percent%+)',
        '$perfect / $total mükemmel (%$percent+)',
      );
  String get perfectChip => _t('PERFECT!', 'MÜKEMMEL!');
  String get notPlaced => _t('Not placed', 'Yerleştirilmedi');

  String get legendActual => _t('Actual position', 'Gerçek konum');
  String get legendYours => _t('Your position', 'Senin konumun');
  String get legendPerfect => _t('Perfect', 'Mükemmel');
  String get legendFake => _t('Fake object', 'Sahte nesne');

  String get directionExact => _t('Direction: exact', 'Yön: tam');
  String directionOff(int degrees) =>
      _t('Direction: $degrees° off', 'Yön: $degrees° sapma');
  String get scoredByPartner => _t(
        'Scored by distance to partner',
        'Eşine olan uzaklıkla puanlandı',
      );
  String get scoredByGroup =>
      _t('Scored by group shape', 'Grup şekliyle puanlandı');

  String fakeSectionTitle(int avoided, int total) => _t(
        'Fake objects avoided: $avoided / $total',
        'Elenen sahte nesne: $avoided / $total',
      );
  String get fakePlacedDetail => _t(
        'Fake object, placed by mistake',
        'Sahte nesne, yanlışlıkla yerleştirildi',
      );
  String get fakeAvoidedDetail => _t(
        'Fake object, correctly left out',
        'Sahte nesne, doğru şekilde bırakıldı',
      );

  String get objectScore => _t('Object score', 'Nesne puanı');
  String get timeBonus => _t('Time bonus', 'Süre bonusu');
  String perfectBonus(int count, int each) => _t(
        'Perfect bonus ($count × $each)',
        'Mükemmel bonusu ($count × $each)',
      );
  String get flawlessBonus => _t('Flawless bonus', 'Kusursuzluk bonusu');
  String fakePenalty(int count, int each) => _t(
        'Fake object penalty ($count × $each)',
        'Sahte nesne cezası ($count × $each)',
      );
  String difficultyRow(String name) =>
      _t('Difficulty ($name)', 'Zorluk ($name)');
  String get finalScore => _t('FINAL SCORE', 'TOPLAM PUAN');
  String get playAgain => _t('Play again', 'Tekrar oyna');
  String get mainMenu => _t('Main menu', 'Ana menü');
}
