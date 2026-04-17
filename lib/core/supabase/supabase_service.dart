import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';

class SupabaseService {
  static String _tblProfiles = 'profiles';
  static String _tblCourses = 'courses';
  static String _tblScheduleItems = 'schedule_items';
  static String _tblAssignments = 'assignments';
  static String _tblAnnouncements = 'announcements';
  static String _tblCalendarEvents = 'calendar_events';
  static String _tblGroups = 'groups';
  static String _tblGroupMembers = 'group_members';
  static String _tblMessages = 'messages';
  static String _tblUnreadCounts = 'unread_conversation_counts';
  static String _tblMenuItems = 'menu_items';

  static bool _tableNamesResolved = false;
  static RealtimeChannel? _conversationChannel;
  static final StreamController<String> _conversationEventsController =
      StreamController<String>.broadcast();

  static final Map<String, String> _groupIdByName = <String, String>{};
  static final Map<String, String> _studentIdByNumber = <String, String>{};
  static final Map<String, String> _studentAvatarByNumber = <String, String>{};

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Stream<String> get conversationEvents =>
      _conversationEventsController.stream;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static String? get currentUserId => client.auth.currentUser?.id;

  static void resetAppSessionData() {
    if (_conversationChannel != null) {
      client.removeChannel(_conversationChannel!);
      _conversationChannel = null;
    }
    MockData.resetStudent();
    MockData.setSchedules(const <ScheduleItem>[]);
    MockData.setAssignments(const <AssignmentItem>[]);
    MockData.setGroups(const <GroupItem>[]);
    MockData.setUnreadConversationCounts(const <String, int>{});
    MockData.setConversationMessages(const <String, List<ChatMessage>>{});
    MockData.setGroupMembers(const <String, List<StudentOption>>{});
    MockData.setConversationPinned(const <String, bool>{});
    MockData.setConversationLastActivity(const <String, int>{});
    MockData.setConversationLastMessage(const <String, String>{});
    MockData.deletedConversationAt.clear();
    MockData.hiddenMessageIdsByConversation.clear();
    _groupIdByName.clear();
  }

