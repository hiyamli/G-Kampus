import '../models/mock_models.dart';

abstract class AppRepository {
  StudentProfile get student;
  List<String> get courses;
  List<ScheduleItem> get schedules;
  List<AssignmentItem> get assignments;
  List<AnnouncementItem> get announcements;
  List<CalendarEvent> get calendarEvents;
  List<GroupItem> get groups;
  Map<String, int> get unreadConversationCounts;
  List<ChatMessage> get chatMessages;
  Map<String, List<ChatMessage>> get conversationMessages;
  Map<String, List<StudentOption>> get groupMembers;
  List<StudentOption> get students;
  List<String> get menuItems;
}
