import 'dart:convert';
import 'dart:io';

import '../models/mock_models.dart';
import 'app_repository.dart';
import 'mock_app_repository.dart';

class ApiAppRepository implements AppRepository {
  ApiAppRepository({
    required this.baseUrl,
    AppRepository? fallback,
    HttpClient? httpClient,
  }) : _fallback = fallback ?? const MockAppRepository(),
       _httpClient = httpClient ?? HttpClient(),
       _student = (fallback ?? const MockAppRepository()).student,
       _courses = List<String>.from(
         (fallback ?? const MockAppRepository()).courses,
       ),
       _schedules = List<ScheduleItem>.from(
         (fallback ?? const MockAppRepository()).schedules,
       ),
       _assignments = List<AssignmentItem>.from(
         (fallback ?? const MockAppRepository()).assignments,
       ),
       _announcements = List<AnnouncementItem>.from(
         (fallback ?? const MockAppRepository()).announcements,
       ),
       _calendarEvents = List<CalendarEvent>.from(
         (fallback ?? const MockAppRepository()).calendarEvents,
       ),
       _groups = List<GroupItem>.from(
         (fallback ?? const MockAppRepository()).groups,
       ),
       _unreadConversationCounts = Map<String, int>.from(
         (fallback ?? const MockAppRepository()).unreadConversationCounts,
       ),
       _chatMessages = List<ChatMessage>.from(
         (fallback ?? const MockAppRepository()).chatMessages,
       ),
       _conversationMessages = Map<String, List<ChatMessage>>.from(
         (fallback ?? const MockAppRepository()).conversationMessages,
       ),
       _groupMembers = Map<String, List<StudentOption>>.from(
         (fallback ?? const MockAppRepository()).groupMembers,
       ),
       _students = List<StudentOption>.from(
         (fallback ?? const MockAppRepository()).students,
       ),
       _menuItems = List<String>.from(
         (fallback ?? const MockAppRepository()).menuItems,
       );

  final String baseUrl;
  final AppRepository _fallback;
  final HttpClient _httpClient;

  StudentProfile _student;
  final List<String> _courses;
  final List<ScheduleItem> _schedules;
  final List<AssignmentItem> _assignments;
  final List<AnnouncementItem> _announcements;
  final List<CalendarEvent> _calendarEvents;
  final List<GroupItem> _groups;
  final Map<String, int> _unreadConversationCounts;
  final List<ChatMessage> _chatMessages;
  final Map<String, List<ChatMessage>> _conversationMessages;
  final Map<String, List<StudentOption>> _groupMembers;
  final List<StudentOption> _students;
  final List<String> _menuItems;

  @override
  StudentProfile get student => _student;

  @override
  List<String> get courses => _courses;

  @override
  List<ScheduleItem> get schedules => _schedules;

  @override
  List<AssignmentItem> get assignments => _assignments;

  @override
  List<AnnouncementItem> get announcements => _announcements;

  @override
  List<CalendarEvent> get calendarEvents => _calendarEvents;

  @override
  List<GroupItem> get groups => _groups;

  @override
  Map<String, int> get unreadConversationCounts => _unreadConversationCounts;

  @override
  List<ChatMessage> get chatMessages => _chatMessages;

  @override
  Map<String, List<ChatMessage>> get conversationMessages =>
      _conversationMessages;

  @override
  Map<String, List<StudentOption>> get groupMembers => _groupMembers;

  @override
  List<StudentOption> get students => _students;

  @override
  List<String> get menuItems => _menuItems;

  Future<void> fetchBootstrap() async {
    await Future.wait([
      fetchStudent(),
      fetchCourses(),
      fetchSchedules(),
      fetchAssignments(),
      fetchAnnouncements(),
      fetchCalendarEvents(),
      fetchStudents(),
      fetchMenuItems(),
    ]);
  }

  Future<void> fetchStudent() async {
    try {
      final data = await _getMap('/student');
      _student = StudentProfile.fromJson(data);
    } catch (_) {
      _student = _fallback.student;
    }
  }

  Future<void> fetchCourses() async {
    try {
      final data = await _getList('/courses');
      _courses
        ..clear()
        ..addAll(data.cast<String>());
    } catch (_) {
      _courses
        ..clear()
        ..addAll(_fallback.courses);
    }
  }

  Future<void> fetchSchedules() async {
    try {
      final data = await _getList('/schedules');
      _schedules
        ..clear()
        ..addAll(
          data.map(
            (item) => ScheduleItem.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _schedules
        ..clear()
        ..addAll(_fallback.schedules);
    }
  }

  Future<void> fetchAssignments() async {
    try {
      final data = await _getList('/assignments');
      _assignments
        ..clear()
        ..addAll(
          data.map(
            (item) => AssignmentItem.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _assignments
        ..clear()
        ..addAll(_fallback.assignments);
    }
  }

  Future<void> fetchAnnouncements() async {
    try {
      final data = await _getList('/announcements');
      _announcements
        ..clear()
        ..addAll(
          data.map(
            (item) => AnnouncementItem.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _announcements
        ..clear()
        ..addAll(_fallback.announcements);
    }
  }

  Future<void> fetchCalendarEvents() async {
    try {
      final data = await _getList('/calendar-events');
      _calendarEvents
        ..clear()
        ..addAll(
          data.map(
            (item) => CalendarEvent.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _calendarEvents
        ..clear()
        ..addAll(_fallback.calendarEvents);
    }
  }

  Future<void> fetchStudents() async {
    try {
      final data = await _getList('/students');
      _students
        ..clear()
        ..addAll(
          data.map(
            (item) => StudentOption.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _students
        ..clear()
        ..addAll(_fallback.students);
    }
  }

  Future<void> fetchMenuItems() async {
    try {
      final data = await _getList('/menu-items');
      _menuItems
        ..clear()
        ..addAll(data.cast<String>());
    } catch (_) {
      _menuItems
        ..clear()
        ..addAll(_fallback.menuItems);
    }
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final json = await _getJson(path);
    if (json is Map<String, dynamic>) return json;
    throw const FormatException('Expected JSON object');
  }

  Future<List<dynamic>> _getList(String path) async {
    final json = await _getJson(path);
    if (json is List<dynamic>) return json;
    throw const FormatException('Expected JSON array');
  }

  Future<dynamic> _getJson(String path) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    final request = await _httpClient.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
    }

    return jsonDecode(body);
  }
}
