import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ar'),
    Locale('ur'),
    Locale('ps'),
  ];

  static const Map<String, Map<String, String>> _values = {
    'de': {
      'appName': 'Salaty',
      'tagline': 'Weniger Ablenkung. Mehr Salah.',
      'getStarted': "Los geht's",
      'home': 'Home',
      'tracker': 'Tracker',
      'qibla': 'Qibla',
      'settings': 'Einstellungen',
      'nextPrayer': 'Nächstes Gebet',
      'today': 'Heute',
      'prayed': 'Gebetet',
      'snoozed': 'Verschoben',
      'skipped': 'Übersprungen',
      'missed': 'Nicht bestätigt',
      'upcoming': 'Bevorstehend',
      'active': 'Aktiv',
      'pending': 'Erinnerung offen',
      'refresh': 'Aktualisieren',
      'location': 'Standort',
      'currentLocation': 'Aktueller Standort',
      'useLocation': 'Standort verwenden',
      'chooseCity': 'Stadt auswählen',
      'city': 'Stadt',
      'country': 'Land',
      'continue': 'Weiter',
      'back': 'Zurück',
      'prayerTimes': 'Gebetszeiten',
      'timesQuestion':
          'Stimmen diese Zeiten ungefähr mit deiner Moschee überein?',
      'yes': 'Ja',
      'adjust': 'Anpassen',
      'graceQuestion': 'Wann sollen wir dich stärker erinnern?',
      'minutesAfter': 'Minuten nach Gebetsbeginn',
      'permissions': 'Berechtigungen',
      'permissionExplain': 'Wir fragen Berechtigungen erst dann an, wenn sie für eine Funktion gebraucht werden.',
      'finish': 'Fertig',
      'confirmPrayer': 'Ich habe gebetet',
      'snooze': '20 Minuten später erinnern',
      'snoozeIn': 'In {minutes} Minuten erinnern',
      'skipToday': 'Heute überspringen',
      'skipConfirmTitle': 'Erinnerung beenden?',
      'skipConfirmBody':
          'Möchtest du die Erinnerung für dieses Gebet wirklich beenden?',
      'noPrayLater': 'Nein, ich bete noch',
      'yesEnd': 'Ja, Erinnerung beenden',
      'reminderBody': 'Du wolltest dir Zeit für dein Gebet nehmen. Lege dein Handy für ein paar Minuten weg und bete.',
      'accepted': 'Alhamdulillah 🤍',
      'week': 'Diese Woche',
      'month': 'Monat',
      'confirmedPrayers': 'Bestätigte Gebete',
      'calculationMethod': 'Berechnungsmethode',
      'madhhab': 'Asr-Berechnung',
      'standard': 'Standard',
      'hanafi': 'Hanafi',
      'highLatitude': 'Hohe Breitengrade',
      'gracePeriod': 'Erinnerungsfrist',
      'snoozeDuration': 'Snooze-Dauer',
      'confirmationText': 'Bestätigungstext',
      'softReminder': 'Sanfte Erinnerung nach Überspringen',
      'theme': 'Darstellung',
      'system': 'System',
      'light': 'Hell',
      'dark': 'Dunkel',
      'language': 'Sprache',
      'languageChoose': 'Wähle die Sprache für Salaty.',
      'german': 'Deutsch',
      'english': 'Englisch',
      'arabic': 'Arabisch',
      'notificationPermission': 'Benachrichtigungen erlauben',
      'exactAlarmPermission': 'Präzise Erinnerungen erlauben',
      'qiblaDirection': 'Qibla-Richtung',
      'calibrate': 'Bewege dein Handy in Form einer Acht, wenn der Kompass ungenau wirkt.',
      'noCompass': 'Kein Kompass-Sensor verfügbar. Die Qibla-Richtung wird in Grad angezeigt.',
      'needLocation': 'Bitte zuerst einen Standort festlegen.',
      'offlineCache': 'Offline-Cache wird verwendet.',
      'retry': 'Erneut versuchen',
      'noData': 'Für heute sind keine zuverlässigen Gebetszeiten gespeichert.',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'manualAdjustments': 'Minutenkorrekturen',
      'maxSnoozes': 'Maximale Snoozes',
      'unlimited': 'Unbegrenzt',
      'genericError': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
      'locationError': 'Der Standort konnte nicht bestimmt werden. Du kannst stattdessen eine Stadt auswählen.',
      'networkError': 'Die Gebetszeiten konnten gerade nicht geladen werden. Gespeicherte Daten werden verwendet, wenn sie verfügbar sind.',
      'prayerDataError': 'Die Gebetszeiten konnten nicht zuverlässig verarbeitet werden. Bitte versuche es erneut.',
      'snoozeUnavailable': 'Dieses Gebet kann nicht weiter verschoben werden.',
      'prayerFirst': 'Gebet zuerst, Handy danach.',
      'heading': 'Ausrichtung',
      'minutesValue': '{value} Min.',
    },
    'en': {
      'appName': 'Salaty',
      'tagline': 'Less distraction. More Salah.',
      'getStarted': 'Get started',
      'home': 'Home',
      'tracker': 'Tracker',
      'qibla': 'Qibla',
      'settings': 'Settings',
      'nextPrayer': 'Next prayer',
      'today': 'Today',
      'prayed': 'Prayed',
      'snoozed': 'Snoozed',
      'skipped': 'Skipped',
      'missed': 'Not confirmed',
      'upcoming': 'Upcoming',
      'active': 'Active',
      'pending': 'Reminder pending',
      'refresh': 'Refresh',
      'location': 'Location',
      'currentLocation': 'Current location',
      'useLocation': 'Use my location',
      'chooseCity': 'Choose city',
      'city': 'City',
      'country': 'Country',
      'continue': 'Continue',
      'back': 'Back',
      'prayerTimes': 'Prayer times',
      'timesQuestion': 'Do these times roughly match your local mosque?',
      'yes': 'Yes',
      'adjust': 'Adjust',
      'graceQuestion': 'When should we remind you more strongly?',
      'minutesAfter': 'minutes after prayer begins',
      'permissions': 'Permissions',
      'permissionExplain':
          'We only request permissions when a feature actually needs them.',
      'finish': 'Finish',
      'confirmPrayer': 'I have prayed',
      'snooze': 'Remind me in 20 minutes',
      'snoozeIn': 'Remind me in {minutes} minutes',
      'skipToday': 'Skip today',
      'skipConfirmTitle': 'End reminder?',
      'skipConfirmBody': 'Do you really want to end reminders for this prayer?',
      'noPrayLater': 'No, I will pray',
      'yesEnd': 'Yes, end reminder',
      'reminderBody': 'You wanted to make time for prayer. Put your phone down for a few minutes and pray.',
      'accepted': 'Alhamdulillah 🤍',
      'week': 'This week',
      'month': 'Month',
      'confirmedPrayers': 'Confirmed prayers',
      'calculationMethod': 'Calculation method',
      'madhhab': 'Asr calculation',
      'standard': 'Standard',
      'hanafi': 'Hanafi',
      'highLatitude': 'High latitude rule',
      'gracePeriod': 'Grace period',
      'snoozeDuration': 'Snooze duration',
      'confirmationText': 'Confirmation text',
      'softReminder': 'Gentle reminder after skip',
      'theme': 'Appearance',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'languageChoose': 'Choose the language for Salaty.',
      'german': 'German',
      'english': 'English',
      'arabic': 'Arabic',
      'notificationPermission': 'Allow notifications',
      'exactAlarmPermission': 'Allow precise reminders',
      'qiblaDirection': 'Qibla direction',
      'calibrate':
          'Move your phone in a figure eight if the compass seems inaccurate.',
      'noCompass':
          'No compass sensor is available. Qibla is still shown in degrees.',
      'needLocation': 'Please set a location first.',
      'offlineCache': 'Using offline cache.',
      'retry': 'Try again',
      'noData': 'No reliable prayer times are stored for today.',
      'save': 'Save',
      'cancel': 'Cancel',
      'manualAdjustments': 'Minute adjustments',
      'maxSnoozes': 'Maximum snoozes',
      'unlimited': 'Unlimited',
      'genericError': 'Something went wrong. Please try again.',
      'locationError': 'Your location could not be determined. You can choose a city instead.',
      'networkError': 'Prayer times could not be loaded right now. Cached data will be used when available.',
      'prayerDataError':
          'Prayer times could not be processed reliably. Please try again.',
      'snoozeUnavailable': 'This prayer cannot be snoozed any further.',
      'prayerFirst': 'Prayer first, phone second.',
      'heading': 'Heading',
      'minutesValue': '{value} min',
    },
    'ar': {
      'appName': 'صلاتي',
      'tagline': 'تشتيت أقل. صلاة أكثر.',
      'getStarted': 'ابدأ',
      'home': 'الرئيسية',
      'tracker': 'المتابعة',
      'qibla': 'القبلة',
      'settings': 'الإعدادات',
      'nextPrayer': 'الصلاة القادمة',
      'today': 'اليوم',
      'prayed': 'تمت الصلاة',
      'snoozed': 'مؤجل',
      'skipped': 'تم الإنهاء',
      'missed': 'غير مؤكد',
      'upcoming': 'قادمة',
      'active': 'حان وقتها',
      'pending': 'تذكير مفتوح',
      'refresh': 'تحديث',
      'location': 'الموقع',
      'currentLocation': 'الموقع الحالي',
      'useLocation': 'استخدم موقعي',
      'chooseCity': 'اختر مدينة',
      'city': 'المدينة',
      'country': 'الدولة',
      'continue': 'متابعة',
      'back': 'رجوع',
      'prayerTimes': 'مواقيت الصلاة',
      'timesQuestion': 'هل تتوافق هذه الأوقات تقريبًا مع مسجدك؟',
      'yes': 'نعم',
      'adjust': 'تعديل',
      'graceQuestion': 'متى تريد تذكيرًا أقوى؟',
      'minutesAfter': 'دقيقة بعد دخول وقت الصلاة',
      'permissions': 'الأذونات',
      'permissionExplain': 'نطلب الأذونات فقط عندما تحتاجها ميزة معينة.',
      'finish': 'إنهاء',
      'confirmPrayer': 'لقد صليت',
      'snooze': 'ذكرني بعد 20 دقيقة',
      'snoozeIn': 'ذكّرني بعد {minutes} دقيقة',
      'skipToday': 'إنهاء تذكير اليوم',
      'skipConfirmTitle': 'إنهاء التذكير؟',
      'skipConfirmBody': 'هل تريد فعلًا إنهاء التذكيرات لهذه الصلاة؟',
      'noPrayLater': 'لا، سأصلي',
      'yesEnd': 'نعم، أنهِ التذكير',
      'reminderBody':
          'أردت أن تخصص وقتًا للصلاة. اترك الهاتف لبضع دقائق وصلِّ.',
      'accepted': 'الحمد لله 🤍',
      'week': 'هذا الأسبوع',
      'month': 'الشهر',
      'confirmedPrayers': 'الصلوات المؤكدة',
      'calculationMethod': 'طريقة الحساب',
      'madhhab': 'حساب العصر',
      'standard': 'قياسي',
      'hanafi': 'حنفي',
      'highLatitude': 'قاعدة خطوط العرض العليا',
      'gracePeriod': 'فترة السماح',
      'snoozeDuration': 'مدة التأجيل',
      'confirmationText': 'نص التأكيد',
      'softReminder': 'تذكير لطيف بعد الإنهاء',
      'theme': 'المظهر',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'language': 'اللغة',
      'languageChoose': 'اختر لغة تطبيق صلاتي.',
      'german': 'الألمانية',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'notificationPermission': 'السماح بالإشعارات',
      'exactAlarmPermission': 'السماح بالتذكيرات الدقيقة',
      'qiblaDirection': 'اتجاه القبلة',
      'calibrate': 'حرّك هاتفك على شكل رقم ثمانية إذا بدا البوصلة غير دقيقة.',
      'noCompass': 'لا يوجد مستشعر بوصلة. سيظهر اتجاه القبلة بالدرجات.',
      'needLocation': 'حدد موقعًا أولًا.',
      'offlineCache': 'يتم استخدام البيانات المحفوظة دون اتصال.',
      'retry': 'حاول مجددًا',
      'noData': 'لا توجد مواقيت صلاة موثوقة محفوظة لليوم.',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'manualAdjustments': 'تعديلات الدقائق',
      'maxSnoozes': 'أقصى عدد للتأجيل',
      'unlimited': 'بلا حد',
      'genericError': 'حدث خطأ ما. حاول مرة أخرى.',
      'locationError': 'تعذر تحديد موقعك. يمكنك اختيار مدينة بدلًا من ذلك.',
      'networkError': 'تعذر تحميل مواقيت الصلاة الآن. سيتم استخدام البيانات المحفوظة إن كانت متاحة.',
      'prayerDataError': 'تعذر معالجة مواقيت الصلاة بشكل موثوق. حاول مرة أخرى.',
      'snoozeUnavailable': 'لا يمكن تأجيل تذكير هذه الصلاة أكثر.',
      'prayerFirst': 'الصلاة أولًا، ثم الهاتف.',
      'heading': 'اتجاه الهاتف',
      'minutesValue': '{value} دقيقة',
    },
    'ur': {
      'appName': 'صلاتی',
      'tagline': 'کم توجہ بھٹکنا۔ زیادہ نماز۔',
      'getStarted': 'شروع کریں',
      'home': 'ہوم',
      'tracker': 'ریکارڈ',
      'qibla': 'قبلہ',
      'settings': 'ترتیبات',
      'nextPrayer': 'اگلی نماز',
      'today': 'آج',
      'prayed': 'نماز پڑھی',
      'snoozed': 'موخر',
      'skipped': 'چھوڑ دیا',
      'missed': 'تصدیق نہیں ہوئی',
      'upcoming': 'آنے والی',
      'active': 'فعال',
      'pending': 'یاد دہانی زیرِ عمل',
      'refresh': 'تازہ کریں',
      'location': 'مقام',
      'currentLocation': 'موجودہ مقام',
      'useLocation': 'میرا مقام استعمال کریں',
      'chooseCity': 'شہر منتخب کریں',
      'city': 'شہر',
      'country': 'ملک',
      'continue': 'جاری رکھیں',
      'back': 'واپس',
      'prayerTimes': 'نماز کے اوقات',
      'timesQuestion': 'کیا یہ اوقات تقریباً آپ کی مقامی مسجد سے ملتے ہیں؟',
      'yes': 'ہاں',
      'adjust': 'تبدیل کریں',
      'graceQuestion': 'ہم آپ کو زیادہ مضبوطی سے کب یاد دلائیں؟',
      'minutesAfter': 'نماز شروع ہونے کے بعد منٹ',
      'permissions': 'اجازتیں',
      'permissionExplain':
          'ہم صرف اس وقت اجازت مانگتے ہیں جب کسی خصوصیت کو اس کی ضرورت ہو۔',
      'finish': 'مکمل',
      'confirmPrayer': 'میں نے نماز پڑھی ہے',
      'snooze': '20 منٹ بعد یاد دلائیں',
      'snoozeIn': '{minutes} منٹ بعد یاد دلائیں',
      'skipToday': 'آج چھوڑ دیں',
      'skipConfirmTitle': 'یاد دہانی بند کریں؟',
      'skipConfirmBody':
          'کیا آپ واقعی اس نماز کی یاد دہانیاں بند کرنا چاہتے ہیں؟',
      'noPrayLater': 'نہیں، میں نماز پڑھوں گا',
      'yesEnd': 'ہاں، یاد دہانی بند کریں',
      'reminderBody': 'آپ نے نماز کے لیے وقت نکالنا چاہا تھا۔ فون چند منٹ کے لیے رکھ دیں اور نماز پڑھیں۔',
      'accepted': 'الحمدللہ 🤍',
      'week': 'اس ہفتے',
      'month': 'مہینہ',
      'confirmedPrayers': 'تصدیق شدہ نمازیں',
      'calculationMethod': 'حساب کا طریقہ',
      'madhhab': 'عصر کا حساب',
      'standard': 'معیاری',
      'hanafi': 'حنفی',
      'highLatitude': 'بلند عرض البلد کا اصول',
      'gracePeriod': 'مہلت کی مدت',
      'snoozeDuration': 'موخر کرنے کی مدت',
      'confirmationText': 'تصدیقی متن',
      'softReminder': 'چھوڑنے کے بعد نرم یاد دہانی',
      'theme': 'ظاہری شکل',
      'system': 'سسٹم',
      'light': 'روشن',
      'dark': 'تاریک',
      'language': 'زبان',
      'languageChoose': 'صلاتی کے لیے زبان منتخب کریں۔',
      'german': 'جرمن',
      'english': 'انگریزی',
      'arabic': 'عربی',
      'urdu': 'اردو',
      'pashto': 'پشتو',
      'notificationPermission': 'اطلاعات کی اجازت دیں',
      'exactAlarmPermission': 'درست یاددہانیوں کی اجازت دیں',
      'qiblaDirection': 'قبلہ کی سمت',
      'calibrate': 'اگر قطب نما غلط لگے تو فون کو آٹھ کی شکل میں حرکت دیں۔',
      'noCompass': 'قطب نما سینسر دستیاب نہیں۔ قبلہ کی سمت پھر بھی درجوں میں دکھائی جاتی ہے۔',
      'needLocation': 'پہلے ایک مقام مقرر کریں۔',
      'offlineCache': 'آف لائن محفوظ ڈیٹا استعمال ہو رہا ہے۔',
      'retry': 'دوبارہ کوشش کریں',
      'noData': 'آج کے لیے نماز کے قابلِ اعتماد اوقات محفوظ نہیں ہیں۔',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ',
      'manualAdjustments': 'منٹ کی تبدیلیاں',
      'maxSnoozes': 'زیادہ سے زیادہ موخر کرنا',
      'unlimited': 'لامحدود',
      'genericError': 'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔',
      'locationError':
          'آپ کا مقام معلوم نہیں ہو سکا۔ آپ اس کے بجائے شہر منتخب کر سکتے ہیں۔',
      'networkError': 'نماز کے اوقات ابھی لوڈ نہیں ہو سکے۔ دستیاب ہونے پر محفوظ ڈیٹا استعمال ہوگا۔',
      'prayerDataError': 'نماز کے اوقات قابل اعتماد طور پر پراسیس نہیں ہو سکے۔ براہ کرم دوبارہ کوشش کریں۔',
      'snoozeUnavailable': 'اس نماز کو مزید موخر نہیں کیا جا سکتا۔',
      'prayerFirst': 'پہلے نماز، پھر فون۔',
      'heading': 'سمت',
      'minutesValue': '{value} منٹ',
    },
    'ps': {
      'appName': 'صلاتي',
      'tagline': 'لږ ګډوډي. ډېره لمونځ.',
      'getStarted': 'پیل کړئ',
      'home': 'کور',
      'tracker': 'څارونکی',
      'qibla': 'قبله',
      'settings': 'امستنې',
      'nextPrayer': 'راتلونکی لمونځ',
      'today': 'نن',
      'prayed': 'لمونځ وشو',
      'snoozed': 'ځنډول شوی',
      'skipped': 'تېر شوی',
      'missed': 'تایید نه شو',
      'upcoming': 'راتلونکی',
      'active': 'فعال',
      'pending': 'یادونه پرانیستې ده',
      'refresh': 'تازه کړئ',
      'location': 'ځای',
      'currentLocation': 'اوسنی ځای',
      'useLocation': 'زما ځای وکاروئ',
      'chooseCity': 'ښار وټاکئ',
      'city': 'ښار',
      'country': 'هېواد',
      'continue': 'دوام ورکړئ',
      'back': 'بېرته',
      'prayerTimes': 'د لمانځه وختونه',
      'timesQuestion': 'ایا دا وختونه نږدې ستاسو له جومات سره سمون لري؟',
      'yes': 'هو',
      'adjust': 'سمول',
      'graceQuestion': 'کله مو په ډېر ټینګار یاد کړو؟',
      'minutesAfter': 'د لمانځه له پیله وروسته دقیقې',
      'permissions': 'اجازې',
      'permissionExplain':
          'موږ یوازې هغه وخت اجازه غواړو چې کومه ځانګړنه ورته اړتیا ولري.',
      'finish': 'پای',
      'confirmPrayer': 'ما لمونځ کړی دی',
      'snooze': 'په ۲۰ دقیقو کې مې یاد کړئ',
      'snoozeIn': 'په {minutes} دقیقو کې مې یاد کړئ',
      'skipToday': 'نن پرېږدئ',
      'skipConfirmTitle': 'یادونه پای ته ورسوئ؟',
      'skipConfirmBody': 'ایا رښتیا غواړئ د دې لمانځه یادونې پای ته ورسوئ؟',
      'noPrayLater': 'نه، لمونځ به وکړم',
      'yesEnd': 'هو، یادونه پای ته ورسوئ',
      'reminderBody': 'تاسو غوښتل لمانځه ته وخت ځانګړی کړئ. فون د څو دقیقو لپاره کېږدئ او لمونځ وکړئ.',
      'accepted': 'الحمدلله 🤍',
      'week': 'دا اونۍ',
      'month': 'میاشت',
      'confirmedPrayers': 'تایید شوي لمونځونه',
      'calculationMethod': 'د محاسبې طریقه',
      'madhhab': 'د مازدیګر محاسبه',
      'standard': 'معیاري',
      'hanafi': 'حنفي',
      'highLatitude': 'د لوړې عرض البلد قاعده',
      'gracePeriod': 'د ځنډ موده',
      'snoozeDuration': 'د ځنډولو موده',
      'confirmationText': 'د تایید متن',
      'softReminder': 'له پرېښودو وروسته نرمه یادونه',
      'theme': 'بڼه',
      'system': 'سیستم',
      'light': 'روښانه',
      'dark': 'تیاره',
      'language': 'ژبه',
      'languageChoose': 'د صلاتي لپاره ژبه وټاکئ.',
      'german': 'جرمني',
      'english': 'انګلیسي',
      'arabic': 'عربي',
      'urdu': 'اردو',
      'pashto': 'پښتو',
      'notificationPermission': 'خبرتیاوو ته اجازه ورکړئ',
      'exactAlarmPermission': 'دقیقو یادونو ته اجازه ورکړئ',
      'qiblaDirection': 'د قبلې لوری',
      'calibrate': 'که قطب نما ناسمه ښکاري، فون د اته په بڼه وخوځوئ.',
      'noCompass': 'د قطب نما حسګر نشته. د قبلې لوری بیا هم په درجو ښودل کېږي.',
      'needLocation': 'لومړی یو ځای وټاکئ.',
      'offlineCache': 'افلاین زیرمه کارول کېږي.',
      'retry': 'بیا هڅه وکړئ',
      'noData': 'د نن لپاره د لمانځه باوري وختونه نشته.',
      'save': 'ساتل',
      'cancel': 'لغوه',
      'manualAdjustments': 'د دقیقو سمون',
      'maxSnoozes': 'اعظمي ځنډول',
      'unlimited': 'نامحدود',
      'genericError': 'یوه ستونزه پېښه شوه. بیا هڅه وکړئ.',
      'locationError': 'ستاسو ځای ونه موندل شو. پر ځای یې ښار ټاکلی شئ.',
      'networkError': 'د لمانځه وختونه اوس نه شي پورته کېدای. که موجود وي زیرمه شوې معلومات کارېږي.',
      'prayerDataError':
          'د لمانځه وختونه په باوري توګه پروسس نه شول. بیا هڅه وکړئ.',
      'snoozeUnavailable': 'دا لمونځ نور نه شي ځنډېدای.',
      'prayerFirst': 'لومړی لمونځ، بیا فون.',
      'heading': 'لوری',
      'minutesValue': '{value} دقیقې',
    },
  };

  String t(
    String key, {
    Map<String, String> params = const <String, String>{},
  }) {
    String value =
        _values[locale.languageCode]?[key] ?? _values['en']?[key] ?? key;
    for (final MapEntry<String, String> entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  /// Formats every user-visible number using the active app language.
  ///
  /// `intl` localizes punctuation, while Arabic, Urdu and Pashto also use
  /// their familiar digit shapes so no Latin digits leak into the interface.
  String number(num value) {
    final String formatted = NumberFormat.decimalPattern(locale.languageCode)
        .format(value);
    const Map<String, String> western = <String, String>{
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    const Map<String, String> eastern = <String, String>{
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };
    final Map<String, String>? digits = switch (locale.languageCode) {
      'ar' => western,
      'ur' || 'ps' => eastern,
      _ => null,
    };
    if (digits == null) return formatted;
    return formatted.splitMapJoin(
      RegExp('[0-9]'),
      onMatch: (Match match) => digits[match.group(0)]!,
    );
  }

  String minutes(num value) =>
      t('minutesValue', params: <String, String>{'value': number(value)});

  String date(DateTime value, {required String pattern}) {
    final String formatted = DateFormat(
      pattern,
      locale.languageCode,
    ).format(value);
    return _localizeDigits(_localizeGregorianDateWords(formatted));
  }

  String time(DateTime value) =>
      _localizeDigits(DateFormat.Hm(locale.languageCode).format(value));

  String hijriDate(String value) {
    if (!const <String>{'ar', 'ur', 'ps'}.contains(locale.languageCode)) {
      return _localizeDigits(value);
    }

    const Map<String, String> arabicMonths = <String, String>{
      'Muharram': 'محرم',
      'Safar': 'صفر',
      'Rabi al-Awwal': 'ربيع الأول',
      'Rabi al-awwal': 'ربيع الأول',
      "Rabi' al-awwal": 'ربيع الأول',
      'Rabīʿ al-awwal': 'ربيع الأول',
      'Rabi al-Thani': 'ربيع الثاني',
      'Rabi al-thani': 'ربيع الثاني',
      "Rabi' al-thani": 'ربيع الثاني',
      'Rabīʿ al-thānī': 'ربيع الثاني',
      'Jumada al-Awwal': 'جمادى الأولى',
      'Jumada al-awwal': 'جمادى الأولى',
      'Jumada al-ula': 'جمادى الأولى',
      'Jumada al-Thani': 'جمادى الآخرة',
      'Jumada al-thani': 'جمادى الآخرة',
      'Jumada al-akhirah': 'جمادى الآخرة',
      'Rajab': 'رجب',
      'Shaban': 'شعبان',
      'Ramadan': 'رمضان',
      'Shawwal': 'شوال',
      'Dhul Qadah': 'ذو القعدة',
      'Dhu al-Qidah': 'ذو القعدة',
      'Dhul Hijjah': 'ذو الحجة',
      'Dhu al-Hijjah': 'ذو الحجة',
    };

    String localized = value;
    for (final MapEntry<String, String> entry in arabicMonths.entries) {
      localized = localized.replaceAll(entry.key, entry.value);
    }
    return _localizeDigits(localized);
  }

  String _localizeDigits(String value) {
    if (locale.languageCode == 'de' || locale.languageCode == 'en') {
      return value;
    }
    return value.replaceAllMapped(RegExp('[0-9]'), (Match match) {
      final String digit = match.group(0)!;
      return number(int.parse(digit));
    });
  }

  /// Keeps Gregorian day and month names in the selected app language even
  /// when a platform's date-symbol fallback returns English names.
  String _localizeGregorianDateWords(String value) {
    if (locale.languageCode != 'ar') return value;

    const Map<String, String> arabicWords = <String, String>{
      'Monday': 'الاثنين',
      'Tuesday': 'الثلاثاء',
      'Wednesday': 'الأربعاء',
      'Thursday': 'الخميس',
      'Friday': 'الجمعة',
      'Saturday': 'السبت',
      'Sunday': 'الأحد',
      'January': 'كانون الثاني',
      'February': 'شباط',
      'March': 'آذار',
      'April': 'نيسان',
      'May': 'أيار',
      'June': 'حزيران',
      'July': 'تموز',
      'August': 'آب',
      'September': 'أيلول',
      'October': 'تشرين الأول',
      'November': 'تشرين الثاني',
      'December': 'كانون الأول',
      // Arabic CLDR data normally uses these international Arabic names.
      // Replace them with the requested Levantine Gregorian month names.
      'يناير': 'كانون الثاني',
      'فبراير': 'شباط',
      'مارس': 'آذار',
      'أبريل': 'نيسان',
      'مايو': 'أيار',
      'يونيو': 'حزيران',
      'يوليو': 'تموز',
      'أغسطس': 'آب',
      'سبتمبر': 'أيلول',
      'أكتوبر': 'تشرين الأول',
      'نوفمبر': 'تشرين الثاني',
      'ديسمبر': 'كانون الأول',
    };

    String localized = value;
    for (final MapEntry<String, String> entry in arabicWords.entries) {
      localized = localized.replaceAll(entry.key, entry.value);
    }
    return localized;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (Locale item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
