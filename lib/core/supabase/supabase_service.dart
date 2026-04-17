import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';

class SupabaseService {
  static final Map<String, String> _groupIdByName = <String, String>{};
  static final Map<String, String> _studentIdByNumber = <String, String>{};

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static String? get currentUserId => client.auth.currentUser?.id;

  static Future<StudentProfile?> fetchCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return StudentProfile.fromJson(response);
  }

  static Future<void> loadCurrentProfileToAppState() async {
    try {
      final profile = await fetchCurrentProfile();
      if (profile != null) {
        MockData.setStudent(profile);
      }
    } catch (_) {
      MockData.resetStudent();
    }
  }

  static Future<void> loadCurrentUserDataToAppState() async {
    if (!isAuthenticated) return;

    await Future.wait([
      _safeLoad(loadCurrentProfileToAppState),
      _safeLoad(_loadCourses),
      _safeLoad(_loadSchedules),
      _safeLoad(_loadAssignments),
      _safeLoad(_loadAnnouncements),
      _safeLoad(_loadCalendarEvents),
      _safeLoad(_loadStudents),
      _safeLoad(_loadGroupsAndMembers),
      _safeLoad(_loadMessagesAndUnreadCounts),
      _safeLoad(_loadMenuItems),
    ]);
  }

  static void resetAppProfile() {
    MockData.resetStudent();
  }

  static Future<void> refreshMessagesData() async {
    if (!isAuthenticated) return;
    await Future.wait([
      _safeLoad(_loadGroupsAndMembers),
      _safeLoad(_loadMessagesAndUnreadCounts),
    ]);
  }

  static Future<void> _safeLoad(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (_) {
      // Keep current in-memory state if one source fails.
    }
  }

  static Future<void> markConversationRead(String groupName) async {
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final groupId = _groupIdByName[groupName];
    if (groupId == null) return;

    await client.from('unread_conversation_counts').upsert({
      'profile_id': userId,
      'group_id': groupId,
      'unread_count': 0,
    });

    MockData.unreadConversationCounts[groupName] = 0;
  }

  static Future<void> updateCurrentProfile({String? bio}) async {
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final payload = <String, dynamic>{};
    if (bio != null) payload['bio'] = bio;
    if (payload.isEmpty) return;

    await client.from('profiles').update(payload).eq('id', userId);
    await loadCurrentProfileToAppState();
  }

  static Future<void> sendMessage({
    required String groupName,
    required String message,
    String? replyTo,
    String? attachment,
  }) async {
    if (!isAuthenticated) return;
    final groupId = _groupIdByName[groupName];
    final userId = currentUserId!;
    if (groupId == null) return;

    await client.from('messages').insert({
      'group_id': groupId,
      'sender_profile_id': userId,
      'message': message,
      'time_label': DateTime.now().toIso8601String(),
      'is_me': true,
      'reply_to': replyTo,
      'attachment': attachment,
      'is_system': false,
    });

    await _loadMessagesAndUnreadCounts();
  }

  static Future<void> forwardMessage({
    required String targetGroupName,
    required String message,
    String? attachment,
  }) async {
    await sendMessage(
      groupName: targetGroupName,
      message: message,
      attachment: attachment,
    );
  }

  static Future<void> createDirectMessage({
    required StudentOption target,
    required String initialMessage,
  }) async {
    if (!isAuthenticated) return;
    final userId = currentUserId!;

    final existingGroup = await client
        .from('groups')
        .select()
        .eq('is_direct', true)
        .eq('name', target.name)
        .maybeSingle();

    late final String groupId;
    if (existingGroup == null) {
      final created = await client
          .from('groups')
          .insert({
            'name': target.name,
            'member_count': 'Direkt mesaj',
            'muted': false,
            'color': '#31A8AD',
            'avatar_index': 0,
            'is_direct': true,
          })
          .select()
          .single();
      groupId = created['id'] as String;

      final targetProfileId = _studentIdByNumber[target.number];
      await client.from('group_members').upsert([
        {'group_id': groupId, 'profile_id': userId, 'role': 'member'},
      ]);
      if (targetProfileId != null) {
        try {
          await client.from('group_members').upsert([
            {
              'group_id': groupId,
              'profile_id': targetProfileId,
              'role': 'member',
            },
          ]);
        } catch (_) {
          // Some RLS policies allow only own membership insert.
        }
      }
    } else {
      groupId = existingGroup['id'] as String;
      final targetProfileId = _studentIdByNumber[target.number];
      await client.from('group_members').upsert([
        {'group_id': groupId, 'profile_id': userId, 'role': 'member'},
      ]);
      if (targetProfileId != null) {
        try {
          await client.from('group_members').upsert([
            {
              'group_id': groupId,
              'profile_id': targetProfileId,
              'role': 'member',
            },
          ]);
        } catch (_) {
          // Some RLS policies allow only own membership insert.
        }
      }
    }

    await client.from('messages').insert({
      'group_id': groupId,
      'sender_profile_id': userId,
      'message': initialMessage,
      'time_label': DateTime.now().toIso8601String(),
      'is_me': true,
      'is_system': false,
    });

    await refreshMessagesData();
  }

  static Future<void> createGroup({
    required String name,
    required String topic,
    required int avatarIndex,
    required List<StudentOption> members,
  }) async {
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final created = await client
        .from('groups')
        .insert({
          'name': name,
          'member_count': '${members.length + 1} üye',
          'muted': false,
          'color': '#31A8AD',
          'avatar_index': avatarIndex,
          'is_direct': false,
        })
        .select()
        .single();

    final groupId = created['id'] as String;
    final allMembers = <Map<String, dynamic>>[
      {'group_id': groupId, 'profile_id': userId, 'role': 'owner'},
      ...members.map((member) {
        final memberId = _studentIdByNumber[member.number];
        return {'group_id': groupId, 'profile_id': memberId, 'role': 'member'};
      }),
    ].where((item) => item['profile_id'] != null).toList();

    await client.from('group_members').upsert([
      {'group_id': groupId, 'profile_id': userId, 'role': 'owner'},
    ]);
    for (final member in allMembers.skip(1)) {
      try {
        await client.from('group_members').upsert([member]);
      } catch (_) {
        // Some RLS policies allow only own membership insert.
      }
    }
    await client.from('messages').insert({
      'group_id': groupId,
      'sender_profile_id': userId,
      'message': topic.isEmpty
          ? 'Yeni grup oluşturuldu.'
          : '$topic oluşturuldu.',
      'time_label': DateTime.now().toIso8601String(),
      'is_me': false,
      'is_system': true,
    });

    await refreshMessagesData();
  }

  static Future<void> _loadCourses() async {
    final rows = await client
        .from('courses')
        .select()
        .order('title', ascending: true);

    final courseTitles = rows
        .map((row) => (row['title'] as String?)?.trim())
        .whereType<String>()
        .where((title) => title.isNotEmpty)
        .toList();

    MockData.setCourses(courseTitles);
  }

  static Future<void> _loadSchedules() async {
    final userId = currentUserId;
    if (userId == null) return;

    final rows = await client
        .from('schedule_items')
        .select('*, courses(title, instructor, credit, ects)')
        .eq('profile_id', userId)
        .order('created_at', ascending: true);

    final schedules = rows.map((row) {
      final course = row['courses'] as Map<String, dynamic>?;
      final time =
          (row['time_label'] as String?) ??
          (row['day_label'] as String?) ??
          '-';
      return ScheduleItem(
        course: (course?['title'] as String?) ?? 'Ders',
        time: time,
        location: (row['location'] as String?) ?? '-',
        instructor: (course?['instructor'] as String?) ?? '-',
        color: colorFromJson(row['color'] ?? '#31A8AD'),
        badge: (row['badge'] as String?) ?? 'Program',
        credit: (course?['credit'] as String?) ?? '-',
        ects: (course?['ects'] as String?) ?? '-',
        examSummary: (row['exam_summary'] as String?) ?? '-',
        letter: (row['letter'] as String?) ?? '-',
      );
    }).toList();

    MockData.setSchedules(schedules);
  }

  static Future<void> _loadAssignments() async {
    final userId = currentUserId;
    if (userId == null) return;

    final rows = await client
        .from('assignments')
        .select('*, courses(title)')
        .eq('profile_id', userId)
        .order('created_at', ascending: false);

    final assignments = rows.map((row) {
      final course = row['courses'] as Map<String, dynamic>?;
      final deadlineRaw = row['deadline'] as String?;
      final deadline = _formatDate(deadlineRaw);
      final isCompleted = (row['is_completed'] as bool?) ?? false;
      final isOverdue = (row['is_overdue'] as bool?) ?? false;
      return AssignmentItem(
        title: (row['title'] as String?) ?? 'Ödev',
        course: (course?['title'] as String?) ?? 'Ders',
        description: (row['description'] as String?) ?? '-',
        deadline: deadline,
        timeLeft: _timeLeft(deadlineRaw, isCompleted: isCompleted),
        status: (row['status'] as String?) ?? 'Aktif',
        documentInfo: row['document_info'] as String?,
        submissionNote: row['submission_note'] as String?,
        isCompleted: isCompleted,
        isOverdue: isOverdue,
      );
    }).toList();

    MockData.setAssignments(assignments);
  }

  static Future<void> _loadAnnouncements() async {
    final rows = await client
        .from('announcements')
        .select()
        .order('published_at', ascending: false);

    final announcements = rows.map((row) {
      final published = row['published_at'] as String?;
      return AnnouncementItem(
        title: (row['title'] as String?) ?? 'Duyuru',
        description: (row['description'] as String?) ?? '-',
        scope: scopeTypeFromString((row['scope'] as String?) ?? 'universite'),
        date: _timeAgo(published),
        isNew: (row['is_new'] as bool?) ?? false,
      );
    }).toList();

    MockData.setAnnouncements(announcements);
  }

  static Future<void> _loadCalendarEvents() async {
    final rows = await client
        .from('calendar_events')
        .select()
        .order('created_at', ascending: false);

    final events = rows
        .map(
          (row) => CalendarEvent(
            title: (row['title'] as String?) ?? 'Takvim Etkinliği',
            range: (row['range_label'] as String?) ?? '-',
            color: colorFromJson(row['color'] ?? '#31A8AD'),
          ),
        )
        .toList();

    MockData.setCalendarEvents(events);
  }

  static Future<void> _loadStudents() async {
    final rows = await client.from('profiles').select();
    _studentIdByNumber.clear();
    final students = rows.map((row) {
      final studentNumber = (row['student_number'] as String?) ?? '-';
      final profileId = row['id'] as String?;
      if (profileId != null) {
        _studentIdByNumber[studentNumber] = profileId;
      }
      return StudentOption(
        name:
            (row['full_name'] as String?) ??
            (row['name'] as String?) ??
            'Öğrenci',
        number: studentNumber,
        role: (row['role'] as String?) ?? 'Öğrenci',
      );
    }).toList();

    MockData.setStudents(students);
  }

  static Future<void> _loadGroupsAndMembers() async {
    final userId = currentUserId;
    if (userId == null) return;
    _groupIdByName.clear();

    final memberRows = await client
        .from('group_members')
        .select('group_id')
        .eq('profile_id', userId);

    final groupIds = memberRows
        .map((row) => row['group_id'] as String?)
        .whereType<String>()
        .toList();
    if (groupIds.isEmpty) {
      MockData.setGroups(const <GroupItem>[]);
      MockData.setGroupMembers(const <String, List<StudentOption>>{});
      return;
    }

    final groupRows = await client
        .from('groups')
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    final groups = groupRows.map((row) {
      final name = (row['name'] as String?) ?? 'Grup';
      final id = row['id'] as String;
      _groupIdByName[name] = id;
      return GroupItem(
        name: name,
        memberCount: (row['member_count'] as String?) ?? 'Üye yok',
        muted: (row['muted'] as bool?) ?? false,
        color: colorFromJson(row['color'] ?? '#31A8AD'),
        avatarIndex: (row['avatar_index'] as int?) ?? 0,
        isDirect: (row['is_direct'] as bool?) ?? false,
        mutedUntil: row['muted_until'] as String?,
      );
    }).toList();

    MockData.setGroups(groups);

    final groupMemberRows = await client
        .from('group_members')
        .select('group_id, profiles(id, full_name, role)')
        .inFilter('group_id', groupIds);

    final membersByGroup = <String, List<StudentOption>>{};
    for (final row in groupMemberRows) {
      final groupId = row['group_id'] as String?;
      final profile = row['profiles'] as Map<String, dynamic>?;
      if (groupId == null || profile == null) continue;
      final name = _groupIdByName.entries
          .firstWhere(
            (entry) => entry.value == groupId,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (name.isEmpty) continue;
      final member = StudentOption(
        name: (profile['full_name'] as String?) ?? 'Öğrenci',
        number: (profile['id'] as String?) ?? '-',
        role: (profile['role'] as String?) ?? 'Öğrenci',
      );
      membersByGroup.putIfAbsent(name, () => <StudentOption>[]).add(member);
    }

    MockData.setGroupMembers(membersByGroup);
  }

  static Future<void> _loadMessagesAndUnreadCounts() async {
    if (_groupIdByName.isEmpty || currentUserId == null) {
      MockData.setConversationMessages(const <String, List<ChatMessage>>{});
      MockData.setUnreadConversationCounts(const <String, int>{});
      return;
    }
    final groupIds = _groupIdByName.values.toList();

    final messageRows = await client
        .from('messages')
        .select(
          'group_id, message, time_label, is_me, reply_to, attachment, is_system, profiles(full_name)',
        )
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: true);

    final messagesByGroup = <String, List<ChatMessage>>{};
    for (final row in messageRows) {
      final groupId = row['group_id'] as String?;
      if (groupId == null) continue;
      final groupName = _groupIdByName.entries
          .firstWhere(
            (entry) => entry.value == groupId,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (groupName.isEmpty) continue;

      final senderProfile = row['profiles'] as Map<String, dynamic>?;
      final senderName =
          (senderProfile?['full_name'] as String?) ??
          ((row['is_me'] as bool?) ?? false
              ? MockData.student.name
              : 'Öğrenci');

      final message = ChatMessage(
        sender: senderName,
        message: (row['message'] as String?) ?? '',
        time: _formatTime(row['time_label'] as String?),
        isMe: (row['is_me'] as bool?) ?? false,
        replyTo: row['reply_to'] as String?,
        attachment: row['attachment'] as String?,
        isSystem: (row['is_system'] as bool?) ?? false,
      );
      messagesByGroup
          .putIfAbsent(groupName, () => <ChatMessage>[])
          .add(message);
    }

    MockData.setConversationMessages(messagesByGroup);

    final unreadRows = await client
        .from('unread_conversation_counts')
        .select('group_id, unread_count')
        .eq('profile_id', currentUserId!);

    final unreadByName = <String, int>{};
    for (final row in unreadRows) {
      final groupId = row['group_id'] as String?;
      if (groupId == null) continue;
      final groupName = _groupIdByName.entries
          .firstWhere(
            (entry) => entry.value == groupId,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (groupName.isNotEmpty) {
        unreadByName[groupName] = (row['unread_count'] as int?) ?? 0;
      }
    }
    MockData.setUnreadConversationCounts(unreadByName);
  }

  static Future<void> _loadMenuItems() async {
    final rows = await client
        .from('menu_items')
        .select('title')
        .order('menu_date', ascending: false);

    final items = rows
        .map((row) => (row['title'] as String?)?.trim())
        .whereType<String>()
        .where((title) => title.isNotEmpty)
        .toList();

    MockData.setMenuItems(items);
  }

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate)?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static String _formatTime(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '')?.toLocal();
    if (date == null) return '-';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _timeAgo(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '')?.toLocal();
    if (date == null) return 'Bugün';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }

  static String _timeLeft(String? isoDate, {required bool isCompleted}) {
    if (isCompleted) return 'Tamamlandı';
    final date = DateTime.tryParse(isoDate ?? '')?.toLocal();
    if (date == null) return 'Tarih yok';
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Gecikti';
    if (diff.inHours < 24) return '${diff.inHours} saat';
    return '${diff.inDays} gün';
  }
}
