import '../../theme/colors.dart';
import '../models/mock_models.dart';

class MockData {
  const MockData._();

  static const defaultStudent = StudentProfile(
    name: 'Zeynep Kaya',
    number: '220401092',
    department: 'Yazilim Muhendisligi',
    grade: '3. Sınıf',
    gpa: '3.42 / 4.00',
    bio:
        'Mobil urunler, kampus topluluklari ve deneyim tasarimi ile ilgileniyorum. Bu donem proje ve study group odakli bir rutinim var.',
    role: 'Öğrenci',
    courseCount: 4,
    notificationsEnabled: true,
  );

  static StudentProfile student = defaultStudent;

  static void setStudent(StudentProfile profile) {
    student = profile;
  }

  static void resetStudent() {
    student = defaultStudent;
  }

  static const courses = [
    'Mobil Programlama',
    'Veri Yapilari',
    'UI Design Studio',
    'Ag Teknolojileri',
  ];

  static const schedules = [
    ScheduleItem(
      course: 'Mobil Programlama',
      time: '10:00 - 11:45',
      location: 'Lab-2',
      instructor: 'Dr. Can Aydin',
      color: AppColors.teal,
      badge: 'Proje haftasi',
      credit: '3',
      ects: '6',
      examSummary: 'Vize 78, Final 86, But -',
      letter: 'BA',
    ),
    ScheduleItem(
      course: 'UI Design Studio',
      time: '13:00 - 14:45',
      location: 'Atolye-5',
      instructor: 'Ogr. Gor. Ipek Yalcin',
      color: AppColors.sunrise,
      badge: 'Studio critique',
      credit: '4',
      ects: '5',
      examSummary: 'Vize 84, Final 91, But -',
      letter: 'AA',
    ),
    ScheduleItem(
      course: 'Veri Yapilari',
      time: '09:00 - 10:30',
      location: 'D-204',
      instructor: 'Doc. Dr. Mert Koc',
      color: AppColors.coral,
      badge: 'Lab teslimi',
      credit: '4',
      ects: '6',
      examSummary: 'Vize 81, Final 76, But -',
      letter: 'BB',
    ),
  ];

  static final assignments = [
    AssignmentItem(
      title: 'UI Design Project',
      course: 'UI Design Studio',
      description:
          'Final mobil ekran setini, component aciklamalari ve mini case dokümani ile teslim et.',
      deadline: '28 Nisan, 23:59',
      timeLeft: '2 gun',
      status: 'Aktif',
      documentInfo: 'Final_mockups_v3.fig baglandi',
      submissionNote: null,
      isCompleted: false,
      isOverdue: false,
    ),
    AssignmentItem(
      title: 'API katmani mini raporu',
      course: 'Mobil Programlama',
      description:
          'Authentication, state akışı ve hata yonetimini 2 sayfalik ozetle acikla.',
      deadline: '30 Nisan, 18:00',
      timeLeft: '4 gun',
      status: 'Aktif',
      documentInfo: null,
      submissionNote: null,
      isCompleted: false,
      isOverdue: false,
    ),
    AssignmentItem(
      title: 'Hash tablo performans analizi',
      course: 'Veri Yapilari',
      description:
          'Cakisma senaryolari icin performans tablolarini ve yorumunu ekle.',
      deadline: '22 Nisan, 09:00',
      timeLeft: 'Gecikti',
      status: 'Tamamlandi',
      documentInfo: null,
      submissionNote: null,
      isCompleted: false,
      isOverdue: true,
    ),
    AssignmentItem(
      title: 'Routing demo teslimi',
      course: 'Mobil Programlama',
      description: 'Bottom nav ve detail akışıni iceren mini demo uygulama.',
      deadline: '18 Nisan, 17:00',
      timeLeft: 'Teslim edildi',
      status: 'Tamamlandi',
      documentInfo: 'routing_demo.zip yüklendi',
      submissionNote: 'Bottom nav ve detail akislarini tamamladim.',
      isCompleted: true,
      isOverdue: false,
    ),
  ];

  static const announcements = [
    AnnouncementItem(
      title: 'Bahar Senligi kayıtlari açıldı',
      description:
          'Kulup stantlari, muzik etkinlikleri ve gonullu ekip basvurulari kampus portalinda yayinda.',
      scope: ScopeType.universite,
      date: '2s once',
      isNew: true,
    ),
    AnnouncementItem(
      title: 'Fakülte laboratuvar saatleri güncellendi',
      description:
          'Hafta ici laboratuvar acilis-kapanis saatleri yeni donem yogunluguna gore yenilendi.',
      scope: ScopeType.fakulte,
      date: 'Bugun',
      isNew: true,
    ),
    AnnouncementItem(
      title: 'Mobil Programlama proje sunum takvimi',
      description:
          'Sunum slotlari ve ekip dagilimi ders duyuru panelinde yayinlandi.',
      scope: ScopeType.ders,
      date: 'Dun',
      isNew: false,
    ),
    AnnouncementItem(
      title: 'Bölüm semineri',
      description:
          'Yapay zeka urun ekiplerinden konusmacilarla seminer cuma gunu konferans salonunda.',
      scope: ScopeType.bolum,
      date: '3 gun once',
      isNew: false,
    ),
  ];

