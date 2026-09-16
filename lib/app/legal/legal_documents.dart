import 'package:salah_focus/app/legal/legal_document.dart';

abstract final class PrivacyLegalDocuments {
  static const List<String> supportedLanguages = <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'id',
    'ms',
    'pa',
    'ps',
    'tr',
    'ur',
  ];

  static LegalDocument privacyPolicy(String languageCode) =>
      (_privacyPolicies[languageCode] ?? _privacyPolicies['en']!).resolved();

  static LegalDocument legalNotice(String languageCode) =>
      (_legalNotices[languageCode] ?? _legalNotices['en']!).resolved();

  static const Map<String, LegalDocument> _privacyPolicies = {
    'en': LegalDocument(
      title: 'Privacy Policy',
      lastUpdated: '16 September 2026',
      introduction: 'This policy describes the data processing performed by the current SalahFocus app. It does not describe future account, cloud-sync, analytics, or advertising features that are not present in this release.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Controller and scope',
          paragraphs: <String>[
            'The person responsible for SalahFocus is {controller}, {location}. Contact: {email}. LinkedIn: {linkedin}. SalahFocus has no user accounts and no developer-operated account or synchronization server.',
          ],
        ),
        LegalSection(
          title: '2. Location and geocoding',
          paragraphs: <String>[
            'If you choose automatic location, SalahFocus requests foreground/while-in-use precise location. It stores latitude, longitude, city, country, time zone, and whether the location was automatic. While the app is running, automatic mode listens for location changes with an approximately 1 km distance filter so prayer data can be refreshed.',
            'The current builds do not request Android background location or iOS Always authorization and do not declare an iOS background-location mode. You may instead enter a city and country. Forward or reverse geocoding is performed by the device platform and may send the entered place or coordinates, language, IP address, and ordinary request metadata to the platform geocoding provider.',
          ],
        ),
        LegalSection(
          title: '3. Prayer times and Qibla',
          paragraphs: <String>[
            'To download a monthly prayer calendar, SalahFocus sends the selected latitude and longitude, month and year, calculation method, Asr school, and high-latitude rule over HTTPS to the AlAdhan API at api.aladhan.com. The service and network operators can also receive ordinary connection data such as the IP address. City names and prayer history are not included in this request.',
            'Qibla bearing is calculated on the device from the stored coordinates. Compass heading is read from the device sensor for display and is not stored or sent by SalahFocus.',
          ],
        ),
        LegalSection(
          title: '4. Data stored on the device',
          paragraphs: <String>[
            'SharedPreferences stores selected location, prayer and Ramadan settings, language, theme, onboarding status, first successful launch time, and whether an in-app review request was attempted. SQLite stores cached prayer times, time zone and Hijri metadata, prayer status, confirmation/edit/snooze timestamps, manual offsets, Ramadan fasting, Tarawih and Qiyam records, custom Ramadan goal titles, and goal completions.',
            'Prayer and Ramadan records can reveal religious practice and should be treated as sensitive. The current code keeps these records in the app database and does not upload them to SalahFocus or the prayer-time API. The app does not access contacts, photos, microphone, health data, advertising identifiers, or other device identifiers.',
          ],
        ),
        LegalSection(
          title: '5. Notifications and device features',
          paragraphs: <String>[
            'With permission, SalahFocus schedules local prayer, Friday, snooze, and Ramadan notifications on the device. Notification text, dates, prayer identifiers, and actions are handled by the operating system; no remote-push token or notification server is used. Android may use exact alarms, vibration, restart scheduling after boot, and optional full-screen prayer alerts. iOS may use Time Sensitive notifications.',
            'The current iOS target does not contain FamilyControls, ManagedSettings, DeviceActivity, an App Group, or a Family Controls entitlement. SalahFocus therefore does not access Screen Time app selections or usage data in this release.',
          ],
        ),
        LegalSection(
          title: '6. Third-party services and network transfers',
          paragraphs: <String>[
            'External processing is limited to the AlAdhan prayer-time API, operating-system geocoding services, and an optional operating-system App Store or Google Play review prompt. Those providers may process technical connection logs under their own terms. SalahFocus contains no analytics, crash-reporting, advertising, tracking, or social-login SDK.',
            'No prayer history, Ramadan history, custom goals, notification actions, or account data is transmitted to the developer. All app requests identified in the source use HTTPS, but SalahFocus does not control how external providers retain their server logs.',
          ],
        ),
        LegalSection(
          title: '7. Retention and deletion',
          paragraphs: <String>[
            'Local settings remain until changed, app storage is cleared, or the app is uninstalled. Prayer and Ramadan history is retained in the local database without an automatic deletion period. Cached prayer data may be replaced by later downloads; scheduled notifications expire or are cancelled when schedules change.',
            'You can revoke location and notification permissions in system settings. Clearing SalahFocus storage or uninstalling the app deletes the app-managed local database and preferences. Requests concerning data held by an external provider must be addressed under that provider’s process.',
          ],
        ),
        LegalSection(
          title: '8. Legal bases and your rights',
          paragraphs: <String>[
            'Processing needed to provide the functions you request is based, as applicable, on Article 6(1)(b) GDPR; permission-based processing is based on consent under Article 6(1)(a) GDPR. You can withdraw device permission consent at any time without affecting earlier lawful processing.',
            'Subject to the legal conditions, you may request access, rectification, erasure, restriction, portability, or object to processing, and you may complain to a data-protection supervisory authority. Because most data stays only in your local app storage, the controller normally cannot inspect or recover it remotely.',
          ],
        ),
        LegalSection(
          title: '9. Contact and policy changes',
          paragraphs: <String>[
            'For privacy questions or rights requests, contact {email}. This policy must be updated before any release adds accounts, cloud backup, analytics, advertising, new data recipients, or materially different permissions. The effective date above identifies the displayed version.',
          ],
        ),
      ],
    ),
    'de': LegalDocument(
      title: 'Datenschutzerklärung',
      lastUpdated: '16. September 2026',
      introduction: 'Diese Erklärung beschreibt die Datenverarbeitung der aktuellen SalahFocus-App. Sie beschreibt keine künftigen Konto-, Cloud-Sync-, Analyse- oder Werbefunktionen, die in dieser Version nicht vorhanden sind.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Verantwortlicher und Geltungsbereich',
          paragraphs: <String>[
            'Verantwortlich für SalahFocus ist {controller}, {location}. Kontakt: {email}. LinkedIn: {linkedin}. SalahFocus hat keine Benutzerkonten und keinen vom Entwickler betriebenen Konto- oder Synchronisationsserver.',
          ],
        ),
        LegalSection(
          title: '2. Standort und Geokodierung',
          paragraphs: <String>[
            'Wenn du den automatischen Standort auswählst, fragt SalahFocus den genauen Standort im Vordergrund beziehungsweise während der Nutzung ab. Gespeichert werden Breiten- und Längengrad, Stadt, Land, Zeitzone sowie die Information, ob der Standort automatisch ermittelt wurde. Solange die App läuft, reagiert der automatische Modus ungefähr ab einer Ortsänderung von 1 km.',
            'Die aktuellen Builds fordern weder Android-Hintergrundstandort noch die iOS-Berechtigung „Immer“ an und deklarieren keinen iOS-Hintergrundmodus für Standort. Alternativ kannst du Stadt und Land eingeben. Die Geokodierung erfolgt über den Plattformdienst und kann Ortsangaben oder Koordinaten, Sprache, IP-Adresse und übliche Verbindungsdaten an dessen Anbieter übermitteln.',
          ],
        ),
        LegalSection(
          title: '3. Gebetszeiten und Qibla',
          paragraphs: <String>[
            'Für den monatlichen Gebetskalender sendet SalahFocus den gewählten Breiten- und Längengrad, Monat und Jahr, Berechnungsmethode, Asr-Rechtsschule und Höhenbreitenregel verschlüsselt per HTTPS an die AlAdhan-API unter api.aladhan.com. Der Dienst und Netzbetreiber können zusätzlich übliche Verbindungsdaten wie die IP-Adresse erhalten. Stadtname und Gebetsverlauf werden nicht mitgesendet.',
            'Die Qibla-Richtung wird auf dem Gerät aus den gespeicherten Koordinaten berechnet. Die Kompassausrichtung wird nur zur Anzeige vom Sensor gelesen und von SalahFocus weder gespeichert noch übertragen.',
          ],
        ),
        LegalSection(
          title: '4. Auf dem Gerät gespeicherte Daten',
          paragraphs: <String>[
            'SharedPreferences speichert Standort, Gebets- und Ramadan-Einstellungen, Sprache, Design, Onboarding-Status, Zeitpunkt des ersten erfolgreichen Starts und ob eine In-App-Bewertung angefragt wurde. SQLite speichert Gebetszeit-Cache, Zeitzonen- und Hijri-Daten, Gebetsstatus, Bestätigungs-, Bearbeitungs- und Snooze-Zeitpunkte, manuelle Korrekturen sowie Fasten-, Tarawih-, Qiyam- und Ramadan-Zieldaten.',
            'Gebets- und Ramadan-Einträge können religiöse Praxis erkennen lassen und sind besonders sensibel. Der aktuelle Code belässt sie in der App-Datenbank und lädt sie weder zu SalahFocus noch zur Gebetszeiten-API hoch. Kontakte, Fotos, Mikrofon, Gesundheitsdaten, Werbe- oder andere Gerätekennungen werden nicht abgerufen.',
          ],
        ),
        LegalSection(
          title: '5. Benachrichtigungen und Gerätefunktionen',
          paragraphs: <String>[
            'Mit deiner Erlaubnis plant SalahFocus lokale Gebets-, Freitags-, Snooze- und Ramadan-Benachrichtigungen. Inhalt, Termine, Gebetskennungen und Aktionen verarbeitet das Betriebssystem; es gibt keinen Remote-Push-Token und keinen Benachrichtigungsserver. Android kann exakte Alarme, Vibration, Neuplanung nach Neustart und optionale Vollbildhinweise verwenden. iOS kann zeitkritische Mitteilungen verwenden.',
            'Das aktuelle iOS-Ziel enthält keine FamilyControls-, ManagedSettings- oder DeviceActivity-Integration, keine App Group und keine Family-Controls-Berechtigung. Diese Version greift daher nicht auf Bildschirmzeit-Auswahlen oder Nutzungsdaten zu.',
          ],
        ),
        LegalSection(
          title: '6. Drittanbieter und Übermittlungen',
          paragraphs: <String>[
            'Externe Verarbeitung beschränkt sich auf die AlAdhan-Gebetszeiten-API, Geokodierungsdienste des Betriebssystems und eine optionale Bewertungsabfrage über App Store oder Google Play. Diese Anbieter können technische Verbindungsprotokolle nach ihren eigenen Bedingungen verarbeiten. SalahFocus enthält keine Analyse-, Absturzbericht-, Werbe-, Tracking- oder Social-Login-SDKs.',
            'Gebets- oder Ramadan-Verlauf, eigene Ziele und Benachrichtigungsaktionen werden nicht an den Entwickler übertragen. Alle im Quellcode festgelegten App-Anfragen verwenden HTTPS; die Speicherfristen externer Serverprotokolle werden jedoch nicht von SalahFocus kontrolliert.',
          ],
        ),
        LegalSection(
          title: '7. Speicherdauer und Löschung',
          paragraphs: <String>[
            'Lokale Einstellungen bleiben bis zur Änderung, Löschung der App-Daten oder Deinstallation erhalten. Für den lokalen Gebets- und Ramadan-Verlauf gibt es derzeit keine automatische Löschfrist. Gebetszeit-Caches können überschrieben werden; geplante Mitteilungen laufen ab oder werden bei Planänderungen gelöscht.',
            'Standort- und Mitteilungsberechtigungen kannst du in den Systemeinstellungen widerrufen. Das Löschen des SalahFocus-App-Speichers oder die Deinstallation entfernt die von der App verwaltete Datenbank und Einstellungen. Für Daten eines externen Anbieters gilt dessen Löschverfahren.',
          ],
        ),
        LegalSection(
          title: '8. Rechtsgrundlagen und Rechte',
          paragraphs: <String>[
            'Soweit anwendbar, beruht die für angeforderte Funktionen notwendige Verarbeitung auf Art. 6 Abs. 1 lit. b DSGVO; einwilligungsabhängige Verarbeitung beruht auf Art. 6 Abs. 1 lit. a DSGVO. Eine Einwilligung zu Geräteberechtigungen kann jederzeit mit Wirkung für die Zukunft widerrufen werden.',
            'Unter den gesetzlichen Voraussetzungen bestehen Rechte auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch sowie ein Beschwerderecht bei einer Datenschutzaufsichtsbehörde. Da die meisten Daten nur im lokalen App-Speicher liegen, kann der Verantwortliche sie normalerweise nicht aus der Ferne einsehen oder wiederherstellen.',
          ],
        ),
        LegalSection(
          title: '9. Kontakt und Änderungen',
          paragraphs: <String>[
            'Datenschutzfragen und Betroffenenanfragen bitte an {email}. Vor einer Version mit Konten, Cloud-Backup, Analyse, Werbung, neuen Empfängern oder wesentlich anderen Berechtigungen muss diese Erklärung aktualisiert werden. Das oben genannte Datum kennzeichnet die angezeigte Fassung.',
          ],
        ),
      ],
    ),
    'ar': LegalDocument(
      title: 'سياسة الخصوصية',
      lastUpdated: '16 سبتمبر 2026',
      introduction: 'تصف هذه السياسة معالجة البيانات في الإصدار الحالي من تطبيق SalahFocus، ولا تشمل ميزات مستقبلية مثل الحسابات أو المزامنة السحابية أو التحليلات أو الإعلانات لأنها غير موجودة حاليًا.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. المسؤول ونطاق السياسة',
          paragraphs: <String>[
            'المسؤول عن SalahFocus هو {controller}، {location}. التواصل: {email}. لينكدإن: {linkedin}. لا توجد حسابات مستخدمين ولا خادم حسابات أو مزامنة يديره المطور.',
          ],
        ),
        LegalSection(
          title: '2. الموقع والترميز الجغرافي',
          paragraphs: <String>[
            'عند اختيار الموقع التلقائي يطلب التطبيق الموقع الدقيق أثناء الاستخدام، ويحفظ خط العرض والطول والمدينة والدولة والمنطقة الزمنية وطريقة اختيار الموقع. وأثناء تشغيل التطبيق يتابع تغيّرات الموقع بمرشح مسافة يقارب كيلومترًا واحدًا لتحديث بيانات الصلاة.',
            'لا يطلب الإصدار الحالي موقع الخلفية في Android ولا إذن «دائمًا» أو وضع موقع في الخلفية في iOS. ويمكن إدخال مدينة ودولة يدويًا. قد ترسل خدمة الترميز الجغرافي التابعة للنظام المكان أو الإحداثيات واللغة وعنوان IP وبيانات الطلب العادية إلى مزود المنصة.',
          ],
        ),
        LegalSection(
          title: '3. مواقيت الصلاة والقبلة',
          paragraphs: <String>[
            'لتنزيل تقويم شهري يرسل التطبيق عبر HTTPS الإحداثيات والشهر والسنة وطريقة الحساب ومذهب العصر وقاعدة خطوط العرض العليا إلى واجهة AlAdhan على api.aladhan.com. وقد يستلم مزود الخدمة والشبكة عنوان IP وبيانات الاتصال المعتادة. لا يُرسل اسم المدينة ولا سجل الصلاة.',
            'يُحسب اتجاه القبلة على الجهاز من الإحداثيات المحفوظة. تُقرأ جهة البوصلة من حساس الجهاز للعرض فقط ولا يحفظها SalahFocus أو يرسلها.',
          ],
        ),
        LegalSection(
          title: '4. البيانات المحفوظة على الجهاز',
          paragraphs: <String>[
            'تحفظ SharedPreferences الموقع والإعدادات واللغة والمظهر وحالة الإعداد الأول ووقت أول تشغيل ناجح وحالة طلب التقييم. وتحفظ SQLite أوقات الصلاة المخبأة وحالتها وأوقات التأكيد والتعديل والتأجيل وبيانات الهجري، إضافة إلى الصيام والتراويح والقيام وأسماء أهداف رمضان وإنجازها.',
            'قد تكشف سجلات الصلاة ورمضان عن ممارسة دينية ولذلك تُعد حساسة. تبقى في قاعدة بيانات التطبيق ولا تُرفع إلى المطور أو واجهة المواقيت. لا يصل التطبيق إلى جهات الاتصال أو الصور أو الميكروفون أو البيانات الصحية أو معرّفات الإعلانات أو الجهاز.',
          ],
        ),
        LegalSection(
          title: '5. الإشعارات وميزات الجهاز',
          paragraphs: <String>[
            'بعد الإذن يجدول التطبيق إشعارات محلية للصلاة والجمعة والتأجيل ورمضان. يعالج نظام التشغيل النص والمواعيد ومعرّفات الصلاة والإجراءات، ولا يستخدم التطبيق رمز دفع بعيدًا أو خادم إشعارات. قد يستخدم Android المنبهات الدقيقة والاهتزاز وإعادة الجدولة بعد التشغيل والتنبيه الاختياري بملء الشاشة، وقد يستخدم iOS إشعارات حساسة للوقت.',
            'هدف iOS الحالي لا يتضمن FamilyControls أو ManagedSettings أو DeviceActivity أو App Group أو صلاحية Family Controls، لذلك لا يصل هذا الإصدار إلى اختيارات «مدة استخدام الجهاز» أو بيانات الاستخدام.',
          ],
        ),
        LegalSection(
          title: '6. الخدمات الخارجية ونقل البيانات',
          paragraphs: <String>[
            'تقتصر المعالجة الخارجية على AlAdhan وخدمات الترميز الجغرافي في النظام ونافذة تقييم اختيارية من App Store أو Google Play. قد يعالج هؤلاء المزودون سجلات تقنية وفق شروطهم. لا يحتوي SalahFocus على تحليلات أو تقارير أعطال أو إعلانات أو تتبع أو تسجيل اجتماعي.',
            'لا تُنقل سجلات الصلاة ورمضان أو الأهداف أو إجراءات الإشعارات إلى المطور. تستخدم طلبات التطبيق المحددة في المصدر HTTPS، لكن SalahFocus لا يتحكم في مدة احتفاظ المزودين بسجلات خوادمهم.',
          ],
        ),
        LegalSection(
          title: '7. الاحتفاظ والحذف',
          paragraphs: <String>[
            'تبقى الإعدادات المحلية حتى تغييرها أو مسح بيانات التطبيق أو إلغاء تثبيته. لا توجد مدة حذف تلقائي لسجل الصلاة ورمضان المحلي. قد تُستبدل بيانات المواقيت المخبأة، وتنتهي الإشعارات أو تُلغى عند تغيير الجدول.',
            'يمكن سحب أذونات الموقع والإشعارات من إعدادات النظام. يؤدي مسح تخزين SalahFocus أو إلغاء تثبيته إلى حذف قاعدة البيانات والتفضيلات التي يديرها التطبيق. تخضع بيانات المزود الخارجي لإجراءات ذلك المزود.',
          ],
        ),
        LegalSection(
          title: '8. الأساس القانوني وحقوقك',
          paragraphs: <String>[
            'تعتمد المعالجة اللازمة للوظائف المطلوبة، حسب الحالة، على المادة 6(1)(b) من GDPR، وتعتمد المعالجة القائمة على الإذن على الموافقة وفق المادة 6(1)(a). يمكنك سحب إذن الجهاز في أي وقت للمستقبل.',
            'وفق الشروط القانونية يمكنك طلب الوصول أو التصحيح أو المحو أو التقييد أو النقل أو الاعتراض، وتقديم شكوى إلى سلطة حماية البيانات. وبما أن معظم البيانات تبقى في تخزين التطبيق المحلي، فعادة لا يستطيع المسؤول رؤيتها أو استعادتها عن بعد.',
          ],
        ),
        LegalSection(
          title: '9. التواصل وتغييرات السياسة',
          paragraphs: <String>[
            'لأسئلة الخصوصية أو ممارسة الحقوق تواصل عبر {email}. يجب تحديث هذه السياسة قبل إضافة حسابات أو نسخ سحابي أو تحليلات أو إعلانات أو مستلمين جدد أو أذونات مختلفة جوهريًا. يحدد التاريخ أعلاه النسخة المعروضة.',
          ],
        ),
      ],
    ),
    'fr': LegalDocument(
      title: 'Politique de confidentialité',
      lastUpdated: '16 septembre 2026',
      introduction: 'Cette politique décrit les traitements de la version actuelle de SalahFocus. Elle ne couvre pas de futurs comptes, synchronisation cloud, analyses ou publicités, absents de cette version.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Responsable et portée',
          paragraphs: <String>[
            'Le responsable de SalahFocus est {controller}, {location}. Contact : {email}. LinkedIn : {linkedin}. SalahFocus ne propose aucun compte utilisateur ni serveur de compte ou de synchronisation exploité par le développeur.',
          ],
        ),
        LegalSection(
          title: '2. Localisation et géocodage',
          paragraphs: <String>[
            'Si vous choisissez la localisation automatique, l’app demande la position précise au premier plan/pendant l’utilisation et conserve latitude, longitude, ville, pays, fuseau horaire et mode de sélection. Pendant que l’app fonctionne, ce mode écoute les changements avec un filtre d’environ 1 km.',
            'Les versions actuelles ne demandent ni localisation Android en arrière-plan, ni autorisation iOS « Toujours », et ne déclarent aucun mode iOS de localisation en arrière-plan. Vous pouvez saisir ville et pays. Le géocodage du système peut transmettre lieu ou coordonnées, langue, adresse IP et métadonnées usuelles au fournisseur de la plateforme.',
          ],
        ),
        LegalSection(
          title: '3. Horaires de prière et Qibla',
          paragraphs: <String>[
            'Pour le calendrier mensuel, SalahFocus envoie par HTTPS latitude, longitude, mois, année, méthode de calcul, école de l’Asr et règle de haute latitude à l’API AlAdhan sur api.aladhan.com. Le service et les opérateurs réseau peuvent recevoir l’adresse IP et les données de connexion usuelles. La ville et l’historique des prières ne sont pas envoyés.',
            'La Qibla est calculée sur l’appareil. Le cap du compas sert uniquement à l’affichage et SalahFocus ne le conserve ni ne le transmet.',
          ],
        ),
        LegalSection(
          title: '4. Données conservées sur l’appareil',
          paragraphs: <String>[
            'SharedPreferences conserve localisation, réglages de prière et Ramadan, langue, thème, état de l’accueil initial, premier lancement et état de demande d’avis. SQLite conserve cache des horaires, fuseau et données hégiriennes, statuts, dates de confirmation/modification/report, ajustements, jeûne, Tarawih, Qiyam, objectifs Ramadan et accomplissements.',
            'Ces données peuvent révéler une pratique religieuse et sont sensibles. Le code actuel les garde dans la base locale et ne les envoie ni au développeur ni à l’API. L’app n’accède pas aux contacts, photos, microphone, données de santé, identifiants publicitaires ou autres identifiants de l’appareil.',
          ],
        ),
        LegalSection(
          title: '5. Notifications et fonctions de l’appareil',
          paragraphs: <String>[
            'Avec votre autorisation, l’app programme localement les rappels de prière, du vendredi, de report et de Ramadan. Le système traite textes, dates, identifiants et actions ; aucun jeton push distant ni serveur de notifications n’est utilisé. Android peut utiliser alarmes exactes, vibration, reprogrammation au démarrage et plein écran facultatif ; iOS peut utiliser les notifications urgentes.',
            'La cible iOS actuelle n’intègre pas FamilyControls, ManagedSettings, DeviceActivity, App Group ni l’autorisation Family Controls. Cette version n’accède donc pas aux choix ou données Temps d’écran.',
          ],
        ),
        LegalSection(
          title: '6. Services tiers et transferts',
          paragraphs: <String>[
            'Les traitements externes se limitent à AlAdhan, au géocodage du système et à une éventuelle invite d’avis App Store/Google Play. Ces fournisseurs peuvent traiter des journaux techniques selon leurs règles. Aucun SDK d’analyse, de crash, de publicité, de suivi ou de connexion sociale n’est intégré.',
            'Historique de prière/Ramadan, objectifs et actions de notification ne sont pas transmis au développeur. Les requêtes définies dans le code utilisent HTTPS, mais SalahFocus ne contrôle pas la conservation des journaux des fournisseurs.',
          ],
        ),
        LegalSection(
          title: '7. Conservation et suppression',
          paragraphs: <String>[
            'Les réglages restent jusqu’à modification, effacement des données ou désinstallation. Aucun délai automatique ne supprime actuellement l’historique local. Le cache peut être remplacé et les notifications expirent ou sont annulées lors d’un changement.',
            'Vous pouvez retirer les autorisations dans les réglages système. Effacer le stockage de SalahFocus ou désinstaller l’app supprime sa base et ses préférences. Les données d’un fournisseur externe suivent sa propre procédure.',
          ],
        ),
        LegalSection(
          title: '8. Bases juridiques et droits',
          paragraphs: <String>[
            'Selon le cas, les fonctions demandées reposent sur l’article 6(1)(b) du RGPD et les traitements soumis à permission sur le consentement de l’article 6(1)(a). Vous pouvez retirer une autorisation pour l’avenir.',
            'Sous réserve des conditions légales, vous disposez de droits d’accès, rectification, effacement, limitation, portabilité et opposition, ainsi que du droit de saisir une autorité de contrôle. Les données restant surtout en stockage local, le responsable ne peut normalement pas les consulter ou restaurer à distance.',
          ],
        ),
        LegalSection(
          title: '9. Contact et modifications',
          paragraphs: <String>[
            'Pour toute question ou demande, écrivez à {email}. Cette politique devra être actualisée avant d’ajouter comptes, cloud, analyses, publicité, nouveaux destinataires ou permissions sensiblement différentes. La date ci-dessus identifie la version affichée.',
          ],
        ),
      ],
    ),
    'es': LegalDocument(
      title: 'Política de privacidad',
      lastUpdated: '16 de septiembre de 2026',
      introduction: 'Esta política describe el tratamiento de datos de la versión actual de SalahFocus. No describe futuras cuentas, sincronización en la nube, analítica o publicidad que no existen en esta versión.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Responsable y alcance',
          paragraphs: <String>[
            'El responsable de SalahFocus es {controller}, {location}. Contacto: {email}. LinkedIn: {linkedin}. SalahFocus no tiene cuentas de usuario ni un servidor de cuentas o sincronización operado por el desarrollador.',
          ],
        ),
        LegalSection(
          title: '2. Ubicación y geocodificación',
          paragraphs: <String>[
            'Si eliges ubicación automática, la app solicita ubicación precisa en primer plano/durante el uso y guarda latitud, longitud, ciudad, país, zona horaria y el modo de selección. Mientras se ejecuta, escucha cambios con un filtro aproximado de 1 km.',
            'La versión actual no solicita ubicación en segundo plano de Android ni autorización «Siempre» o modo de ubicación en segundo plano de iOS. Puedes introducir ciudad y país. El geocodificador del sistema puede enviar lugar o coordenadas, idioma, IP y metadatos habituales al proveedor de la plataforma.',
          ],
        ),
        LegalSection(
          title: '3. Horarios de oración y Qibla',
          paragraphs: <String>[
            'Para el calendario mensual se envían por HTTPS latitud, longitud, mes, año, método, escuela del Asr y regla de latitudes altas a la API AlAdhan en api.aladhan.com. El servicio y la red pueden recibir la IP y datos de conexión. No se envían ciudad ni historial de oración.',
            'La Qibla se calcula en el dispositivo. El rumbo de la brújula solo se usa para mostrarlo y SalahFocus no lo guarda ni transmite.',
          ],
        ),
        LegalSection(
          title: '4. Datos guardados en el dispositivo',
          paragraphs: <String>[
            'SharedPreferences guarda ubicación, ajustes, idioma, tema, incorporación, primer inicio y estado de solicitud de reseña. SQLite guarda horarios, zona horaria y datos hiyri, estados y marcas de confirmación/edición/posposición, ajustes, ayuno, Tarawih, Qiyam, títulos de objetivos y logros.',
            'Los registros pueden revelar práctica religiosa y son sensibles. El código actual los conserva localmente y no los sube al desarrollador ni a la API. La app no accede a contactos, fotos, micrófono, salud, identificadores publicitarios ni otros identificadores del dispositivo.',
          ],
        ),
        LegalSection(
          title: '5. Notificaciones y funciones del dispositivo',
          paragraphs: <String>[
            'Con permiso, la app programa notificaciones locales de oración, viernes, posposición y Ramadán. El sistema gestiona texto, fechas, identificadores y acciones; no hay token push remoto ni servidor. Android puede usar alarmas exactas, vibración, reinicio y pantalla completa opcional; iOS, notificaciones urgentes.',
            'El objetivo iOS actual no contiene FamilyControls, ManagedSettings, DeviceActivity, App Group ni la autorización Family Controls, por lo que no accede a selecciones o datos de Tiempo de uso.',
          ],
        ),
        LegalSection(
          title: '6. Terceros y transferencias',
          paragraphs: <String>[
            'El tratamiento externo se limita a AlAdhan, geocodificación del sistema y una solicitud opcional de reseña de App Store/Google Play. Pueden tratar registros técnicos según sus términos. No hay SDK de analítica, fallos, anuncios, seguimiento o acceso social.',
            'No se transmiten al desarrollador historial, objetivos ni acciones. Las solicitudes del código usan HTTPS, pero SalahFocus no controla la retención de registros de proveedores.',
          ],
        ),
        LegalSection(
          title: '7. Conservación y eliminación',
          paragraphs: <String>[
            'Los ajustes permanecen hasta cambiarlos, borrar los datos o desinstalar. No hay plazo automático para el historial local. La caché puede sustituirse y las notificaciones caducan o se cancelan al cambiar la programación.',
            'Puedes revocar permisos en ajustes del sistema. Borrar el almacenamiento o desinstalar elimina la base y preferencias de la app. Los datos de un proveedor externo siguen su procedimiento.',
          ],
        ),
        LegalSection(
          title: '8. Base jurídica y derechos',
          paragraphs: <String>[
            'Según proceda, las funciones solicitadas se basan en el artículo 6.1.b del RGPD y el tratamiento sujeto a permiso en el consentimiento del artículo 6.1.a. Puedes retirar permisos para el futuro.',
            'Con los requisitos legales, puedes ejercer acceso, rectificación, supresión, limitación, portabilidad y oposición, y reclamar ante una autoridad. Como la mayoría de datos es local, el responsable normalmente no puede verla ni recuperarla a distancia.',
          ],
        ),
        LegalSection(
          title: '9. Contacto y cambios',
          paragraphs: <String>[
            'Para consultas o derechos escribe a {email}. La política debe actualizarse antes de añadir cuentas, nube, analítica, anuncios, destinatarios o permisos materialmente distintos. La fecha superior identifica esta versión.',
          ],
        ),
      ],
    ),
    'tr': LegalDocument(
      title: 'Gizlilik Politikası',
      lastUpdated: '16 Eylül 2026',
      introduction: 'Bu politika SalahFocus’un mevcut sürümündeki veri işlemesini açıklar; bu sürümde bulunmayan gelecekteki hesap, bulut eşitleme, analiz veya reklam özelliklerini kapsamaz.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Sorumlu ve kapsam',
          paragraphs: <String>[
            'SalahFocus’tan sorumlu kişi {controller}, {location}. İletişim: {email}. LinkedIn: {linkedin}. Kullanıcı hesabı ve geliştiricinin işlettiği hesap/eşitleme sunucusu yoktur.',
          ],
        ),
        LegalSection(
          title: '2. Konum ve coğrafi kodlama',
          paragraphs: <String>[
            'Otomatik konumu seçerseniz uygulama kullanım sırasında hassas konum ister; enlem, boylam, şehir, ülke, saat dilimi ve seçim biçimini saklar. Uygulama çalışırken yaklaşık 1 km mesafe filtresiyle değişiklikleri dinler.',
            'Mevcut sürüm Android arka plan konumu, iOS “Her Zaman” izni veya iOS arka plan konum modu istemez. Şehir ve ülkeyi elle girebilirsiniz. Sistem coğrafi kodlama hizmeti yer/koordinat, dil, IP ve olağan istek verilerini platform sağlayıcısına gönderebilir.',
          ],
        ),
        LegalSection(
          title: '3. Namaz vakitleri ve Kıble',
          paragraphs: <String>[
            'Aylık takvim için enlem, boylam, ay, yıl, hesap yöntemi, Asr ekolü ve yüksek enlem kuralı HTTPS ile api.aladhan.com adresindeki AlAdhan API’ye gönderilir. Hizmet ve ağ IP ile olağan bağlantı verilerini alabilir. Şehir adı ve namaz geçmişi gönderilmez.',
            'Kıble cihazda hesaplanır. Pusula yönü yalnızca gösterim için okunur; SalahFocus bunu saklamaz veya iletmez.',
          ],
        ),
        LegalSection(
          title: '4. Cihazda saklanan veriler',
          paragraphs: <String>[
            'SharedPreferences konum, ayarlar, dil, tema, ilk kurulum, ilk başarılı açılış ve değerlendirme isteği durumunu; SQLite önbellek vakitlerini, saat dilimi/Hicri verileri, durum ve onay/düzenleme/erteleme zamanlarını, ayarları, oruç, Teravih, Kıyam ve Ramazan hedeflerini saklar.',
            'Bu kayıtlar dini pratiği gösterebilir ve hassastır. Mevcut kod kayıtları yerel veritabanında tutar; geliştiriciye veya API’ye yüklemez. Rehber, fotoğraf, mikrofon, sağlık verisi, reklam veya cihaz kimliği erişimi yoktur.',
          ],
        ),
        LegalSection(
          title: '5. Bildirimler ve cihaz özellikleri',
          paragraphs: <String>[
            'İzinle cihazda namaz, cuma, erteleme ve Ramazan bildirimleri planlanır. Metin, tarih, kimlik ve eylemleri işletim sistemi işler; uzak push belirteci veya bildirim sunucusu yoktur. Android kesin alarm, titreşim, açılışta yeniden planlama ve isteğe bağlı tam ekranı; iOS Zamana Duyarlı bildirimleri kullanabilir.',
            'Mevcut iOS hedefinde FamilyControls, ManagedSettings, DeviceActivity, App Group veya Family Controls yetkisi yoktur; Ekran Süresi seçimlerine ya da kullanım verilerine erişilmez.',
          ],
        ),
        LegalSection(
          title: '6. Üçüncü taraflar ve aktarımlar',
          paragraphs: <String>[
            'Harici işleme AlAdhan, sistem coğrafi kodlaması ve isteğe bağlı App Store/Google Play değerlendirme penceresiyle sınırlıdır. Sağlayıcılar teknik günlükleri kendi koşullarına göre işleyebilir. Analiz, çökme raporu, reklam, izleme veya sosyal giriş SDK’sı yoktur.',
            'Namaz/Ramazan geçmişi, hedefler ve bildirim eylemleri geliştiriciye aktarılmaz. Kodda tanımlı istekler HTTPS kullanır; sağlayıcı günlüklerinin saklama süresi SalahFocus’un denetiminde değildir.',
          ],
        ),
        LegalSection(
          title: '7. Saklama ve silme',
          paragraphs: <String>[
            'Yerel ayarlar değiştirilene, uygulama verisi silinene veya uygulama kaldırılana kadar kalır. Yerel geçmiş için otomatik silme süresi yoktur. Önbellek yenilenebilir; bildirimler sona erer veya program değişince iptal edilir.',
            'İzinleri sistem ayarlarından geri alabilirsiniz. Uygulama verisini silmek veya kaldırmak veritabanını ve tercihleri siler. Harici sağlayıcıdaki veriler onun sürecine tabidir.',
          ],
        ),
        LegalSection(
          title: '8. Hukuki dayanak ve haklar',
          paragraphs: <String>[
            'Duruma göre istenen işlevler GDPR Madde 6(1)(b), izne bağlı işleme ise Madde 6(1)(a) kapsamındaki rızaya dayanır. İzni gelecek için geri çekebilirsiniz.',
            'Yasal koşullarla erişim, düzeltme, silme, kısıtlama, taşınabilirlik ve itiraz hakları ile denetim makamına şikâyet hakkınız vardır. Çoğu veri yerel olduğundan sorumlu kişi normalde uzaktan göremez veya kurtaramaz.',
          ],
        ),
        LegalSection(
          title: '9. İletişim ve değişiklikler',
          paragraphs: <String>[
            'Sorular ve hak talepleri için {email}. Hesap, bulut, analiz, reklam, yeni alıcı veya önemli ölçüde farklı izin eklenmeden önce politika güncellenmelidir. Üstteki tarih görüntülenen sürümü belirtir.',
          ],
        ),
      ],
    ),
    'id': LegalDocument(
      title: 'Kebijakan Privasi',
      lastUpdated: '16 September 2026',
      introduction: 'Kebijakan ini menjelaskan pemrosesan data dalam SalahFocus versi saat ini. Fitur akun, sinkronisasi awan, analitik, atau iklan yang belum ada tidak tercakup.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Pengendali dan cakupan',
          paragraphs: <String>[
            'Penanggung jawab SalahFocus adalah {controller}, {location}. Kontak: {email}. LinkedIn: {linkedin}. Tidak ada akun pengguna atau server akun/sinkronisasi yang dioperasikan pengembang.',
          ],
        ),
        LegalSection(
          title: '2. Lokasi dan geocoding',
          paragraphs: <String>[
            'Jika memilih lokasi otomatis, aplikasi meminta lokasi presisi saat digunakan dan menyimpan lintang, bujur, kota, negara, zona waktu, serta cara lokasi dipilih. Saat aplikasi berjalan, mode otomatis mendengarkan perubahan dengan filter jarak sekitar 1 km.',
            'Versi saat ini tidak meminta lokasi latar belakang Android, izin iOS “Selalu”, atau mode lokasi latar belakang iOS. Anda dapat memasukkan kota dan negara. Geocoding sistem dapat mengirim tempat/koordinat, bahasa, alamat IP, dan metadata permintaan biasa kepada penyedia platform.',
          ],
        ),
        LegalSection(
          title: '3. Waktu salat dan Kiblat',
          paragraphs: <String>[
            'Untuk kalender bulanan, lintang, bujur, bulan, tahun, metode perhitungan, mazhab Asar, dan aturan lintang tinggi dikirim melalui HTTPS ke API AlAdhan di api.aladhan.com. Layanan dan jaringan dapat menerima IP serta data koneksi biasa. Nama kota dan riwayat salat tidak dikirim.',
            'Arah Kiblat dihitung di perangkat. Arah kompas hanya dibaca untuk tampilan dan tidak disimpan atau dikirim oleh SalahFocus.',
          ],
        ),
        LegalSection(
          title: '4. Data yang disimpan di perangkat',
          paragraphs: <String>[
            'SharedPreferences menyimpan lokasi, pengaturan, bahasa, tema, status orientasi awal, waktu peluncuran pertama, dan status permintaan ulasan. SQLite menyimpan cache waktu salat, zona waktu/Hijriah, status dan waktu konfirmasi/edit/tunda, penyesuaian, puasa, Tarawih, Qiyam, judul sasaran Ramadan, dan penyelesaiannya.',
            'Catatan ini dapat mengungkap praktik agama dan bersifat sensitif. Kode saat ini menyimpannya secara lokal dan tidak mengunggahnya kepada pengembang atau API. Aplikasi tidak mengakses kontak, foto, mikrofon, data kesehatan, ID iklan, atau ID perangkat lainnya.',
          ],
        ),
        LegalSection(
          title: '5. Notifikasi dan fitur perangkat',
          paragraphs: <String>[
            'Dengan izin, notifikasi salat, Jumat, tunda, dan Ramadan dijadwalkan secara lokal. Sistem operasi menangani teks, tanggal, ID, dan tindakan; tidak ada token push jarak jauh atau server notifikasi. Android dapat memakai alarm tepat, getaran, penjadwalan setelah boot, dan layar penuh opsional; iOS dapat memakai notifikasi Peka Waktu.',
            'Target iOS saat ini tidak memiliki FamilyControls, ManagedSettings, DeviceActivity, App Group, atau hak Family Controls, sehingga tidak mengakses pilihan atau data Durasi Layar.',
          ],
        ),
        LegalSection(
          title: '6. Pihak ketiga dan transfer',
          paragraphs: <String>[
            'Pemrosesan eksternal terbatas pada AlAdhan, geocoding sistem, dan dialog ulasan App Store/Google Play opsional. Penyedia dapat memproses log teknis berdasarkan ketentuan mereka. Tidak ada SDK analitik, laporan crash, iklan, pelacakan, atau login sosial.',
            'Riwayat salat/Ramadan, sasaran, dan tindakan notifikasi tidak dikirim kepada pengembang. Permintaan dalam kode memakai HTTPS, tetapi retensi log penyedia tidak dikendalikan SalahFocus.',
          ],
        ),
        LegalSection(
          title: '7. Retensi dan penghapusan',
          paragraphs: <String>[
            'Pengaturan lokal tetap ada sampai diubah, data aplikasi dihapus, atau aplikasi dicopot. Tidak ada masa penghapusan otomatis untuk riwayat lokal. Cache dapat diganti dan notifikasi berakhir atau dibatalkan saat jadwal berubah.',
            'Izin dapat dicabut di pengaturan sistem. Menghapus penyimpanan atau mencopot aplikasi menghapus basis data dan preferensi yang dikelola aplikasi. Data penyedia eksternal mengikuti proses penyedia itu.',
          ],
        ),
        LegalSection(
          title: '8. Dasar hukum dan hak',
          paragraphs: <String>[
            'Sesuai konteks, fungsi yang diminta didasarkan pada Pasal 6(1)(b) GDPR dan pemrosesan berbasis izin pada persetujuan Pasal 6(1)(a). Anda dapat mencabut izin untuk masa depan.',
            'Sesuai syarat hukum, Anda dapat meminta akses, koreksi, penghapusan, pembatasan, portabilitas, keberatan, dan mengadu kepada otoritas. Karena sebagian besar data lokal, pengendali biasanya tidak dapat melihat atau memulihkannya dari jarak jauh.',
          ],
        ),
        LegalSection(
          title: '9. Kontak dan perubahan',
          paragraphs: <String>[
            'Untuk pertanyaan atau permintaan hak, hubungi {email}. Kebijakan harus diperbarui sebelum menambah akun, awan, analitik, iklan, penerima baru, atau izin yang berbeda secara material. Tanggal di atas menunjukkan versi ini.',
          ],
        ),
      ],
    ),
    'ms': LegalDocument(
      title: 'Dasar Privasi',
      lastUpdated: '16 September 2026',
      introduction: 'Dasar ini menerangkan pemprosesan data dalam versi semasa SalahFocus. Ia tidak meliputi akaun, penyegerakan awan, analitik atau pengiklanan masa hadapan yang belum wujud.',
      sections: <LegalSection>[
        LegalSection(
          title: '1. Pengawal dan skop',
          paragraphs: <String>[
            'Orang yang bertanggungjawab terhadap SalahFocus ialah {controller}, {location}. Hubungan: {email}. LinkedIn: {linkedin}. Tiada akaun pengguna atau pelayan akaun/penyegerakan yang dikendalikan pembangun.',
          ],
        ),
        LegalSection(
          title: '2. Lokasi dan pengekodan geo',
          paragraphs: <String>[
            'Jika lokasi automatik dipilih, aplikasi meminta lokasi tepat semasa digunakan dan menyimpan latitud, longitud, bandar, negara, zon waktu serta cara lokasi dipilih. Semasa aplikasi berjalan, perubahan didengar dengan penapis jarak kira-kira 1 km.',
            'Versi semasa tidak meminta lokasi latar Android, kebenaran iOS “Sentiasa” atau mod lokasi latar iOS. Anda boleh memasukkan bandar dan negara. Perkhidmatan geo sistem boleh menghantar tempat/koordinat, bahasa, IP dan metadata biasa kepada penyedia platform.',
          ],
        ),
        LegalSection(
          title: '3. Waktu solat dan Kiblat',
          paragraphs: <String>[
            'Untuk kalendar bulanan, latitud, longitud, bulan, tahun, kaedah, mazhab Asar dan peraturan latitud tinggi dihantar melalui HTTPS ke API AlAdhan di api.aladhan.com. Perkhidmatan dan rangkaian boleh menerima IP dan data sambungan biasa. Nama bandar dan sejarah solat tidak dihantar.',
            'Arah Kiblat dikira pada peranti. Arah kompas hanya dibaca untuk paparan dan tidak disimpan atau dihantar oleh SalahFocus.',
          ],
        ),
        LegalSection(
          title: '4. Data pada peranti',
          paragraphs: <String>[
            'SharedPreferences menyimpan lokasi, tetapan, bahasa, tema, status pengenalan, masa pelancaran pertama dan status permintaan ulasan. SQLite menyimpan cache waktu, zon waktu/Hijri, status serta masa pengesahan/sunting/tunda, pelarasan, puasa, Tarawih, Qiyam, tajuk matlamat Ramadan dan penyelesaian.',
            'Rekod ini boleh mendedahkan amalan agama dan bersifat sensitif. Kod semasa menyimpannya secara setempat dan tidak memuat naik kepada pembangun atau API. Aplikasi tidak mengakses kenalan, foto, mikrofon, data kesihatan, ID iklan atau ID peranti lain.',
          ],
        ),
        LegalSection(
          title: '5. Pemberitahuan dan ciri peranti',
          paragraphs: <String>[
            'Dengan kebenaran, pemberitahuan solat, Jumaat, tunda dan Ramadan dijadualkan secara setempat. Sistem mengurus teks, tarikh, ID dan tindakan; tiada token push jauh atau pelayan. Android boleh menggunakan penggera tepat, getaran, penjadualan selepas but dan skrin penuh pilihan; iOS boleh menggunakan pemberitahuan Sensitif Masa.',
            'Sasaran iOS semasa tidak mempunyai FamilyControls, ManagedSettings, DeviceActivity, App Group atau kelayakan Family Controls, maka data Masa Skrin tidak diakses.',
          ],
        ),
        LegalSection(
          title: '6. Pihak ketiga dan pemindahan',
          paragraphs: <String>[
            'Pemprosesan luar terhad kepada AlAdhan, geokod sistem dan gesaan ulasan App Store/Google Play pilihan. Penyedia boleh memproses log teknikal mengikut syarat mereka. Tiada SDK analitik, laporan ranap, iklan, penjejakan atau log masuk sosial.',
            'Sejarah solat/Ramadan, matlamat dan tindakan pemberitahuan tidak dihantar kepada pembangun. Permintaan kod menggunakan HTTPS, tetapi pengekalan log penyedia bukan di bawah kawalan SalahFocus.',
          ],
        ),
        LegalSection(
          title: '7. Pengekalan dan pemadaman',
          paragraphs: <String>[
            'Tetapan kekal sehingga diubah, data aplikasi dipadam atau aplikasi dinyahpasang. Tiada tempoh pemadaman automatik bagi sejarah setempat. Cache boleh diganti dan pemberitahuan tamat atau dibatalkan apabila jadual berubah.',
            'Kebenaran boleh ditarik balik dalam tetapan sistem. Memadam storan atau menyahpasang memadam pangkalan data dan pilihan aplikasi. Data penyedia luar tertakluk pada prosesnya.',
          ],
        ),
        LegalSection(
          title: '8. Asas undang-undang dan hak',
          paragraphs: <String>[
            'Mengikut keadaan, fungsi diminta berasaskan Artikel 6(1)(b) GDPR dan pemprosesan berizin pada persetujuan Artikel 6(1)(a). Kebenaran boleh ditarik balik untuk masa hadapan.',
            'Tertakluk pada undang-undang, anda boleh meminta akses, pembetulan, pemadaman, sekatan, mudah alih, membantah dan mengadu kepada pihak berkuasa. Oleh sebab kebanyakan data setempat, pengawal biasanya tidak boleh melihat atau memulihkannya dari jauh.',
          ],
        ),
        LegalSection(
          title: '9. Hubungan dan perubahan',
          paragraphs: <String>[
            'Untuk soalan atau permintaan hak, hubungi {email}. Dasar mesti dikemas kini sebelum menambah akaun, awan, analitik, iklan, penerima baharu atau kebenaran yang berbeza secara ketara. Tarikh di atas mengenal pasti versi ini.',
          ],
        ),
      ],
    ),
    'bn': LegalDocument(
      title: 'গোপনীয়তা নীতি',
      lastUpdated: '১৬ সেপ্টেম্বর ২০২৬',
      introduction: 'এই নীতি SalahFocus-এর বর্তমান সংস্করণে ডেটা প্রক্রিয়াকরণ ব্যাখ্যা করে। এই সংস্করণে না থাকা ভবিষ্যৎ অ্যাকাউন্ট, ক্লাউড সিঙ্ক, অ্যানালিটিক্স বা বিজ্ঞাপন এতে অন্তর্ভুক্ত নয়।',
      sections: <LegalSection>[
        LegalSection(
          title: '১. নিয়ন্ত্রক ও পরিধি',
          paragraphs: <String>[
            'SalahFocus-এর দায়িত্বপ্রাপ্ত ব্যক্তি {controller}, {location}। যোগাযোগ: {email}। LinkedIn: {linkedin}। কোনো ব্যবহারকারী অ্যাকাউন্ট বা ডেভেলপার-চালিত অ্যাকাউন্ট/সিঙ্ক সার্ভার নেই।',
          ],
        ),
        LegalSection(
          title: '২. অবস্থান ও জিওকোডিং',
          paragraphs: <String>[
            'স্বয়ংক্রিয় অবস্থান নিলে অ্যাপ ব্যবহারের সময় নির্ভুল অবস্থান চায় এবং অক্ষাংশ, দ্রাঘিমাংশ, শহর, দেশ, সময় অঞ্চল ও নির্বাচনের ধরন সংরক্ষণ করে। অ্যাপ চলাকালে প্রায় ১ কিমি দূরত্ব ফিল্টারে পরিবর্তন শোনা হয়।',
            'বর্তমান সংস্করণ Android ব্যাকগ্রাউন্ড লোকেশন, iOS “Always” অনুমতি বা iOS ব্যাকগ্রাউন্ড লোকেশন মোড চায় না। শহর ও দেশ হাতে দেওয়া যায়। সিস্টেম জিওকোডিং স্থান/স্থানাঙ্ক, ভাষা, IP ও সাধারণ অনুরোধ তথ্য প্ল্যাটফর্ম সরবরাহকারীর কাছে পাঠাতে পারে।',
          ],
        ),
        LegalSection(
          title: '৩. নামাজের সময় ও কিবলা',
          paragraphs: <String>[
            'মাসিক ক্যালেন্ডারের জন্য অক্ষাংশ, দ্রাঘিমাংশ, মাস, বছর, গণনা পদ্ধতি, আসর মাযহাব ও উচ্চ অক্ষাংশ নিয়ম HTTPS-এ api.aladhan.com-এর AlAdhan API-তে যায়। সেবা ও নেটওয়ার্ক IP ও সাধারণ সংযোগ তথ্য পেতে পারে। শহরের নাম বা নামাজের ইতিহাস যায় না।',
            'কিবলা ডিভাইসেই হিসাব হয়। কম্পাসের দিক শুধু দেখানোর জন্য পড়া হয়; SalahFocus তা সংরক্ষণ বা পাঠায় না।',
          ],
        ),
        LegalSection(
          title: '৪. ডিভাইসে সংরক্ষিত ডেটা',
          paragraphs: <String>[
            'SharedPreferences অবস্থান, সেটিংস, ভাষা, থিম, অনবোর্ডিং, প্রথম চালুর সময় ও রিভিউ অনুরোধের অবস্থা রাখে। SQLite সময়ের ক্যাশ, সময় অঞ্চল/হিজরি তথ্য, অবস্থা ও নিশ্চিত/সম্পাদনা/স্নুজ সময়, সমন্বয়, রোজা, তারাবিহ, কিয়াম, রমজান লক্ষ্য ও সম্পন্ন হওয়া রাখে।',
            'এসব রেকর্ড ধর্মীয় অনুশীলন প্রকাশ করতে পারে এবং সংবেদনশীল। বর্তমান কোড এগুলো স্থানীয়ভাবে রাখে; ডেভেলপার বা API-তে আপলোড করে না। অ্যাপ পরিচিতি, ছবি, মাইক্রোফোন, স্বাস্থ্য তথ্য, বিজ্ঞাপন বা অন্য ডিভাইস ID ব্যবহার করে না।',
          ],
        ),
        LegalSection(
          title: '৫. নোটিফিকেশন ও ডিভাইস বৈশিষ্ট্য',
          paragraphs: <String>[
            'অনুমতি দিলে নামাজ, জুমা, স্নুজ ও রমজান নোটিফিকেশন ডিভাইসে নির্ধারিত হয়। লেখা, তারিখ, ID ও কাজ অপারেটিং সিস্টেম সামলায়; দূরবর্তী push token বা সার্ভার নেই। Android সঠিক alarm, vibration, boot-এর পর পুনঃনির্ধারণ ও ঐচ্ছিক full-screen; iOS Time Sensitive নোটিফিকেশন ব্যবহার করতে পারে।',
            'বর্তমান iOS টার্গেটে FamilyControls, ManagedSettings, DeviceActivity, App Group বা Family Controls entitlement নেই; Screen Time নির্বাচন বা ব্যবহার ডেটা নেওয়া হয় না।',
          ],
        ),
        LegalSection(
          title: '৬. তৃতীয় পক্ষ ও স্থানান্তর',
          paragraphs: <String>[
            'বাহ্যিক প্রক্রিয়াকরণ AlAdhan, সিস্টেম জিওকোডিং এবং ঐচ্ছিক App Store/Google Play রিভিউ প্রম্পটে সীমিত। সরবরাহকারীরা নিজ শর্তে প্রযুক্তিগত লগ রাখতে পারে। কোনো অ্যানালিটিক্স, ক্র্যাশ, বিজ্ঞাপন, ট্র্যাকিং বা সামাজিক লগইন SDK নেই।',
            'নামাজ/রমজান ইতিহাস, লক্ষ্য বা নোটিফিকেশন কাজ ডেভেলপারের কাছে যায় না। কোডের অনুরোধ HTTPS ব্যবহার করে, তবে সরবরাহকারীর লগ ধরে রাখা SalahFocus নিয়ন্ত্রণ করে না।',
          ],
        ),
        LegalSection(
          title: '৭. সংরক্ষণ ও মুছে ফেলা',
          paragraphs: <String>[
            'স্থানীয় সেটিংস পরিবর্তন, অ্যাপ ডেটা মুছা বা আনইনস্টল পর্যন্ত থাকে। ইতিহাসের স্বয়ংক্রিয় মেয়াদ নেই। ক্যাশ বদলাতে পারে এবং সময়সূচি বদলালে নোটিফিকেশন শেষ বা বাতিল হয়।',
            'সিস্টেম সেটিংসে অনুমতি প্রত্যাহার করা যায়। স্টোরেজ মুছলে বা আনইনস্টল করলে অ্যাপের ডেটাবেস ও পছন্দ মুছে যায়। বাহ্যিক সরবরাহকারীর ডেটা তার প্রক্রিয়ার অধীন।',
          ],
        ),
        LegalSection(
          title: '৮. আইনি ভিত্তি ও অধিকার',
          paragraphs: <String>[
            'প্রযোজ্য ক্ষেত্রে অনুরোধ করা ফাংশনের ভিত্তি GDPR 6(1)(b), আর অনুমতিনির্ভর প্রক্রিয়ার সম্মতির ভিত্তি 6(1)(a)। ভবিষ্যতের জন্য অনুমতি প্রত্যাহার করা যায়।',
            'আইনি শর্তে প্রবেশাধিকার, সংশোধন, মুছা, সীমাবদ্ধতা, বহনযোগ্যতা, আপত্তি ও কর্তৃপক্ষের কাছে অভিযোগের অধিকার আছে। অধিকাংশ ডেটা স্থানীয় হওয়ায় নিয়ন্ত্রক সাধারণত দূর থেকে তা দেখতে বা ফেরাতে পারেন না।',
          ],
        ),
        LegalSection(
          title: '৯. যোগাযোগ ও পরিবর্তন',
          paragraphs: <String>[
            'প্রশ্ন বা অধিকার অনুরোধের জন্য {email}। অ্যাকাউন্ট, ক্লাউড, অ্যানালিটিক্স, বিজ্ঞাপন, নতুন প্রাপক বা ভিন্ন অনুমতি যোগের আগে নীতি হালনাগাদ করতে হবে। ওপরের তারিখ এই সংস্করণ চিহ্নিত করে।',
          ],
        ),
      ],
    ),
    'fa': LegalDocument(
      title: 'سیاست حریم خصوصی',
      lastUpdated: '۱۶ سپتامبر ۲۰۲۶',
      introduction: 'این سیاست پردازش داده در نسخهٔ فعلی SalahFocus را توضیح می‌دهد و شامل حساب، همگام‌سازی ابری، تحلیل یا تبلیغات آینده که اکنون وجود ندارند نیست.',
      sections: <LegalSection>[
        LegalSection(
          title: '۱. مسئول و دامنه',
          paragraphs: <String>[
            'مسئول SalahFocus، {controller}، {location} است. تماس: {email}. لینکدین: {linkedin}. حساب کاربری یا سرور حساب/همگام‌سازی تحت ادارهٔ توسعه‌دهنده وجود ندارد.',
          ],
        ),
        LegalSection(
          title: '۲. مکان و ژئوکدینگ',
          paragraphs: <String>[
            'با انتخاب مکان خودکار، برنامه هنگام استفاده مکان دقیق را می‌خواهد و عرض و طول جغرافیایی، شهر، کشور، منطقهٔ زمانی و نوع انتخاب را ذخیره می‌کند. هنگام اجرای برنامه تغییرات با فیلتر حدود یک کیلومتر شنیده می‌شود.',
            'نسخهٔ فعلی مکان پس‌زمینهٔ Android، مجوز «همیشه» iOS یا حالت مکان پس‌زمینهٔ iOS را درخواست نمی‌کند. می‌توانید شهر و کشور را دستی وارد کنید. ژئوکدینگ سیستم ممکن است مکان/مختصات، زبان، IP و فرادادهٔ معمول را به ارائه‌دهندهٔ پلتفرم بفرستد.',
          ],
        ),
        LegalSection(
          title: '۳. اوقات نماز و قبله',
          paragraphs: <String>[
            'برای تقویم ماهانه، مختصات، ماه، سال، روش محاسبه، مذهب عصر و قاعدهٔ عرض‌های بالا با HTTPS به API ‏AlAdhan در api.aladhan.com فرستاده می‌شود. سرویس و شبکه ممکن است IP و دادهٔ اتصال را دریافت کنند. نام شهر و سابقهٔ نماز ارسال نمی‌شود.',
            'قبله روی دستگاه محاسبه می‌شود. جهت قطب‌نما فقط برای نمایش خوانده می‌شود و SalahFocus آن را ذخیره یا ارسال نمی‌کند.',
          ],
        ),
        LegalSection(
          title: '۴. دادهٔ ذخیره‌شده روی دستگاه',
          paragraphs: <String>[
            'SharedPreferences مکان، تنظیمات، زبان، پوسته، راه‌اندازی اولیه، زمان نخستین اجرا و وضعیت درخواست امتیاز را نگه می‌دارد. SQLite کش اوقات، منطقهٔ زمانی/هجری، وضعیت و زمان تأیید/ویرایش/تعویق، تنظیمات دقیقه‌ای، روزه، تراویح، قیام، عنوان اهداف رمضان و تکمیل آن‌ها را ذخیره می‌کند.',
            'این سوابق ممکن است عمل دینی را نشان دهند و حساس‌اند. کد فعلی آن‌ها را محلی نگه می‌دارد و برای توسعه‌دهنده یا API بارگذاری نمی‌کند. مخاطبان، عکس، میکروفن، سلامت، شناسهٔ تبلیغاتی یا سایر شناسه‌های دستگاه خوانده نمی‌شوند.',
          ],
        ),
        LegalSection(
          title: '۵. اعلان‌ها و قابلیت‌های دستگاه',
          paragraphs: <String>[
            'با اجازه، اعلان نماز، جمعه، تعویق و رمضان محلی زمان‌بندی می‌شود. سیستم متن، تاریخ، شناسه و اقدام را مدیریت می‌کند؛ توکن push یا سرور اعلان وجود ندارد. Android می‌تواند از زنگ دقیق، لرزش، زمان‌بندی پس از راه‌اندازی و تمام‌صفحهٔ اختیاری و iOS از اعلان Time Sensitive استفاده کند.',
            'هدف فعلی iOS شامل FamilyControls، ManagedSettings، DeviceActivity، App Group یا مجوز Family Controls نیست؛ بنابراین داده یا انتخاب Screen Time خوانده نمی‌شود.',
          ],
        ),
        LegalSection(
          title: '۶. اشخاص ثالث و انتقال',
          paragraphs: <String>[
            'پردازش خارجی به AlAdhan، ژئوکدینگ سیستم و درخواست اختیاری امتیاز App Store/Google Play محدود است. ارائه‌دهندگان ممکن است طبق شرایط خود گزارش فنی پردازش کنند. SDK تحلیل، خرابی، تبلیغ، ردیابی یا ورود اجتماعی وجود ندارد.',
            'سابقهٔ نماز/رمضان، اهداف و اقدامات اعلان برای توسعه‌دهنده ارسال نمی‌شود. درخواست‌های کد HTTPS هستند، اما نگهداری گزارش ارائه‌دهندگان در کنترل SalahFocus نیست.',
          ],
        ),
        LegalSection(
          title: '۷. نگهداری و حذف',
          paragraphs: <String>[
            'تنظیمات تا تغییر، پاک‌کردن داده یا حذف برنامه باقی می‌ماند. برای سابقهٔ محلی حذف خودکار تعیین نشده است. کش ممکن است جایگزین شود و اعلان‌ها با تغییر برنامه منقضی یا لغو می‌شوند.',
            'مجوزها را می‌توان در تنظیمات سیستم پس گرفت. پاک‌کردن فضای SalahFocus یا حذف برنامه پایگاه داده و ترجیحات را حذف می‌کند. دادهٔ ارائه‌دهندهٔ خارجی تابع فرایند اوست.',
          ],
        ),
        LegalSection(
          title: '۸. مبنای حقوقی و حقوق شما',
          paragraphs: <String>[
            'برحسب مورد، قابلیت درخواستی بر مادهٔ 6(1)(b) ‏GDPR و پردازش مجوزمحور بر رضایت مادهٔ 6(1)(a) استوار است. مجوز را می‌توان برای آینده پس گرفت.',
            'با شرایط قانونی حق دسترسی، اصلاح، حذف، محدودسازی، انتقال، اعتراض و شکایت نزد مرجع حفاظت داده دارید. چون بیشتر داده محلی است، مسئول معمولاً نمی‌تواند آن را از راه دور ببیند یا بازیابی کند.',
          ],
        ),
        LegalSection(
          title: '۹. تماس و تغییرات',
          paragraphs: <String>[
            'برای پرسش یا درخواست حقوق با {email} تماس بگیرید. پیش از افزودن حساب، ابر، تحلیل، تبلیغ، دریافت‌کنندهٔ جدید یا مجوز متفاوت، سیاست باید به‌روز شود. تاریخ بالا نسخه را مشخص می‌کند.',
          ],
        ),
      ],
    ),
    'pa': LegalDocument(
      title: 'رازداری پالیسی',
      lastUpdated: '۱۶ ستمبر ۲۰۲۶',
      introduction: 'ایہہ پالیسی SalahFocus دے موجودہ ورژن وچ ڈیٹا پراسیسنگ دسدے اے۔ مستقبل دے اکاؤنٹ، کلاؤڈ سنک، تجزیے یا اشتہار جیہڑے ہن موجود نئیں، ایس وچ شامل نئیں۔',
      sections: <LegalSection>[
        LegalSection(
          title: '۱. ذمہ وار تے دائرہ',
          paragraphs: <String>[
            'SalahFocus دا ذمہ وار {controller}، {location} اے۔ رابطہ: {email}۔ LinkedIn: {linkedin}۔ صارف اکاؤنٹ یا ڈویلپر دا اکاؤنٹ/سنک سرور نئیں۔',
          ],
        ),
        LegalSection(
          title: '۲. تھاں تے جیوکوڈنگ',
          paragraphs: <String>[
            'خودکار تھاں چنّن تے ایپ ورتدیاں درست تھاں منگدی تے عرض، طول، شہر، ملک، وقت دا علاقہ تے انتخاب دا طریقہ محفوظ کردی اے۔ ایپ چلدی ہووے تے لگ بھگ ۱ کلومیٹر فلٹر نال تبدیلیاں سن دی اے۔',
            'موجودہ ورژن Android پس منظر تھاں، iOS “Always” اجازت یا iOS پس منظر موڈ نئیں منگدا۔ شہر تے ملک ہتھ نال دِتے جا سکدے نیں۔ سسٹم جیوکوڈنگ تھاں/مختصات، زبان، IP تے عام میٹاڈیٹا پلیٹ فارم نوں بھیج سکدی اے۔',
          ],
        ),
        LegalSection(
          title: '۳. نماز دے ویلے تے قبلہ',
          paragraphs: <String>[
            'مہینے دے کیلنڈر لئی مختصات، مہینہ، سال، حساب طریقہ، عصر فقہ تے اونچی عرض دا اصول HTTPS نال api.aladhan.com دے AlAdhan API نوں جاندا اے۔ سروس تے نیٹ ورک IP تے عام کنکشن ڈیٹا لے سکدے نیں۔ شہر دا ناں تے نماز تاریخ نئیں بھیجی جاندی۔',
            'قبلہ ڈیوائس تے حساب ہوندا اے۔ کمپاس سمت صرف دکھاؤن لئی پڑھی جاندی تے SalahFocus محفوظ یا منتقل نئیں کردا۔',
          ],
        ),
        LegalSection(
          title: '۴. ڈیوائس تے محفوظ ڈیٹا',
          paragraphs: <String>[
            'SharedPreferences تھاں، ترتیباں، زبان، تھیم، شروعات، پہلی کامیاب شروعات تے ریویو حالت رکھدا اے۔ SQLite نماز ویلے، ٹائم زون/ہجری، حالت، تصدیق/ترمیم/سنوز وقت، ایڈجسٹمنٹ، روزہ، تراویح، قیام، رمضان مقصد تے تکمیل رکھدا اے۔',
            'ایہہ ریکارڈ مذہبی عمل ظاہر کر سکدے تے حساس نیں۔ موجودہ کوڈ انہاں نوں مقامی رکھدا تے ڈویلپر یا API نوں اپلوڈ نئیں کردا۔ رابطے، تصویراں، مائک، صحت، اشتہاری یا ہور ڈیوائس ID نئیں ورتے جاندے۔',
          ],
        ),
        LegalSection(
          title: '۵. اطلاعات تے ڈیوائس سہولتاں',
          paragraphs: <String>[
            'اجازت نال نماز، جمعہ، سنوز تے رمضان اطلاعات ڈیوائس تے شیڈول ہوندیاں۔ سسٹم متن، تاریخ، ID تے عمل سنبھالدا؛ ریموٹ push token یا سرور نئیں۔ Android درست الارم، وائبریشن، بوٹ توں بعد شیڈول تے اختیاری پوری سکرین؛ iOS Time Sensitive اطلاع ورت سکدا اے۔',
            'موجودہ iOS ٹارگٹ وچ FamilyControls، ManagedSettings، DeviceActivity، App Group یا Family Controls entitlement نئیں؛ Screen Time ڈیٹا نئیں پڑھیا جاندا۔',
          ],
        ),
        LegalSection(
          title: '۶. تیجی دھراں تے منتقلی',
          paragraphs: <String>[
            'باہرلی پراسیسنگ AlAdhan، سسٹم جیوکوڈنگ تے اختیاری App Store/Google Play ریویو تک محدود اے۔ فراہم کنندے اپنے شرطاں نال تکنیکی لاگ رکھ سکدے نیں۔ تجزیہ، کریش، اشتہار، ٹریکنگ یا سماجی لاگ اِن SDK نئیں۔',
            'نماز/رمضان تاریخ، مقصد تے اطلاع عمل ڈویلپر نوں نئیں جاندا۔ کوڈ دیاں درخواستاں HTTPS نیں، پر فراہم کنندے دے لاگ دی مدت SalahFocus دے قابو وچ نئیں۔',
          ],
        ),
        LegalSection(
          title: '۷. رکھائی تے مٹانا',
          paragraphs: <String>[
            'مقامی ترتیباں بدلّن، ڈیٹا مٹاؤن یا ایپ ہٹاؤن تک رہندیاں۔ تاریخ لئی خودکار مٹاؤن دی مدت نئیں۔ کیش بدل سکدا تے شیڈول بدلّن تے اطلاعات ختم یا منسوخ ہوندیاں۔',
            'سسٹم ترتیباں وچ اجازتاں واپس لئیاں جا سکدیاں۔ سٹوریج مٹاؤن یا ایپ ہٹاؤن نال ڈیٹابیس تے ترجیحاں مٹ جاندیاں۔ باہرلے فراہم کنندے دا ڈیٹا اوہدے طریقے دے تابع اے۔',
          ],
        ),
        LegalSection(
          title: '۸. قانونی بنیاد تے حق',
          paragraphs: <String>[
            'حالت مطابق منگی سہولت GDPR 6(1)(b) تے اجازت والی پراسیسنگ رضامندی 6(1)(a) تے اے۔ اجازت مستقبل لئی واپس لئی جا سکدی اے۔',
            'قانونی شرطاں نال رسائی، درستگی، مٹانا، پابندی، منتقلی، اعتراض تے نگران ادارے کول شکایت دا حق اے۔ زیادہ ڈیٹا مقامی اے، ایس لئی ذمہ وار عام طور تے دوروں ویکھ یا واپس نئیں کر سکدا۔',
          ],
        ),
        LegalSection(
          title: '۹. رابطہ تے تبدیلیاں',
          paragraphs: <String>[
            'سوال یا حق دی درخواست لئی {email}۔ اکاؤنٹ، کلاؤڈ، تجزیہ، اشتہار، نواں وصول کنندہ یا وکھری اجازت شامل کرن توں پہلاں پالیسی تازہ کرنا ضروری اے۔ اوپر دی تاریخ ایس ورژن دی اے۔',
          ],
        ),
      ],
    ),
    'ps': LegalDocument(
      title: 'د محرمیت تګلاره',
      lastUpdated: '۱۶ سپتمبر ۲۰۲۶',
      introduction: 'دا تګلاره د SalahFocus په اوسنۍ نسخه کې د معلوماتو پروسس بیانوي. راتلونکي حسابونه، کلاوډ همغږي، شننه یا اعلانونه چې اوس نشته پکې نه شاملېږي.',
      sections: <LegalSection>[
        LegalSection(
          title: '۱. مسؤول او ساحه',
          paragraphs: <String>[
            'د SalahFocus مسؤول {controller}، {location} دی. اړیکه: {email}. LinkedIn: {linkedin}. د کارن حساب یا د جوړوونکي حساب/همغږي سرور نشته.',
          ],
        ),
        LegalSection(
          title: '۲. ځای او جیوکوډنګ',
          paragraphs: <String>[
            'د اتومات ځای په ټاکلو اپ د کارونې پر مهال دقیق ځای غواړي او عرض، طول، ښار، هېواد، وخت زون او د ټاکنې ډول ساتي. د اپ د چلولو پر مهال بدلونونه د نږدې ۱ کیلومتر فلټر سره اوري.',
            'اوسنۍ نسخه د Android شالید ځای، د iOS «تل» اجازه یا د iOS شالید ځای حالت نه غواړي. ښار او هېواد لاسي ټاکل کېدای شي. د سیستم جیوکوډنګ ځای/مختصات، ژبه، IP او عادي معلومات د پلاتفورم برابرونکي ته لېږلی شي.',
          ],
        ),
        LegalSection(
          title: '۳. د لمانځه وختونه او قبله',
          paragraphs: <String>[
            'د میاشتني کلیزې لپاره مختصات، میاشت، کال، د حساب طریقه، د عصر مذهب او د لوړو عرضونو قاعده په HTTPS سره api.aladhan.com د AlAdhan API ته ځي. خدمت او شبکه IP او عادي نښلون معلومات اخیستلی شي. د ښار نوم او د لمانځه تاریخ نه لېږل کېږي.',
            'قبله په وسیله کې حسابېږي. د کمپاس لوری یوازې د ښودلو لپاره لوستل کېږي او SalahFocus یې نه ساتي او نه لېږي.',
          ],
        ),
        LegalSection(
          title: '۴. په وسیله کې ساتل شوي معلومات',
          paragraphs: <String>[
            'SharedPreferences ځای، امستنې، ژبه، بڼه، پیل، د لومړي چلولو وخت او د ارزونې غوښتنې حالت ساتي. SQLite د وختونو زېرمه، وخت زون/هجري، حالت، تایید/سمون/ځنډ وختونه، تعدیلات، روژه، تراویح، قیام، رمضان موخې او بشپړونه ساتي.',
            'دا ریکارډونه مذهبي عمل ښودلی شي او حساس دي. اوسنی کوډ یې محلي ساتي او جوړوونکي یا API ته یې نه پورته کوي. اړیکې، انځورونه، مایکروفون، روغتیا، اعلاني یا نور وسیله پېژندونه نه کارول کېږي.',
          ],
        ),
        LegalSection(
          title: '۵. خبرتیاوې او د وسیلې ځانګړنې',
          paragraphs: <String>[
            'له اجازې سره د لمانځه، جمعې، ځنډ او رمضان خبرتیاوې محلي مهالویش کېږي. سیستم متن، نېټه، پېژند او عمل سمبالوي؛ لرې push token یا سرور نشته. Android دقیق الارم، رپ، له چالانېدو وروسته مهالویش او اختیاري بشپړ سکرین؛ iOS Time Sensitive خبرتیا کارولی شي.',
            'اوسنی iOS هدف FamilyControls، ManagedSettings، DeviceActivity، App Group یا Family Controls حق نه لري؛ د Screen Time معلومات نه لوستل کېږي.',
          ],
        ),
        LegalSection(
          title: '۶. درېیم خدمتونه او لېږد',
          paragraphs: <String>[
            'بهرنی پروسس AlAdhan، د سیستم جیوکوډنګ او اختیاري App Store/Google Play ارزونې ته محدود دی. برابرونکي تخنیکي ثبتونه د خپلو شرطونو له مخې پروسس کولی شي. د شننې، خرابۍ، اعلان، تعقیب یا ټولنیز ننوتلو SDK نشته.',
            'د لمانځه/رمضان تاریخ، موخې او د خبرتیا عمل جوړوونکي ته نه ځي. د کوډ غوښتنې HTTPS دي، خو د برابرونکي د ثبتونو ساتنه د SalahFocus تر کنټرول لاندې نه ده.',
          ],
        ),
        LegalSection(
          title: '۷. ساتنه او ړنګول',
          paragraphs: <String>[
            'محلي امستنې تر بدلولو، د اپ معلوماتو پاکولو یا اپ ړنګولو پاتې کېږي. د تاریخ اتومات ړنګولو موده نشته. زېرمه بدلېدای او خبرتیاوې د مهالویش په بدلون ختمېږي.',
            'اجازې د سیستم په امستنو کې بېرته اخیستل کېدای شي. د زېرمتون پاکول یا د اپ لرې کول ډیټابیس او غوره توبونه ړنګوي. د بهرني برابرونکي معلومات د هغه پروسې تابع دي.',
          ],
        ),
        LegalSection(
          title: '۸. قانوني بنسټ او حقونه',
          paragraphs: <String>[
            'د حالت له مخې غوښتل شوې دنده د GDPR 6(1)(b) او اجازې پروسس د 6(1)(a) رضایت پر بنسټ دی. اجازه د راتلونکي لپاره بېرته اخیستل کېدای شي.',
            'د قانوني شرطونو سره د لاسرسي، سمون، ړنګولو، محدودولو، لېږد، اعتراض او ادارې ته د شکایت حق لرئ. ځکه ډېری معلومات محلي دي، مسؤول یې عموماً له لرې نه شي لیدلی یا راګرځولی.',
          ],
        ),
        LegalSection(
          title: '۹. اړیکه او بدلونونه',
          paragraphs: <String>[
            'د پوښتنو یا حق غوښتنې لپاره {email}. د حساب، کلاوډ، شننې، اعلان، نوي ترلاسه کوونکي یا بېلو اجازو تر زیاتولو مخکې تګلاره باید نوې شي. پورته نېټه دا نسخه ښيي.',
          ],
        ),
      ],
    ),
    'ur': LegalDocument(
      title: 'رازداری کی پالیسی',
      lastUpdated: '۱۶ ستمبر ۲۰۲۶',
      introduction: 'یہ پالیسی SalahFocus کے موجودہ ورژن میں ڈیٹا پراسیسنگ بیان کرتی ہے۔ مستقبل کے اکاؤنٹس، کلاؤڈ سنک، تجزیات یا اشتہارات جو اس ورژن میں نہیں ہیں، اس میں شامل نہیں۔',
      sections: <LegalSection>[
        LegalSection(
          title: '۱. ذمہ دار اور دائرہ',
          paragraphs: <String>[
            'SalahFocus کے ذمہ دار {controller}، {location} ہیں۔ رابطہ: {email}۔ LinkedIn: {linkedin}۔ صارف اکاؤنٹ یا ڈویلپر کا اکاؤنٹ/سنک سرور موجود نہیں۔',
          ],
        ),
        LegalSection(
          title: '۲. مقام اور جیوکوڈنگ',
          paragraphs: <String>[
            'خودکار مقام منتخب کرنے پر ایپ استعمال کے دوران درست مقام مانگتی اور عرض، طول، شہر، ملک، ٹائم زون اور انتخاب کا طریقہ محفوظ کرتی ہے۔ ایپ چلتے وقت تقریباً ۱ کلومیٹر فلٹر کے ساتھ تبدیلیاں سنتی ہے۔',
            'موجودہ ورژن Android پس منظر مقام، iOS “Always” اجازت یا iOS پس منظر مقام موڈ نہیں مانگتا۔ شہر اور ملک دستی دیا جا سکتا ہے۔ سسٹم جیوکوڈنگ مقام/مختصات، زبان، IP اور عام درخواست معلومات پلیٹ فارم فراہم کنندہ کو بھیج سکتی ہے۔',
          ],
        ),
        LegalSection(
          title: '۳. نماز کے اوقات اور قبلہ',
          paragraphs: <String>[
            'ماہانہ کیلنڈر کے لیے مختصات، مہینہ، سال، حساب طریقہ، عصر فقہ اور بلند عرض کا اصول HTTPS سے api.aladhan.com کے AlAdhan API کو جاتا ہے۔ سروس اور نیٹ ورک IP اور عام کنکشن ڈیٹا لے سکتے ہیں۔ شہر کا نام اور نماز کی تاریخ نہیں بھیجی جاتی۔',
            'قبلہ ڈیوائس پر حساب ہوتا ہے۔ کمپاس سمت صرف دکھانے کے لیے پڑھی جاتی ہے اور SalahFocus اسے محفوظ یا منتقل نہیں کرتا۔',
          ],
        ),
        LegalSection(
          title: '۴. ڈیوائس پر محفوظ ڈیٹا',
          paragraphs: <String>[
            'SharedPreferences مقام، ترتیبات، زبان، تھیم، آن بورڈنگ، پہلی کامیاب شروعات اور ریویو درخواست کی حالت رکھتا ہے۔ SQLite اوقات کی کیش، ٹائم زون/ہجری، حالت، تصدیق/ترمیم/سنوز وقت، ایڈجسٹمنٹ، روزہ، تراویح، قیام، رمضان اہداف اور تکمیل رکھتا ہے۔',
            'یہ ریکارڈ مذہبی عمل ظاہر کر سکتے اور حساس ہیں۔ موجودہ کوڈ انہیں مقامی رکھتا اور ڈویلپر یا API کو اپلوڈ نہیں کرتا۔ رابطے، تصاویر، مائیک، صحت، اشتہاری یا دیگر ڈیوائس ID استعمال نہیں ہوتے۔',
          ],
        ),
        LegalSection(
          title: '۵. اطلاعات اور ڈیوائس خصوصیات',
          paragraphs: <String>[
            'اجازت کے ساتھ نماز، جمعہ، سنوز اور رمضان اطلاعات ڈیوائس پر شیڈول ہوتی ہیں۔ سسٹم متن، تاریخ، ID اور عمل سنبھالتا؛ ریموٹ push token یا سرور نہیں۔ Android درست الارم، وائبریشن، بوٹ کے بعد شیڈول اور اختیاری پوری اسکرین؛ iOS Time Sensitive اطلاع استعمال کر سکتا ہے۔',
            'موجودہ iOS ہدف میں FamilyControls، ManagedSettings، DeviceActivity، App Group یا Family Controls entitlement نہیں؛ Screen Time ڈیٹا نہیں پڑھا جاتا۔',
          ],
        ),
        LegalSection(
          title: '۶. تیسرے فریق اور منتقلی',
          paragraphs: <String>[
            'بیرونی پراسیسنگ AlAdhan، سسٹم جیوکوڈنگ اور اختیاری App Store/Google Play ریویو تک محدود ہے۔ فراہم کنندے اپنی شرائط کے تحت تکنیکی لاگ رکھ سکتے ہیں۔ تجزیات، کریش، اشتہار، ٹریکنگ یا سوشل لاگ اِن SDK نہیں۔',
            'نماز/رمضان تاریخ، اہداف اور اطلاع عمل ڈویلپر کو نہیں جاتے۔ کوڈ کی درخواستیں HTTPS ہیں، مگر فراہم کنندے کے لاگ کی مدت SalahFocus کے قابو میں نہیں۔',
          ],
        ),
        LegalSection(
          title: '۷. برقرار رکھنا اور حذف',
          paragraphs: <String>[
            'مقامی ترتیبات تبدیلی، ڈیٹا مٹانے یا ایپ ہٹانے تک رہتی ہیں۔ تاریخ کے لیے خودکار حذف مدت نہیں۔ کیش بدل سکتی اور شیڈول بدلنے پر اطلاعات ختم یا منسوخ ہوتی ہیں۔',
            'سسٹم ترتیبات میں اجازت واپس لی جا سکتی ہے۔ اسٹوریج مٹانے یا ایپ ہٹانے سے ڈیٹابیس اور ترجیحات مٹتی ہیں۔ بیرونی فراہم کنندے کا ڈیٹا اس کے طریقے کے تابع ہے۔',
          ],
        ),
        LegalSection(
          title: '۸. قانونی بنیاد اور حقوق',
          paragraphs: <String>[
            'صورتحال کے مطابق مطلوبہ سہولت GDPR 6(1)(b) اور اجازت والی پراسیسنگ رضامندی 6(1)(a) پر ہے۔ اجازت مستقبل کے لیے واپس لی جا سکتی ہے۔',
            'قانونی شرائط کے تحت رسائی، درستگی، حذف، پابندی، منتقلی، اعتراض اور نگران ادارے سے شکایت کا حق ہے۔ زیادہ ڈیٹا مقامی ہے، اس لیے ذمہ دار عام طور پر دور سے دیکھ یا بحال نہیں کر سکتا۔',
          ],
        ),
        LegalSection(
          title: '۹. رابطہ اور تبدیلیاں',
          paragraphs: <String>[
            'سوال یا حقوق درخواست کے لیے {email}۔ اکاؤنٹ، کلاؤڈ، تجزیات، اشتہار، نیا وصول کنندہ یا مختلف اجازت شامل کرنے سے پہلے پالیسی اپ ڈیٹ کرنا ضروری ہے۔ اوپر کی تاریخ اس ورژن کی ہے۔',
          ],
        ),
      ],
    ),
  };

  static const Map<String, LegalDocument> _legalNotices = {
    'en': LegalDocument(
      title: 'Legal Notice / Impressum',
      lastUpdated: '16 September 2026',
      introduction: 'Provider information prepared for SalahFocus. Only information supplied by the developer is stated.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Provider',
          paragraphs: <String>[
            '{controller}\n{location}\nEmail: {email}\nLinkedIn: {linkedin}',
            'A complete street/service address has not been supplied. Before a public release, add it here if a service address is legally required under German law.',
          ],
        ),
        LegalSection(
          title: 'Responsible for content',
          paragraphs: <String>[
            'Responsible for the app content, including under section 18(2) MStV where applicable: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Open-source software',
          paragraphs: <String>[
            'SalahFocus includes open-source software. The applicable notices and license texts are available from Privacy & Legal → Open-Source Licenses inside the app. Rights in third-party names and content remain with their respective owners.',
          ],
        ),
        LegalSection(
          title: 'No invented registration details',
          paragraphs: <String>[
            'No company register number, VAT identification number, telephone number, or consumer-dispute statement is listed because none was provided. Review whether additional German mandatory information applies before publication.',
          ],
        ),
      ],
    ),
    'de': LegalDocument(
      title: 'Impressum / Rechtliche Hinweise',
      lastUpdated: '16. September 2026',
      introduction: 'Anbieterangaben für SalahFocus. Es werden ausschließlich die vom Entwickler mitgeteilten Angaben verwendet.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Anbieter',
          paragraphs: <String>[
            '{controller}\n{location}\nE-Mail: {email}\nLinkedIn: {linkedin}',
            'Eine vollständige Straßen- beziehungsweise ladungsfähige Anschrift wurde noch nicht mitgeteilt. Vor der Veröffentlichung ist sie hier zu ergänzen, soweit sie nach deutschem Recht erforderlich ist.',
          ],
        ),
        LegalSection(
          title: 'Inhaltlich verantwortlich',
          paragraphs: <String>[
            'Verantwortlich für die App-Inhalte, soweit anwendbar auch gemäß § 18 Abs. 2 MStV: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Open-Source-Software',
          paragraphs: <String>[
            'SalahFocus enthält Open-Source-Software. Hinweise und Lizenztexte sind in der App unter Datenschutz & Rechtliches → Open-Source-Lizenzen abrufbar. Rechte an Namen und Inhalten Dritter verbleiben bei den jeweiligen Inhabern.',
          ],
        ),
        LegalSection(
          title: 'Keine erfundenen Pflichtangaben',
          paragraphs: <String>[
            'Handelsregister-, Umsatzsteuer-, Telefon- oder Verbraucherstreitbeilegungsangaben werden nicht genannt, weil sie nicht mitgeteilt wurden. Vor der Veröffentlichung ist zu prüfen, ob weitere deutsche Pflichtangaben gelten.',
          ],
        ),
      ],
    ),
    'ar': LegalDocument(
      title: 'الإشعار القانوني / بيانات الناشر',
      lastUpdated: '16 سبتمبر 2026',
      introduction: 'بيانات مقدم SalahFocus كما زودنا بها المطور فقط.',
      sections: <LegalSection>[
        LegalSection(
          title: 'مقدم التطبيق',
          paragraphs: <String>[
            '{controller}\n{location}\nالبريد الإلكتروني: {email}\nلينكدإن: {linkedin}',
            'لم يُقدَّم عنوان شارع كامل صالح للتبليغ. يجب إضافته قبل النشر إذا كان القانون الألماني يوجبه.',
          ],
        ),
        LegalSection(
          title: 'المسؤول عن المحتوى',
          paragraphs: <String>[
            'المسؤول عن محتوى التطبيق، وكذلك وفق § 18(2) MStV عند انطباقه: {controller}، {location}.',
          ],
        ),
        LegalSection(
          title: 'البرمجيات مفتوحة المصدر',
          paragraphs: <String>[
            'يتضمن SalahFocus برمجيات مفتوحة المصدر. الإشعارات ونصوص التراخيص متاحة داخل التطبيق تحت الخصوصية والشؤون القانونية ← تراخيص المصادر المفتوحة. حقوق الأطراف الأخرى محفوظة لأصحابها.',
          ],
        ),
        LegalSection(
          title: 'لا توجد بيانات قانونية مخترعة',
          paragraphs: <String>[
            'لم تُذكر أرقام سجل تجاري أو ضريبة قيمة مضافة أو هاتف أو بيان تسوية نزاعات لأنها لم تُقدَّم. يجب مراجعة المتطلبات الألمانية الإضافية قبل النشر.',
          ],
        ),
      ],
    ),
    'fr': LegalDocument(
      title: 'Mentions légales / Impressum',
      lastUpdated: '16 septembre 2026',
      introduction: 'Informations du fournisseur de SalahFocus, limitées à celles communiquées par le développeur.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Éditeur',
          paragraphs: <String>[
            '{controller}\n{location}\nE-mail : {email}\nLinkedIn : {linkedin}',
            'Aucune adresse de rue complète permettant une signification n’a été fournie. Elle doit être ajoutée avant publication si le droit allemand l’exige.',
          ],
        ),
        LegalSection(
          title: 'Responsable du contenu',
          paragraphs: <String>[
            'Responsable du contenu de l’app, y compris au titre du § 18(2) MStV le cas échéant : {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Logiciels libres',
          paragraphs: <String>[
            'SalahFocus inclut des logiciels libres. Les avis et licences figurent dans Confidentialité et mentions légales → Licences libres. Les droits des tiers restent à leurs titulaires.',
          ],
        ),
        LegalSection(
          title: 'Aucune donnée inventée',
          paragraphs: <String>[
            'Aucun numéro de registre, TVA, téléphone ou déclaration de règlement des litiges n’est indiqué faute d’information fournie. Vérifiez les mentions allemandes supplémentaires avant publication.',
          ],
        ),
      ],
    ),
    'es': LegalDocument(
      title: 'Aviso legal / Impressum',
      lastUpdated: '16 de septiembre de 2026',
      introduction: 'Datos del proveedor de SalahFocus, limitados a la información facilitada.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Proveedor',
          paragraphs: <String>[
            '{controller}\n{location}\nCorreo: {email}\nLinkedIn: {linkedin}',
            'No se ha facilitado una dirección postal completa para notificaciones. Añádela antes de publicar si la exige la legislación alemana.',
          ],
        ),
        LegalSection(
          title: 'Responsable del contenido',
          paragraphs: <String>[
            'Responsable del contenido, incluido § 18(2) MStV cuando proceda: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Software de código abierto',
          paragraphs: <String>[
            'SalahFocus incluye software abierto. Los avisos y licencias están en Privacidad y aspectos legales → Licencias de código abierto. Los derechos de terceros pertenecen a sus titulares.',
          ],
        ),
        LegalSection(
          title: 'Sin datos inventados',
          paragraphs: <String>[
            'No se indican registros, IVA, teléfono o declaración de litigios porque no se proporcionaron. Revisa otros requisitos alemanes antes de publicar.',
          ],
        ),
      ],
    ),
    'tr': LegalDocument(
      title: 'Yasal Bildirim / Künye',
      lastUpdated: '16 Eylül 2026',
      introduction: 'SalahFocus sağlayıcı bilgileri yalnızca geliştiricinin verdiği bilgilerle hazırlanmıştır.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Sağlayıcı',
          paragraphs: <String>[
            '{controller}\n{location}\nE-posta: {email}\nLinkedIn: {linkedin}',
            'Tam ve tebligata elverişli sokak adresi verilmemiştir. Alman hukuku gerektiriyorsa yayımdan önce ekleyin.',
          ],
        ),
        LegalSection(
          title: 'İçerikten sorumlu',
          paragraphs: <String>[
            'Uygulama içeriğinden, uygulanırsa § 18(2) MStV uyarınca sorumlu: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Açık kaynak',
          paragraphs: <String>[
            'SalahFocus açık kaynak yazılım içerir. Bildirim ve lisanslar Gizlilik ve Yasal Bilgiler → Açık Kaynak Lisansları bölümündedir. Üçüncü taraf hakları sahiplerine aittir.',
          ],
        ),
        LegalSection(
          title: 'Uydurulmuş kayıt bilgisi yok',
          paragraphs: <String>[
            'Şirket sicili, KDV, telefon veya tüketici uyuşmazlığı beyanı verilmediği için listelenmemiştir. Yayımdan önce ek Alman zorunluluklarını inceleyin.',
          ],
        ),
      ],
    ),
    'id': LegalDocument(
      title: 'Pemberitahuan Hukum / Impressum',
      lastUpdated: '16 September 2026',
      introduction: 'Informasi penyedia SalahFocus hanya menggunakan data yang diberikan pengembang.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Penyedia',
          paragraphs: <String>[
            '{controller}\n{location}\nEmail: {email}\nLinkedIn: {linkedin}',
            'Alamat jalan lengkap untuk layanan hukum belum diberikan. Tambahkan sebelum rilis jika diwajibkan hukum Jerman.',
          ],
        ),
        LegalSection(
          title: 'Penanggung jawab konten',
          paragraphs: <String>[
            'Penanggung jawab konten aplikasi, termasuk § 18(2) MStV bila berlaku: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Perangkat lunak sumber terbuka',
          paragraphs: <String>[
            'SalahFocus memakai perangkat lunak sumber terbuka. Pemberitahuan dan lisensi tersedia di Privasi & Hukum → Lisensi Sumber Terbuka. Hak pihak ketiga tetap milik pemiliknya.',
          ],
        ),
        LegalSection(
          title: 'Tidak ada data registrasi rekaan',
          paragraphs: <String>[
            'Nomor registrasi, PPN, telepon, atau pernyataan sengketa tidak dicantumkan karena tidak diberikan. Tinjau kewajiban Jerman lainnya sebelum publikasi.',
          ],
        ),
      ],
    ),
    'ms': LegalDocument(
      title: 'Notis Undang-undang / Impressum',
      lastUpdated: '16 September 2026',
      introduction: 'Maklumat penyedia SalahFocus menggunakan hanya maklumat yang diberikan pembangun.',
      sections: <LegalSection>[
        LegalSection(
          title: 'Penyedia',
          paragraphs: <String>[
            '{controller}\n{location}\nE-mel: {email}\nLinkedIn: {linkedin}',
            'Alamat jalan lengkap untuk penyampaian undang-undang belum diberikan. Tambah sebelum penerbitan jika diwajibkan undang-undang Jerman.',
          ],
        ),
        LegalSection(
          title: 'Bertanggungjawab atas kandungan',
          paragraphs: <String>[
            'Bertanggungjawab atas kandungan aplikasi, termasuk § 18(2) MStV jika terpakai: {controller}, {location}.',
          ],
        ),
        LegalSection(
          title: 'Perisian sumber terbuka',
          paragraphs: <String>[
            'SalahFocus mengandungi perisian sumber terbuka. Notis dan lesen tersedia di Privasi & Perundangan → Lesen Sumber Terbuka. Hak pihak ketiga kekal milik pemiliknya.',
          ],
        ),
        LegalSection(
          title: 'Tiada butiran rekaan',
          paragraphs: <String>[
            'Nombor daftar, VAT, telefon atau kenyataan pertikaian tidak disenaraikan kerana tidak diberikan. Semak kewajipan Jerman lain sebelum penerbitan.',
          ],
        ),
      ],
    ),
    'bn': LegalDocument(
      title: 'আইনি বিজ্ঞপ্তি / ইমপ্রেসুম',
      lastUpdated: '১৬ সেপ্টেম্বর ২০২৬',
      introduction:
          'SalahFocus প্রদানকারীর তথ্য শুধু ডেভেলপার-প্রদত্ত তথ্য দিয়ে তৈরি।',
      sections: <LegalSection>[
        LegalSection(
          title: 'প্রদানকারী',
          paragraphs: <String>[
            '{controller}\n{location}\nইমেইল: {email}\nLinkedIn: {linkedin}',
            'আইনি নোটিশের জন্য পূর্ণ রাস্তার ঠিকানা দেওয়া হয়নি। জার্মান আইন চাইলে প্রকাশের আগে যোগ করুন।',
          ],
        ),
        LegalSection(
          title: 'বিষয়বস্তুর দায়িত্ব',
          paragraphs: <String>[
            'প্রযোজ্য হলে § 18(2) MStV-সহ অ্যাপ বিষয়বস্তুর দায়িত্বে: {controller}, {location}।',
          ],
        ),
        LegalSection(
          title: 'ওপেন-সোর্স সফটওয়্যার',
          paragraphs: <String>[
            'SalahFocus ওপেন-সোর্স সফটওয়্যার ব্যবহার করে। বিজ্ঞপ্তি ও লাইসেন্স গোপনীয়তা ও আইনি তথ্য → ওপেন-সোর্স লাইসেন্সে আছে। তৃতীয় পক্ষের অধিকার তাদের মালিকের।',
          ],
        ),
        LegalSection(
          title: 'কাল্পনিক নিবন্ধন তথ্য নেই',
          paragraphs: <String>[
            'রেজিস্টার, VAT, ফোন বা বিরোধ নিষ্পত্তির তথ্য দেওয়া হয়নি বলে তালিকাভুক্ত নয়। প্রকাশের আগে জার্মান বাধ্যবাধকতা পর্যালোচনা করুন।',
          ],
        ),
      ],
    ),
    'fa': LegalDocument(
      title: 'اطلاعیهٔ حقوقی / Impressum',
      lastUpdated: '۱۶ سپتامبر ۲۰۲۶',
      introduction: 'اطلاعات ارائه‌دهندهٔ SalahFocus فقط بر اساس داده‌های ارائه‌شده تنظیم شده است.',
      sections: <LegalSection>[
        LegalSection(
          title: 'ارائه‌دهنده',
          paragraphs: <String>[
            '{controller}\n{location}\nایمیل: {email}\nلینکدین: {linkedin}',
            'نشانی کامل خیابان برای ابلاغ ارائه نشده است. اگر قانون آلمان لازم می‌داند پیش از انتشار اضافه شود.',
          ],
        ),
        LegalSection(
          title: 'مسئول محتوا',
          paragraphs: <String>[
            'مسئول محتوای برنامه، از جمله § 18(2) MStV در صورت کاربرد: {controller}، {location}.',
          ],
        ),
        LegalSection(
          title: 'نرم‌افزار متن‌باز',
          paragraphs: <String>[
            'SalahFocus نرم‌افزار متن‌باز دارد. اطلاعیه‌ها و مجوزها در حریم خصوصی و اطلاعات حقوقی ← مجوزهای متن‌باز موجود است. حقوق اشخاص ثالث برای مالکان آن‌ها محفوظ است.',
          ],
        ),
        LegalSection(
          title: 'بدون اطلاعات ثبتی ساختگی',
          paragraphs: <String>[
            'شمارهٔ ثبت، VAT، تلفن یا بیانیهٔ حل اختلاف چون ارائه نشده درج نشده است. الزامات دیگر آلمان پیش از انتشار بررسی شود.',
          ],
        ),
      ],
    ),
    'pa': LegalDocument(
      title: 'قانونی نوٹس / امپریسم',
      lastUpdated: '۱۶ ستمبر ۲۰۲۶',
      introduction:
          'SalahFocus فراہم کنندے دی معلومات صرف ڈویلپر دے دِتے ڈیٹا تے اے۔',
      sections: <LegalSection>[
        LegalSection(
          title: 'فراہم کنندہ',
          paragraphs: <String>[
            '{controller}\n{location}\nای میل: {email}\nLinkedIn: {linkedin}',
            'قانونی نوٹس لئی پوری گلی دی پتی نئیں دِتی گئی۔ جرمن قانون منگے تے اشاعت توں پہلاں شامل کرو۔',
          ],
        ),
        LegalSection(
          title: 'مواد دا ذمہ وار',
          paragraphs: <String>[
            'ایپ مواد لئی، جے لاگو ہووے § 18(2) MStV دے تحت ذمہ وار: {controller}، {location}۔',
          ],
        ),
        LegalSection(
          title: 'اوپن سورس سافٹ ویئر',
          paragraphs: <String>[
            'SalahFocus اوپن سورس سافٹ ویئر رکھدا اے۔ نوٹس تے لائسنس رازداری تے قانونی معلومات ← اوپن سورس لائسنس وچ نیں۔ تیجی دھراں دے حق انہاں دے مالکاں کول نیں۔',
          ],
        ),
        LegalSection(
          title: 'کوئی بنائی رجسٹریشن معلومات نئیں',
          paragraphs: <String>[
            'رجسٹر، VAT، فون یا تنازع بیان نئیں دِتا گیا ایس لئی درج نئیں۔ اشاعت توں پہلاں ہور جرمن شرطاں ویکھو۔',
          ],
        ),
      ],
    ),
    'ps': LegalDocument(
      title: 'حقوقي خبرتیا / امپریسوم',
      lastUpdated: '۱۶ سپتمبر ۲۰۲۶',
      introduction: 'د SalahFocus د برابرونکي معلومات یوازې د جوړوونکي له ورکړل شوو معلوماتو جوړ دي.',
      sections: <LegalSection>[
        LegalSection(
          title: 'برابرونکی',
          paragraphs: <String>[
            '{controller}\n{location}\nبرېښنالیک: {email}\nLinkedIn: {linkedin}',
            'د قانوني ابلاغ لپاره بشپړه کوڅه پته نه ده ورکړل شوې. که د جرمني قانون یې غواړي له خپرېدو مخکې یې زیاته کړئ.',
          ],
        ),
        LegalSection(
          title: 'د منځپانګې مسؤول',
          paragraphs: <String>[
            'د اپ د منځپانګې مسؤول، که § 18(2) MStV پلي کېږي: {controller}، {location}.',
          ],
        ),
        LegalSection(
          title: 'پرانیستې سرچینې سافټویر',
          paragraphs: <String>[
            'SalahFocus د پرانیستې سرچینې سافټویر لري. خبرتیاوې او جوازونه محرمیت او حقوقي معلومات ← جوازونو کې دي. د درېیمو حقونه د هغوی له مالکانو سره دي.',
          ],
        ),
        LegalSection(
          title: 'جوړ شوي ثبت معلومات نشته',
          paragraphs: <String>[
            'د شرکت ثبت، VAT، تلیفون یا شخړې بیان ځکه نه دی لیکل شوی چې نه دی ورکړل شوی. له خپرېدو مخکې نور جرمني مکلفیتونه وګورئ.',
          ],
        ),
      ],
    ),
    'ur': LegalDocument(
      title: 'قانونی نوٹس / امپریسم',
      lastUpdated: '۱۶ ستمبر ۲۰۲۶',
      introduction: 'SalahFocus فراہم کنندہ معلومات صرف ڈویلپر کی فراہم کردہ معلومات پر مبنی ہیں۔',
      sections: <LegalSection>[
        LegalSection(
          title: 'فراہم کنندہ',
          paragraphs: <String>[
            '{controller}\n{location}\nای میل: {email}\nLinkedIn: {linkedin}',
            'قانونی نوٹس کے لیے مکمل گلی کا پتہ فراہم نہیں کیا گیا۔ جرمن قانون مانگے تو اشاعت سے پہلے شامل کریں۔',
          ],
        ),
        LegalSection(
          title: 'مواد کا ذمہ دار',
          paragraphs: <String>[
            'ایپ مواد کے لیے، اگر لاگو ہو § 18(2) MStV کے تحت ذمہ دار: {controller}، {location}۔',
          ],
        ),
        LegalSection(
          title: 'اوپن سورس سافٹ ویئر',
          paragraphs: <String>[
            'SalahFocus اوپن سورس سافٹ ویئر رکھتا ہے۔ نوٹس اور لائسنس رازداری اور قانونی معلومات ← اوپن سورس لائسنس میں ہیں۔ تیسرے فریق کے حقوق ان کے مالکوں کے ہیں۔',
          ],
        ),
        LegalSection(
          title: 'کوئی فرضی رجسٹریشن معلومات نہیں',
          paragraphs: <String>[
            'رجسٹر، VAT، فون یا تنازع بیان فراہم نہ ہونے کی وجہ سے درج نہیں۔ اشاعت سے پہلے دیگر جرمن تقاضے دیکھیں۔',
          ],
        ),
      ],
    ),
  };
}