  static Future<StudentProfile?> fetchCurrentProfile() async {
    await _ensureTableNamesResolved();
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from(_tblProfiles)
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
      // Keep current profile in app state when DB read fails.
    }
  }

  static Future<void> loadCurrentUserDataToAppState() async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();

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
    await _safeLoad(ensureConversationRealtime);
  }

  static Future<void> ensureConversationRealtime() async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();
    if (_conversationChannel != null) return;

    final uid = currentUserId ?? 'anon';
    final channel = client.channel('dm-events-$uid');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tblMessages,
          callback: (payload) => _emitEventFromPayload(payload, _tblMessages),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tblUnreadCounts,
          callback: (payload) =>
              _emitEventFromPayload(payload, _tblUnreadCounts),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tblGroups,
          callback: (payload) => _emitEventFromPayload(payload, _tblGroups),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tblGroupMembers,
          callback: (payload) =>
              _emitEventFromPayload(payload, _tblGroupMembers),
        )
        .subscribe();

    _conversationChannel = channel;
  }

  static void _emitEventFromPayload(
    PostgresChangePayload payload,
    String table,
  ) {
    final dynamic record = payload.newRecord.isNotEmpty
        ? payload.newRecord
        : payload.oldRecord;
    if (record is! Map) {
      _conversationEventsController.add('*');
      return;
    }

    String? groupId;
    if (table == _tblGroups) {
      groupId = record['id']?.toString();
    } else {
      groupId = record['group_id']?.toString();
    }

    if (groupId == null || groupId.isEmpty) {
      _conversationEventsController.add('*');
      return;
    }
    final groupName = _groupNameById(groupId);
    _conversationEventsController.add(groupName ?? '*');
  }

  static String? _groupNameById(String groupId) {
    for (final entry in _groupIdByName.entries) {
      if (entry.value == groupId) return entry.key;
    }
    return null;
  }

  static void resetAppProfile() {
    MockData.resetStudent();
  }

  static Future<void> refreshMessagesData() async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();
    await _safeLoad(_loadGroupsAndMembers);
    await _safeLoad(_loadMessagesAndUnreadCounts);
  }

  static Future<void> loadMembersForGroup(String groupName) async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();

    final groupId = await _resolveGroupIdByName(groupName);
    if (groupId == null) return;

    final memberRows = await client
        .from(_tblGroupMembers)
        .select('profile_id')
        .eq('group_id', groupId);
    final profileIds = memberRows
        .map((row) => row['profile_id'] as String?)
        .whereType<String>()
        .toList();
    if (profileIds.isEmpty) {
      MockData.groupMembers[groupName] = <StudentOption>[];
      return;
    }

    final profileRows = await client
        .from(_tblProfiles)
        .select('id, full_name, role, student_number')
        .inFilter('id', profileIds);

    final members = profileRows
        .map(
          (row) => StudentOption(
            name: (row['full_name'] as String?) ?? 'Öğrenci',
            number: (row['student_number'] as String?) ?? '-',
            role: (row['role'] as String?) ?? 'Öğrenci',
          ),
        )
        .toList();
    MockData.groupMembers[groupName] = members;
  }

  static Future<void> setConversationMuted({
    required String groupName,
    required bool muted,
    String? mutedUntil,
  }) async {
    await _ensureTableNamesResolved();
    final groupId = _groupIdByName[groupName];
    if (groupId == null) return;
    try {
      await client
          .from(_tblGroups)
          .update({'muted': muted, 'muted_until': muted ? mutedUntil : null})
          .eq('id', groupId);
    } catch (_) {
      // Continue with local state fallback.
    }

    final index = MockData.groups.indexWhere((item) => item.name == groupName);
    if (index != -1) {
      MockData.groups[index] = MockData.groups[index].copyWith(
        muted: muted,
        mutedUntil: muted ? mutedUntil : null,
      );
    }
  }

  static Future<void> deleteConversation(GroupItem group) async {
    await _ensureTableNamesResolved();
    final userId = currentUserId;
    final groupName = group.name;
    final groupId = group.id ?? await _resolveGroupIdByName(groupName);
    if (userId != null && groupId != null) {
      try {
        await client
            .from(_tblGroupMembers)
            .delete()
            .eq('group_id', groupId)
            .eq('profile_id', userId);
      } catch (_) {
        // Fall back to local removal.
      }
      try {
        await client
            .from(_tblUnreadCounts)
            .delete()
            .eq('group_id', groupId)
            .eq('profile_id', userId);
      } catch (_) {
        // Ignore unread cleanup errors.
      }
    }

    MockData.groups.removeWhere((group) => group.name == groupName);
    MockData.groupMembers.remove(groupName);
    MockData.conversationMessages.remove(groupName);
    MockData.unreadConversationCounts.remove(groupName);
    MockData.conversationPinned.remove(groupName);
    MockData.conversationLastActivity.remove(groupName);
    MockData.conversationLastMessage.remove(groupName);
    _groupIdByName.remove(groupName);
  }

  static Future<void> deleteConversationForCurrentUser(GroupItem group) async {
    await _ensureTableNamesResolved();
    final userId = currentUserId;
    final groupId = group.id ?? await _resolveGroupIdByName(group.name);

    if (userId != null && groupId != null) {
      try {
        await client
            .from(_tblUnreadCounts)
            .delete()
            .eq('group_id', groupId)
            .eq('profile_id', userId);
      } catch (_) {
        // Ignore unread cleanup errors.
      }
    }

    hideConversationLocally(group.name);
  }

  static Future<void> leaveGroup(GroupItem group) async {
    await _ensureTableNamesResolved();
    final userId = currentUserId;
    final groupName = group.name;
    final groupId = group.id ?? await _resolveGroupIdByName(groupName);
    if (userId == null || groupId == null) {
      throw Exception('Grup bilgisi çözümlenemedi.');
    }

    if (group.isDirect) {
      await deleteConversationForCurrentUser(group);
      return;
    }

    try {
      await client.from(_tblMessages).insert({
        'group_id': groupId,
        'sender_profile_id': userId,
        'message': '${MockData.student.name} gruptan ayrıldı.',
        'time_label': DateTime.now().toIso8601String(),
        'is_me': false,
        'is_system': true,
      });
    } catch (_) {
      // System message optional.
    }

    var deletedWithDirectQuery = true;
    try {
      await client
          .from(_tblGroupMembers)
          .delete()
          .eq('group_id', groupId)
          .eq('profile_id', userId);
    } on PostgrestException {
      deletedWithDirectQuery = false;
    }

    if (!deletedWithDirectQuery) {
      final rpcSuccess = await _leaveGroupViaRpc(groupId);
      if (!rpcSuccess) {
        throw Exception(
          'Gruptan çıkış izni yok. RLS veya leave_group_secure RPC gerekli.',
        );
      }
    }

    await refreshMessagesData();
    final stillVisible = MockData.groups.any((item) => item.name == groupName);
    if (stillVisible) {
      throw Exception(
        'Gruptan çıkış başarısız. RLS policy nedeniyle üyelik silinemedi.',
      );
    }

    try {
      await client
          .from(_tblUnreadCounts)
          .delete()
          .eq('group_id', groupId)
          .eq('profile_id', userId);
    } catch (_) {
      // Ignore unread cleanup errors.
    }

    MockData.groups.removeWhere((group) => group.name == groupName);
    MockData.groupMembers.remove(groupName);
    MockData.conversationMessages.remove(groupName);
    MockData.unreadConversationCounts.remove(groupName);
    MockData.conversationPinned.remove(groupName);
    MockData.conversationLastActivity.remove(groupName);
    MockData.conversationLastMessage.remove(groupName);
    _groupIdByName.remove(groupName);
  }

  static void removeConversationLocal(String groupName) {
    MockData.groups.removeWhere((group) => group.name == groupName);
    MockData.groupMembers.remove(groupName);
    MockData.conversationMessages.remove(groupName);
    MockData.unreadConversationCounts.remove(groupName);
    MockData.conversationPinned.remove(groupName);
    MockData.conversationLastActivity.remove(groupName);
    MockData.conversationLastMessage.remove(groupName);
    _groupIdByName.remove(groupName);
  }

  static void hideConversationLocally(String groupName) {
    MockData.deletedConversationAt[groupName] =
        DateTime.now().millisecondsSinceEpoch;
    removeConversationLocal(groupName);
  }

  static Future<void> hardDeleteConversation(GroupItem group) async {
    await _ensureTableNamesResolved();
    final groupId = group.id ?? await _resolveGroupIdByName(group.name);
    if (groupId == null) return;

    try {
      final messageRows = await client
          .from(_tblMessages)
          .select('attachment')
          .eq('group_id', groupId);

      final storageByBucket = <String, List<String>>{};
      for (final row in messageRows) {
        final raw = row['attachment'] as String?;
        if (raw == null || !raw.contains(':')) continue;
        final idx = raw.indexOf(':');
        final bucket = raw.substring(0, idx);
        final path = raw.substring(idx + 1);
        if (bucket.isEmpty || path.isEmpty) continue;
        storageByBucket.putIfAbsent(bucket, () => <String>[]).add(path);
      }

      for (final entry in storageByBucket.entries) {
        try {
          await client.storage.from(entry.key).remove(entry.value);
        } catch (_) {
          // Ignore storage cleanup errors.
        }
      }
    } catch (_) {
      // Ignore lookup errors, continue delete flow.
    }

    try {
      await client.from(_tblMessages).delete().eq('group_id', groupId);
    } catch (_) {}
    try {
      await client.from(_tblUnreadCounts).delete().eq('group_id', groupId);
    } catch (_) {}
    try {
      await client.from(_tblGroupMembers).delete().eq('group_id', groupId);
    } catch (_) {}
    try {
      await client.from(_tblGroups).delete().eq('id', groupId);
    } catch (_) {}

    removeConversationLocal(group.name);
  }

  static Future<void> deleteMessageForMe({
    required String groupName,
    required ChatMessage message,
  }) async {
    final id = await _resolveMessageId(groupName: groupName, message: message);
    if (id == null) {
      throw Exception('Mesaj kimliği çözümlenemedi.');
    }

    final hidden = MockData.hiddenMessageIdsByConversation.putIfAbsent(
      groupName,
      () => <String>{},
    );
    hidden.add(id);

    final existing = List<ChatMessage>.from(
      MockData.conversationMessages[groupName] ?? [],
    );
    existing.removeWhere((item) => item.id == id);
    MockData.conversationMessages[groupName] = existing;
  }

  static Future<void> deleteMessageForEveryone({
    required String groupName,
    required ChatMessage message,
  }) async {
    await _ensureTableNamesResolved();
    if (!message.isMe) {
      throw Exception('Sadece kendi mesajlarınızı herkesten silebilirsiniz.');
    }

    final id = await _resolveMessageId(groupName: groupName, message: message);
    if (id == null) {
      throw Exception('Mesaj kimliği çözümlenemedi.');
    }

    Map<String, dynamic>? updated;
    try {
      updated = await client
          .from(_tblMessages)
          .update({
            'message': 'Bu mesaj silindi',
            'attachment': null,
            'reply_to': null,
          })
          .eq('id', id)
          .eq('sender_profile_id', currentUserId!)
          .select('id')
          .maybeSingle();
    } on PostgrestException {
      updated = null;
    }

    if (updated == null) {
      final rpcSuccess = await _deleteMessageForEveryoneViaRpc(id);
      if (!rpcSuccess) {
        throw Exception(
          'Mesaj herkesten silinemedi. messages update policy veya delete_message_for_everyone_secure RPC gerekli.',
        );
      }
    }

    final existing = List<ChatMessage>.from(
      MockData.conversationMessages[groupName] ?? [],
    );
    final index = existing.indexWhere((item) => item.id == id);
    if (index != -1) {
      existing[index] = existing[index].copyWith(
        message: 'Bu mesaj silindi',
        attachment: null,
        replyTo: null,
      );
      MockData.conversationMessages[groupName] = existing;
      if (index == existing.length - 1) {
        MockData.conversationLastMessage[groupName] = 'Bu mesaj silindi';
      }
    }

    _conversationEventsController.add(groupName);
  }

  static Future<bool> _leaveGroupViaRpc(String groupId) async {
    try {
      final result = await client.rpc(
        'leave_group_secure',
        params: {'p_group_id': groupId},
      );
      if (result is bool) return result;
      if (result is num) return result != 0;
      if (result is String) return result.toLowerCase() == 'true';
      return result != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _deleteMessageForEveryoneViaRpc(String messageId) async {
    try {
      final result = await client.rpc(
        'delete_message_for_everyone_secure',
        params: {'p_message_id': messageId},
      );
      if (result is bool) return result;
      if (result is num) return result != 0;
      if (result is String) return result.toLowerCase() == 'true';
      return result != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _resolveMessageId({
    required String groupName,
    required ChatMessage message,
  }) async {
    if ((message.id ?? '').isNotEmpty) return message.id;
    await _ensureTableNamesResolved();
    final groupId = await _resolveGroupIdByName(groupName);
    if (groupId == null) return null;

    final rows = await client
        .from(_tblMessages)
        .select('id, sender_profile_id, message, time_label')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(100);

    for (final row in rows) {
      final sameSender =
          ((row['sender_profile_id'] as String?) == currentUserId) ==
          message.isMe;
      final sameMessage =
          ((row['message'] as String?) ?? '') == message.message;
      if (!sameSender || !sameMessage) continue;
      final id = row['id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  static void toggleConversationPinned(String groupName) {
    final current = MockData.conversationPinned[groupName] ?? false;
    MockData.conversationPinned[groupName] = !current;
  }

  static Future<void> loadConversationForGroup(String groupName) async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();

    final groupId = await _resolveGroupIdByName(groupName);
    if (groupId == null) return;

    final messageRows = await client
        .from(_tblMessages)
        .select(
          'id, sender_profile_id, message, time_label, is_me, reply_to, attachment, is_system, created_at',
        )
        .eq('group_id', groupId)
        .order('created_at', ascending: true);

    final senderIds = messageRows
        .map((row) => row['sender_profile_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final senderRows = senderIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from(_tblProfiles)
              .select('id, full_name')
              .inFilter('id', senderIds);
    final senderNameById = <String, String>{
      for (final row in senderRows)
        if (row['id'] != null)
          row['id'] as String: (row['full_name'] as String?) ?? 'Öğrenci',
    };

    final messages = messageRows
        .map((row) {
          final senderName =
              senderNameById[row['sender_profile_id'] as String? ?? ''] ??
              ((row['sender_profile_id'] as String?) == currentUserId
                  ? MockData.student.name
                  : 'Öğrenci');
          return ChatMessage(
            id: row['id'] as String?,
            sender: senderName,
            message: (row['message'] as String?) ?? '',
            time: _formatTime(row['time_label'] as String?),
            isMe: (row['sender_profile_id'] as String?) == currentUserId,
            replyTo: row['reply_to'] as String?,
            attachment: row['attachment'] as String?,
            isSystem: (row['is_system'] as bool?) ?? false,
            createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
            sendStatus: ChatSendStatus.sent,
          );
        })
        .where((message) {
          final hidden = MockData.hiddenMessageIdsByConversation[groupName];
          if (hidden == null || hidden.isEmpty) return true;
          final id = message.id;
          if (id == null || id.isEmpty) return true;
          return !hidden.contains(id);
        })
        .toList();

    MockData.conversationMessages[groupName] = messages;
    MockData.conversationLastMessage[groupName] = messages.isNotEmpty
        ? messages.last.message
        : 'Henüz mesaj yok';
    if (messages.isNotEmpty && messageRows.isNotEmpty) {
      final createdAt = DateTime.tryParse(
        messageRows.last['created_at'] as String? ?? '',
      );
      if (createdAt != null) {
        MockData.conversationLastActivity[groupName] =
            createdAt.millisecondsSinceEpoch;
      }
    }
  }

  static Future<void> loadAllConversationPreviews() async {
    if (!isAuthenticated) return;
    await _ensureTableNamesResolved();
    await refreshMessagesData();
    final groupNames = MockData.groups.map((group) => group.name).toList();
    for (final groupName in groupNames) {
      try {
        await loadConversationForGroup(groupName);
      } catch (_) {
        // Continue loading previews for remaining groups.
      }
    }
  }

  static Future<bool> setGroupAvatarPath({
    required String groupName,
    String? avatarPath,
  }) async {
    await _ensureTableNamesResolved();
    final groupId = await _resolveGroupIdByName(groupName);
    if (groupId == null) {
      return false;
    }

    var persisted = true;
    try {
      await client
          .from(_tblGroups)
          .update({'avatar_path': avatarPath})
          .eq('id', groupId);
    } catch (_) {
      persisted = false;
    }

    final index = MockData.groups.indexWhere((item) => item.name == groupName);
    if (index != -1) {
      MockData.groups[index] = MockData.groups[index].copyWith(
        avatarPath: avatarPath,
      );
    }

    await refreshMessagesData();
    return persisted;
  }

  static Future<void> addMemberToGroup({
    required String groupName,
    required StudentOption member,
  }) async {
    await _ensureTableNamesResolved();
    final groupId = await _resolveGroupIdByName(groupName);
    final profileId = _studentIdByNumber[member.number];
    if (groupId == null || profileId == null) {
      throw Exception('Grup veya üye bilgisi bulunamadı.');
    }

    await client.from(_tblGroupMembers).upsert([
      {'group_id': groupId, 'profile_id': profileId, 'role': 'member'},
    ], onConflict: 'group_id,profile_id');

    await loadMembersForGroup(groupName);
    final members = MockData.groupMembers[groupName] ?? <StudentOption>[];
    final idx = MockData.groups.indexWhere((g) => g.name == groupName);
    if (idx != -1) {
      MockData.groups[idx] = MockData.groups[idx].copyWith(
        memberCount: '${members.length} uye',
      );
    }
  }

  static Future<String?> _resolveGroupIdByName(String groupName) async {
    var groupId = _groupIdByName[groupName];
    if (groupId != null) return groupId;

    await _safeLoad(_loadGroupsAndMembers);
    groupId = _groupIdByName[groupName];
    if (groupId != null) return groupId;

    try {
      final row = await client
          .from(_tblGroups)
          .select('id, name')
          .eq('name', groupName)
          .limit(1)
          .maybeSingle();
      groupId = row?['id'] as String?;
      if (groupId != null) {
        _groupIdByName[groupName] = groupId;
      }
      return groupId;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _safeLoad(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (_) {
      // Keep current in-memory state if one source fails.
    }
  }

  static Future<void> markConversationRead(String groupName) async {
    await _ensureTableNamesResolved();
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final groupId = _groupIdByName[groupName];
    if (groupId == null) return;

    await client.from(_tblUnreadCounts).upsert({
      'profile_id': userId,
      'group_id': groupId,
      'unread_count': 0,
    }, onConflict: 'profile_id,group_id');

    MockData.unreadConversationCounts[groupName] = 0;
  }

  static Future<void> updateCurrentProfile({String? bio}) async {
    await _ensureTableNamesResolved();
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final payload = <String, dynamic>{};
    if (bio != null) payload['bio'] = bio;

    if (payload.isEmpty) return;

    await client.from(_tblProfiles).update(payload).eq('id', userId);
    await loadCurrentProfileToAppState();
  }

  static Future<void> updateCurrentProfileFields(
    Map<String, dynamic> fields,
  ) async {
    await _ensureTableNamesResolved();
    if (!isAuthenticated || fields.isEmpty) return;
    final userId = currentUserId!;
    await client.from(_tblProfiles).update(fields).eq('id', userId);
    await loadCurrentProfileToAppState();
  }

  static Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    if (!isAuthenticated) throw Exception('Oturum bulunamadı.');
    final userId = currentUserId!;
    final ext = fileExt.toLowerCase().replaceAll('.', '');
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = client.storage.from('avatars').getPublicUrl(path);
    await updateCurrentProfileFields({'avatar_path': publicUrl});
    return publicUrl;
  }

  static Future<String> uploadChatAttachment({
    required Uint8List bytes,
    required String fileName,
    required bool isImage,
  }) async {
    if (!isAuthenticated) throw Exception('Oturum bulunamadı.');
    final userId = currentUserId!;
    final safeName = fileName.replaceAll(' ', '_');
    final bucket = isImage ? 'avatars' : 'assignments';
    final path =
        '$userId/chat_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return '$bucket:$path';
  }

  static Future<String> uploadGroupPhoto({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    if (!isAuthenticated) throw Exception('Oturum bulunamadı.');
    final userId = currentUserId!;
    final ext = fileExt.toLowerCase().replaceAll('.', '');
    final path = '$userId/group_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from('avatars').getPublicUrl(path);
  }

  static Future<void> sendMessage({
    required String groupName,
    required String message,
    String? replyTo,
    String? attachment,
  }) async {
    await _ensureTableNamesResolved();
    if (!isAuthenticated) return;
    final groupId = _groupIdByName[groupName];
    final userId = currentUserId!;
    if (groupId == null) return;

    await client.from(_tblMessages).insert({
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
    _conversationEventsController.add(groupName);
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
    await _ensureTableNamesResolved();
    if (!isAuthenticated) return;
    final userId = currentUserId!;

    final targetProfileId = _studentIdByNumber[target.number];
    if (targetProfileId == null) {
      throw Exception('Seçilen kullanıcı profil kimliği bulunamadı.');
    }

    final targetProfile = await client
        .from(_tblProfiles)
        .select('full_name, avatar_path')
        .eq('id', targetProfileId)
        .maybeSingle();
    final directName =
        (targetProfile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? (targetProfile!['full_name'] as String).trim()
        : target.name;
    final directAvatarPath = targetProfile?['avatar_path'] as String?;

    final selfMembershipRows = await client
        .from(_tblGroupMembers)
        .select('group_id')
        .eq('profile_id', userId);
    final selfGroupIds = selfMembershipRows
        .map((row) => row['group_id'] as String?)
        .whereType<String>()
        .toList();

    Map<String, dynamic>? existingGroup;
    if (selfGroupIds.isNotEmpty) {
      final commonRows = await client
          .from(_tblGroupMembers)
          .select('group_id')
          .eq('profile_id', targetProfileId)
          .inFilter('group_id', selfGroupIds);

      final commonGroupIds = commonRows
          .map((row) => row['group_id'] as String?)
          .whereType<String>()
          .toList();

      if (commonGroupIds.isNotEmpty) {
        existingGroup = await client
            .from(_tblGroups)
            .select()
            .eq('is_direct', true)
            .inFilter('id', commonGroupIds)
            .limit(1)
            .maybeSingle();
      }
    }

    if (existingGroup == null && selfGroupIds.isNotEmpty) {
      existingGroup = await client
          .from(_tblGroups)
          .select()
          .eq('is_direct', true)
          .eq('name', directName)
          .inFilter('id', selfGroupIds)
          .limit(1)
          .maybeSingle();
    }

    late final String groupId;
    if (existingGroup == null) {
      final created = await client
          .from(_tblGroups)
          .insert({
            'name': directName,
            'member_count': 'Direkt mesaj',
            'muted': false,
            'color': '#31A8AD',
            'avatar_index': 0,
            'avatar_path':
                directAvatarPath ?? _studentAvatarByNumber[target.number],
            'is_direct': true,
          })
          .select()
          .single();
      groupId = created['id'] as String;

      await client.from(_tblGroupMembers).upsert([
        {'group_id': groupId, 'profile_id': userId, 'role': 'member'},
      ], onConflict: 'group_id,profile_id');
      try {
        await client.from(_tblGroupMembers).upsert([
          {
            'group_id': groupId,
            'profile_id': targetProfileId,
            'role': 'member',
          },
        ], onConflict: 'group_id,profile_id');
      } catch (_) {
        // Some RLS policies allow only own membership insert.
      }
    } else {
      groupId = existingGroup['id'] as String;
      try {
        await client
            .from(_tblGroups)
            .update({
              'name': directName,
              'avatar_path':
                  directAvatarPath ?? _studentAvatarByNumber[target.number],
            })
            .eq('id', groupId);
      } catch (_) {
        // Ignore direct conversation metadata sync errors.
      }
      await client.from(_tblGroupMembers).upsert([
        {'group_id': groupId, 'profile_id': userId, 'role': 'member'},
      ], onConflict: 'group_id,profile_id');
      try {
        await client.from(_tblGroupMembers).upsert([
          {
            'group_id': groupId,
            'profile_id': targetProfileId,
            'role': 'member',
          },
        ], onConflict: 'group_id,profile_id');
      } catch (_) {
        // Some RLS policies allow only own membership insert.
      }
    }

    await client.from(_tblMessages).insert({
      'group_id': groupId,
      'sender_profile_id': userId,
      'message': initialMessage,
      'time_label': DateTime.now().toIso8601String(),
      'is_me': true,
      'is_system': false,
    });

    await refreshMessagesData();
    _conversationEventsController.add(directName);
  }

  static Future<void> createGroup({
    required String name,
    required String topic,
    required int avatarIndex,
    required List<StudentOption> members,
    String? avatarPath,
  }) async {
    await _ensureTableNamesResolved();
    if (!isAuthenticated) return;
    final userId = currentUserId!;
    final payload = <String, dynamic>{
      'name': name,
      'member_count': '${members.length + 1} üye',
      'muted': false,
      'color': '#31A8AD',
      'avatar_index': avatarIndex,
      'is_direct': false,
      if (avatarPath != null && avatarPath.isNotEmpty)
        'avatar_path': avatarPath,
    };

    Map<String, dynamic> created;
    try {
      created = await client.from(_tblGroups).insert(payload).select().single();
    } catch (_) {
      payload.remove('avatar_path');
      created = await client.from(_tblGroups).insert(payload).select().single();
    }

    final groupId = created['id'] as String;
    final allMembers = <Map<String, dynamic>>[
      {'group_id': groupId, 'profile_id': userId, 'role': 'owner'},
      ...members.map((member) {
        final memberId = _studentIdByNumber[member.number];
        return {'group_id': groupId, 'profile_id': memberId, 'role': 'member'};
      }),
    ].where((item) => item['profile_id'] != null).toList();

    await client.from(_tblGroupMembers).upsert([
      {'group_id': groupId, 'profile_id': userId, 'role': 'owner'},
    ], onConflict: 'group_id,profile_id');
    for (final member in allMembers.skip(1)) {
      try {
        await client.from(_tblGroupMembers).upsert([
          member,
        ], onConflict: 'group_id,profile_id');
      } catch (_) {
        // Some RLS policies allow only own membership insert.
      }
    }
    await client.from(_tblMessages).insert({
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
    _conversationEventsController.add(name);
  }

  static Future<void> _loadCourses() async {
    final rows = await client
        .from(_tblCourses)
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

    final courseRows = await client
        .from(_tblCourses)
        .select('id, title, instructor, credit, ects');
    final coursesById = <String, Map<String, dynamic>>{
      for (final row in courseRows)
        if (row['id'] != null) row['id'] as String: row,
    };

    final rows = await client
        .from(_tblScheduleItems)
        .select()
        .eq('profile_id', userId)
        .order('created_at', ascending: true);

    final schedules = rows.map((row) {
      final course = coursesById[row['course_id'] as String? ?? ''];
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

    final courseRows = await client.from(_tblCourses).select('id, title');
    final courseTitleById = <String, String>{
      for (final row in courseRows)
        if (row['id'] != null)
          row['id'] as String: (row['title'] as String?) ?? 'Ders',
    };

    final rows = await client
        .from(_tblAssignments)
        .select()
        .eq('profile_id', userId)
        .order('created_at', ascending: false);

    final assignments = rows.map((row) {
      final deadlineRaw = row['deadline'] as String?;
      final deadline = _formatDate(deadlineRaw);
      final isCompleted = (row['is_completed'] as bool?) ?? false;
      final isOverdue = (row['is_overdue'] as bool?) ?? false;
      return AssignmentItem(
        title: (row['title'] as String?) ?? 'Ödev',
        course: courseTitleById[row['course_id'] as String? ?? ''] ?? 'Ders',
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
        .from(_tblAnnouncements)
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
        .from(_tblCalendarEvents)
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
    final rows = await client.from(_tblProfiles).select();
    _studentIdByNumber.clear();
    _studentAvatarByNumber.clear();
    final students = rows.map((row) {
      final rawStudentNumber = (row['student_number'] as String?)?.trim();
      final profileId = row['id'] as String?;
      final studentNumber =
          (rawStudentNumber != null && rawStudentNumber.isNotEmpty)
          ? rawStudentNumber
          : (profileId ?? '-');
      if (profileId != null) {
        _studentIdByNumber[studentNumber] = profileId;
      }
      final avatarPath = row['avatar_path'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        _studentAvatarByNumber[studentNumber] = avatarPath;
      }
      return StudentOption(
        name:
            (row['full_name'] as String?) ??
            (row['student_number'] as String?) ??
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
        .from(_tblGroupMembers)
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
        .from(_tblGroups)
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    final groups = <GroupItem>[];
    final seenDirectNames = <String>{};
    for (final row in groupRows) {
      final name = (row['name'] as String?) ?? 'Grup';
      final id = row['id'] as String;
      final isDirect = (row['is_direct'] as bool?) ?? false;

      if (isDirect && seenDirectNames.contains(name)) {
        continue;
      }
      if (isDirect) {
        seenDirectNames.add(name);
      }

      _groupIdByName.putIfAbsent(name, () => id);
      groups.add(
        GroupItem(
          id: id,
          name: name,
          memberCount: (row['member_count'] as String?) ?? 'Üye yok',
          muted: (row['muted'] as bool?) ?? false,
          color: colorFromJson(row['color'] ?? '#31A8AD'),
          avatarIndex: (row['avatar_index'] as int?) ?? 0,
          isDirect: isDirect,
          mutedUntil: row['muted_until'] as String?,
          avatarPath: row['avatar_path'] as String?,
        ),
      );
    }

    MockData.setGroups(groups);

    final groupMemberRows = await client
        .from(_tblGroupMembers)
        .select('group_id, profile_id')
        .inFilter('group_id', groupIds);

    final profileIds = groupMemberRows
        .map((row) => row['profile_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final profileRows = profileIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from(_tblProfiles)
              .select('id, full_name, role, student_number')
              .inFilter('id', profileIds);
    final profileById = <String, Map<String, dynamic>>{
      for (final row in profileRows)
        if (row['id'] != null) row['id'] as String: row,
    };

    final membersByGroup = <String, List<StudentOption>>{};
    for (final row in groupMemberRows) {
      final groupId = row['group_id'] as String?;
      final profile = profileById[row['profile_id'] as String? ?? ''];
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
        number: (profile['student_number'] as String?) ?? '-',
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
        .from(_tblMessages)
        .select(
          'id, group_id, sender_profile_id, message, time_label, is_me, reply_to, attachment, is_system, created_at',
        )
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: true);

    final senderIds = messageRows
        .map((row) => row['sender_profile_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final senderRows = senderIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from(_tblProfiles)
              .select('id, full_name')
              .inFilter('id', senderIds);
    final senderNameById = <String, String>{
      for (final row in senderRows)
        if (row['id'] != null)
          row['id'] as String: (row['full_name'] as String?) ?? 'Öğrenci',
    };

    final messagesByGroup = <String, List<ChatMessage>>{};
    final lastActivityByGroup = <String, int>{};
    final lastMessageByGroup = <String, String>{};
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

      final senderName =
          senderNameById[row['sender_profile_id'] as String? ?? ''] ??
          ((row['is_me'] as bool?) ?? false
              ? MockData.student.name
              : 'Öğrenci');

      final message = ChatMessage(
        id: row['id'] as String?,
        sender: senderName,
        message: (row['message'] as String?) ?? '',
        time: _formatTime(row['time_label'] as String?),
        isMe: (row['sender_profile_id'] as String?) == currentUserId,
        replyTo: row['reply_to'] as String?,
        attachment: row['attachment'] as String?,
        isSystem: (row['is_system'] as bool?) ?? false,
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
        sendStatus: ChatSendStatus.sent,
      );

      final hiddenMessageIds =
          MockData.hiddenMessageIdsByConversation[groupName];
      if (hiddenMessageIds != null &&
          hiddenMessageIds.isNotEmpty &&
          message.id != null &&
          hiddenMessageIds.contains(message.id!)) {
        continue;
      }

      messagesByGroup
          .putIfAbsent(groupName, () => <ChatMessage>[])
          .add(message);
      lastMessageByGroup[groupName] = message.message;

      final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (createdAt != null) {
        final ms = createdAt.millisecondsSinceEpoch;
        if (ms > (lastActivityByGroup[groupName] ?? 0)) {
          lastActivityByGroup[groupName] = ms;
        }
      }
    }

    MockData.setConversationMessages(messagesByGroup);
    MockData.setConversationLastActivity(lastActivityByGroup);
    MockData.setConversationLastMessage(lastMessageByGroup);

    if (MockData.deletedConversationAt.isNotEmpty) {
      final toHide = <String>[];
      for (final entry in MockData.deletedConversationAt.entries) {
        final latest = lastActivityByGroup[entry.key] ?? 0;
        if (latest > entry.value) {
          continue;
        }
        toHide.add(entry.key);
      }

      for (final name in toHide) {
        MockData.groups.removeWhere((group) => group.name == name);
        MockData.groupMembers.remove(name);
        MockData.conversationMessages.remove(name);
        MockData.unreadConversationCounts.remove(name);
        MockData.conversationPinned.remove(name);
        MockData.conversationLastActivity.remove(name);
        MockData.conversationLastMessage.remove(name);
      }

      MockData.deletedConversationAt.removeWhere(
        (name, hiddenAt) => (lastActivityByGroup[name] ?? 0) > hiddenAt,
      );
    }

    final unreadRows = await client
        .from(_tblUnreadCounts)
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
        if (MockData.deletedConversationAt.containsKey(groupName)) continue;
        unreadByName[groupName] = (row['unread_count'] as int?) ?? 0;
      }
    }
    MockData.setUnreadConversationCounts(unreadByName);
  }

  static Future<void> _loadMenuItems() async {
    final rows = await client
        .from(_tblMenuItems)
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

  static Future<void> _ensureTableNamesResolved() async {
    if (_tableNamesResolved) return;

    _tblProfiles = await _pickExistingTable('profiller', 'profiles');
    _tblCourses = await _pickExistingTable('dersler', 'courses');
    _tblScheduleItems = await _pickExistingTable(
      'ders_programi',
      'schedule_items',
    );
    _tblAssignments = await _pickExistingTable('odevler', 'assignments');
    _tblAnnouncements = await _pickExistingTable('duyurular', 'announcements');
    _tblCalendarEvents = await _pickExistingTable(
      'akademik_takvim',
      'calendar_events',
    );
    _tblGroups = await _pickExistingTable('gruplar', 'groups');
    _tblGroupMembers = await _pickExistingTable(
      'grup_uyeleri',
      'group_members',
    );
    _tblMessages = await _pickExistingTable('mesajlar', 'messages');
    _tblUnreadCounts = await _pickExistingTable(
      'okunmayan_mesaj_sayilari',
      'unread_conversation_counts',
    );
    _tblMenuItems = await _pickExistingTable('menu_ogeleri', 'menu_items');

    _tableNamesResolved = true;
  }

  static Future<String> _pickExistingTable(
    String turkish,
    String english,
  ) async {
    try {
      await client.from(turkish).select('id').limit(1);
      return turkish;
    } catch (_) {
      return english;
    }
  }
}
