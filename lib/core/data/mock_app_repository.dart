import '../models/mock_models.dart';
import 'app_repository.dart';
import 'mock_data.dart';

class MockAppRepository implements AppRepository {
  const MockAppRepository();

  @override
  StudentProfile get student => MockData.student;

  @override
  List<String> get courses => MockData.courses;

  @override
  List<ScheduleItem> get schedules => MockData.schedules;

  @override
  List<AssignmentItem> get assignments => MockData.assignments;

  @override
  List<AnnouncementItem> get announcements => MockData.announcements;

  @override
  List<CalendarEvent> get calendarEvents => MockData.calendarEvents;

  @override
  List<GroupItem> get groups => MockData.groups;

  @override
  Map<String, int> get unreadConversationCounts =>
      MockData.unreadConversationCounts;

  @override
  List<ChatMessage> get chatMessages => MockData.chatMessages;

  @override
  Map<String, List<ChatMessage>> get conversationMessages =>
      MockData.conversationMessages;

  @override
  Map<String, List<StudentOption>> get groupMembers => MockData.groupMembers;

  @override
  List<StudentOption> get students => MockData.students;

  @override
  List<String> get menuItems => MockData.menuItems;
}