  static const calendarEvents = [
    CalendarEvent(
      title: 'Ders kayıt yenileme haftasi',
      range: '01 Mayis - 05 Mayis',
      color: AppColors.teal,
    ),
    CalendarEvent(
      title: 'Ara sinavlar',
      range: '12 Mayis - 19 Mayis',
      color: AppColors.sunrise,
    ),
    CalendarEvent(
      title: 'Proje sunumlari',
      range: '25 Mayis - 30 Mayis',
      color: AppColors.coral,
    ),
  ];

  static final groups = [
    GroupItem(
      name: 'Mobile Dev Study Group',
      memberCount: '4 uye',
      muted: false,
      color: AppColors.teal,
      avatarIndex: 0,
      isDirect: false,
    ),
    GroupItem(
      name: 'Yazilim 3. Sınıf',
      memberCount: '3 uye',
      muted: true,
      color: AppColors.sunrise,
      avatarIndex: 1,
      isDirect: false,
      mutedUntil: '3 gun',
    ),
    GroupItem(
      name: 'Campus Runners',
      memberCount: '2 uye',
      muted: false,
      color: AppColors.coral,
      avatarIndex: 2,
      isDirect: false,
    ),
  ];

  static final unreadConversationCounts = <String, int>{
    'Mobile Dev Study Group': 2,
    'Yazilim 3. Sınıf': 1,
    'Campus Runners': 0,
  };

  static final chatMessages = [
    ChatMessage(
      sender: 'Ece',
      message: 'Sunum akışıni tamamladim, son ekranlara bir bakabilir misiniz?',
      time: '09:18',
      isMe: false,
      attachment: 'wireframes.pdf',
    ),
    ChatMessage(
      sender: 'Zeynep',
      message: 'Bakiyorum, tasarim dilini tum tablarda ayni tutmak istiyorum.',
      time: '09:21',
      isMe: true,
      replyTo: 'Sunum akışıni tamamladim, son ekranlara bir bakabilir misiniz?',
    ),
    ChatMessage(
      sender: 'Mert',
      message: 'Akşam test grubunda son buildi deneyelim.',
      time: '09:24',
      isMe: false,
    ),
  ];

  static final conversationMessages = <String, List<ChatMessage>>{
    'Mobile Dev Study Group': List<ChatMessage>.from(chatMessages),
    'Yazilim 3. Sınıf': [
      const ChatMessage(
        sender: 'Deniz',
        message: 'Yarin algoritma quizinden sonra sınıf toplantisi var.',
        time: '11:05',
        isMe: false,
      ),
      const ChatMessage(
        sender: 'Zeynep',
        message: 'Notlari ben de yanima aliyorum.',
        time: '11:09',
        isMe: true,
      ),
    ],
    'Campus Runners': [
      const ChatMessage(
        sender: 'Selin',
        message: 'Akşam 19:00 pistte buluşalım mi?',
        time: '17:42',
        isMe: false,
      ),
      const ChatMessage(
        sender: 'Zeynep',
        message: 'Tamam, yarim saat once oradayim.',
        time: '17:48',
        isMe: true,
      ),
    ],
  };

  static final groupMembers = <String, List<StudentOption>>{
    'Mobile Dev Study Group': students,
    'Yazilim 3. Sınıf': [students[0], students[2], students[3]],
    'Campus Runners': [students[0], students[3]],
  };

  static const students = [
    StudentOption(
      name: 'Deniz Karaca',
      number: '220401044',
      role: 'Sınıf Temsilcisi',
    ),
    StudentOption(name: 'Ece Tunc', number: '220401051', role: 'Tasarim Ekibi'),
    StudentOption(
      name: 'Mert Polat',
      number: '220401066',
      role: 'Mobil Gelistirici',
    ),
    StudentOption(name: 'Selin Aras', number: '220401073', role: 'Kulup Üyesi'),
  ];

  static const menuItems = [
    'Izgara kofte',
    'Sebzeli bulgur pilavi',
    'Mercimek corbasi',
    'Mevsim salata',
    'Ayran',
  ];
}
