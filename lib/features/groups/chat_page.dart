import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../core/supabase/supabase_service.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/floating_icon_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/tag_badge.dart';
import '../profile/public_profile_page.dart';
import 'group_info_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.group});

  final GroupItem group;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late List<ChatMessage> messages;
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<String>? _conversationSubscription;
  String? replyTo;
  String? pendingAttachment;
  int? pendingAttachmentBytes;
  bool _showJumpToBottom = false;

  @override
  void initState() {
    super.initState();
    _reloadMessagesFromRepository();
    scrollController.addListener(_onScroll);
    unawaited(_bindRealtime());
    unawaited(_refreshFromDatabase());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _bindRealtime() async {
    await SupabaseService.ensureConversationRealtime();
    _conversationSubscription = SupabaseService.conversationEvents.listen((
      name,
    ) {
      if (name != '*' && name != widget.group.name) return;
      unawaited(_refreshFromDatabase(keepScrollPosition: true));
    });
  }

  Future<void> _refreshFromDatabase({bool keepScrollPosition = false}) async {
    final wasNearBottom = _isNearBottom();
    await SupabaseService.loadConversationForGroup(widget.group.name);
    if (!mounted) return;
    setState(_reloadMessagesFromRepository);
    if (!keepScrollPosition || wasNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _reloadMessagesFromRepository() {
    messages = List.of(
      appRepository.conversationMessages[widget.group.name] ?? <ChatMessage>[],
    );
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    scrollController.removeListener(_onScroll);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;
    return (scrollController.position.maxScrollExtent -
            scrollController.offset) <
        120;
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final shouldShow = !_isNearBottom();
    if (shouldShow == _showJumpToBottom) return;
    setState(() => _showJumpToBottom = shouldShow);
  }

  StudentProfile get _directProfile {
    StudentOption? option;
    for (final student in appRepository.students) {
      if (student.name == widget.group.name) {
        option = student;
        break;
      }
    }

    return StudentProfile(
      name: widget.group.name,
      number: option?.number ?? appRepository.student.number,
      department: appRepository.student.department,
      grade: appRepository.student.grade,
      gpa: appRepository.student.gpa,
      bio: '${widget.group.name} ile doğrudan iletişim profili.',
      role: option?.role ?? 'Öğrenci',
      courseCount: appRepository.student.courseCount,
      notificationsEnabled: true,
    );
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  Future<void> _pickDocumentAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      final files = result?.files;
      final file = (files == null || files.isEmpty) ? null : files.first;
      if (file == null || file.bytes == null) return;
      final bytes = file.bytes!;

      final uploadedPath = await SupabaseService.uploadChatAttachment(
        bytes: bytes,
        fileName: file.name,
        isImage: false,
      );

      if (!mounted) return;
      setState(() {
        pendingAttachment = uploadedPath;
        pendingAttachmentBytes = bytes.length;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dosya eklenemedi: $error')));
    }
  }

  Future<void> _pickImageAttachment() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final uploadedPath = await SupabaseService.uploadChatAttachment(
        bytes: bytes,
        fileName: picked.name,
        isImage: true,
      );

      if (!mounted) return;
      setState(() {
        pendingAttachment = uploadedPath;
        pendingAttachmentBytes = bytes.length;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotoğraf eklenemedi: $error')));
    }
  }

  Future<void> _openDetails() async {
    if (widget.group.isDirect) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfilePage(
            profile: _directProfile,
            avatarIndex: 0,
            compactDirect: true,
            commonCourses: const ['Mobil Programlama', 'UI Design Studio'],
          ),
        ),
      );
      return;
    }

    final latest = appRepository.groups.firstWhere(
      (group) => group.name == widget.group.name,
      orElse: () => widget.group,
    );

    final leftGroup = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GroupInfoPage(group: latest)),
    );

    if (leftGroup == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _searchMessages() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MessageSearchSheet(messages: messages),
    );
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && pendingAttachment == null) return;

    final localTempId = DateTime.now().microsecondsSinceEpoch.toString();
    final optimistic = ChatMessage(
      localTempId: localTempId,
      sender: appRepository.student.name,
      message: text,
      time: TimeOfDay.now().format(context),
      isMe: true,
      replyTo: replyTo,
      attachment: pendingAttachment,
      createdAt: DateTime.now(),
      sendStatus: ChatSendStatus.sending,
    );

    setState(() {
      messages = [...messages, optimistic];
      messageController.clear();
      replyTo = null;
      pendingAttachment = null;
      pendingAttachmentBytes = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      await SupabaseService.sendMessage(
        groupName: widget.group.name,
        message: text,
        replyTo: optimistic.replyTo,
        attachment: optimistic.attachment,
      );

      if (!mounted) return;
      setState(_reloadMessagesFromRepository);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (!mounted) return;
      final failedIndex = messages.lastIndexWhere(
        (item) => item.localTempId == localTempId,
      );
      if (failedIndex != -1) {
        setState(() {
          messages[failedIndex] = messages[failedIndex].copyWith(
            sendStatus: ChatSendStatus.failed,
          );
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi. Tekrar deneyin. $error')),
      );
    }
  }

  Future<void> _retryFailedMessage(ChatMessage failed) async {
    if (failed.sendStatus != ChatSendStatus.failed) return;
    final index = messages.indexWhere(
      (item) => item.localTempId == failed.localTempId,
    );
    if (index == -1) return;

    setState(() {
      messages[index] = failed.copyWith(sendStatus: ChatSendStatus.sending);
    });

    try {
      await SupabaseService.sendMessage(
        groupName: widget.group.name,
        message: failed.message,
        replyTo: failed.replyTo,
        attachment: failed.attachment,
      );
      if (!mounted) return;
      setState(_reloadMessagesFromRepository);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages[index] = failed.copyWith(sendStatus: ChatSendStatus.failed);
      });
    }
  }

  Future<void> _showMessageActions(
    LongPressStartDetails details,
    ChatMessage message,
  ) async {
    final menuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'reply', child: Text('Mesaj Cevapla')),
      const PopupMenuItem(value: 'forward', child: Text('Mesaj İlet')),
      const PopupMenuItem(value: 'copy', child: Text('Kopyala')),
      const PopupMenuItem(value: 'delete', child: Text('Mesajı Sil')),
      if (message.sendStatus == ChatSendStatus.failed)
        const PopupMenuItem(value: 'retry', child: Text('Tekrar Gönder')),
    ];

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy - 64,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withValues(alpha: 0.98),
      items: menuItems,
    );

    if (selected == 'reply') {
      setState(() => replyTo = message.message);
    }
    if (selected == 'forward' && mounted) {
      await _showForwardSheet(message);
    }
    if (selected == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.message));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mesaj kopyalandı.')));
    }
    if (selected == 'retry') {
      await _retryFailedMessage(message);
    }
    if (selected == 'delete') {
      await _showDeleteMessageActions(message);
    }
  }

  Future<void> _showDeleteMessageActions(ChatMessage message) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(CupertinoIcons.delete_solid),
              title: const Text('Benden Sil'),
              onTap: () => Navigator.of(context).pop('me'),
            ),
            if (message.isMe)
              ListTile(
                leading: const Icon(CupertinoIcons.trash),
                title: const Text('Herkesten Sil'),
                onTap: () => Navigator.of(context).pop('all'),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    if (selected == 'me') {
      try {
        await SupabaseService.deleteMessageForMe(
          groupName: widget.group.name,
          message: message,
        );
        if (!mounted) return;
        setState(_reloadMessagesFromRepository);
      } catch (error) {
        if (message.id == null && message.localTempId != null) {
          setState(() {
            messages = messages
                .where((item) => item.localTempId != message.localTempId)
                .toList();
          });
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj silinemedi: $error')));
      }
      return;
    }

    if (selected == 'all') {
      try {
        await SupabaseService.deleteMessageForEveryone(
          groupName: widget.group.name,
          message: message,
        );
        await SupabaseService.loadConversationForGroup(widget.group.name);
        if (!mounted) return;
        setState(_reloadMessagesFromRepository);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj herkesten silinemedi. Policy gerekir: $error'),
          ),
        );
      }
    }
  }

  Future<void> _showForwardSheet(ChatMessage sourceMessage) async {
    final target = await showModalBottomSheet<GroupItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ForwardMessageSheet(
        currentGroupName: widget.group.name,
        groups: appRepository.groups,
      ),
    );

    if (target == null || !mounted) return;

    try {
      await SupabaseService.forwardMessage(
        targetGroupName: target.name,
        message: sourceMessage.message,
        attachment: sourceMessage.attachment,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj ${target.name} sohbetine iletildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mesaj iletilemedi: $error')));
    }
  }

  List<_ChatTimelineEntry> _timelineEntries() {
    final entries = <_ChatTimelineEntry>[];
    DateTime? previousDate;
    final unreadCount =
        appRepository.unreadConversationCounts[widget.group.name] ?? 0;
    final unreadStartIndex = unreadCount > 0
        ? (messages.length - unreadCount).clamp(0, messages.length)
        : -1;

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      final messageDate = _resolveMessageDate(message);
      if (messageDate != null) {
        if (previousDate == null ||
            previousDate.year != messageDate.year ||
            previousDate.month != messageDate.month ||
            previousDate.day != messageDate.day) {
          entries.add(_ChatTimelineEntry.date(_formatDateLabel(messageDate)));
          previousDate = messageDate;
        }
      }

      if (index == unreadStartIndex) {
        entries.add(const _ChatTimelineEntry.unread('Okunmayan Mesajlar'));
      }

      entries.add(_ChatTimelineEntry.message(message));
    }

    return entries;
  }

  DateTime? _resolveMessageDate(ChatMessage message) {
    if (message.createdAt != null) return message.createdAt!.toLocal();
    final now = DateTime.now();
    final parts = message.time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final candidate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(candidate).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineEntries();
    final canSend =
        messageController.text.trim().isNotEmpty || pendingAttachment != null;
    return CampusScaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 28),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.group.color, AppColors.ink],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        image:
                            (widget.group.avatarPath != null &&
                                widget.group.avatarPath!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(widget.group.avatarPath!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (widget.group.avatarPath == null ||
                              widget.group.avatarPath!.isEmpty)
                          ? Icon(
                              widget.group.isDirect
                                  ? CupertinoIcons.person_fill
                                  : CupertinoIcons.person_3_fill,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openDetails,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.group.memberCount,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FloatingIconButton(
                      icon: CupertinoIcons.search,
                      onTap: _searchMessages,
                      size: 44,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (context, index) {
                    final entry = timeline[index];
                    if (entry.type == _ChatTimelineType.date) {
                      return _TimelineChip(label: entry.label!);
                    }
                    if (entry.type == _ChatTimelineType.unread) {
                      return _UnreadDivider(label: entry.label!);
                    }
                    final message = entry.message!;
                    if (message.isSystem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MessageBubble(message: message),
                      );
                    }
                    return GestureDetector(
                      onLongPressStart: (details) =>
                          _showMessageActions(details, message),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MessageBubble(message: message),
                      ),
                    );
                  },
                  itemCount: timeline.length,
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    if (replyTo != null || pendingAttachment != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sunrise.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pendingAttachment != null
                                  ? CupertinoIcons.paperclip
                                  : CupertinoIcons.reply,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: pendingAttachment != null
                                  ? Row(
                                      children: [
                                        if (_isImageAttachment(
                                          pendingAttachment!,
                                        ))
                                          Container(
                                            width: 34,
                                            height: 34,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  _attachmentUrl(
                                                    pendingAttachment!,
                                                  ),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            _formatBytes(
                                              pendingAttachmentBytes,
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Yanıt: $replyTo',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                replyTo = null;
                                pendingAttachment = null;
                                pendingAttachmentBytes = null;
                              }),
                              child: const Icon(CupertinoIcons.xmark, size: 16),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingIconButton(
                          icon: CupertinoIcons.plus,
                          onTap: () => unawaited(_pickDocumentAttachment()),
                          size: 42,
                          opacity: 0.58,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.52),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      unawaited(_pickImageAttachment()),
                                  icon: const Icon(
                                    CupertinoIcons.camera_fill,
                                    size: 18,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: messageController,
                                    onChanged: (_) => setState(() {}),
                                    minLines: 1,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Mesaj',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: FloatingActionButton(
                            heroTag: null,
                            elevation: 0,
                            onPressed: canSend
                                ? () => unawaited(_sendMessage())
                                : null,
                            child: Icon(
                              canSend
                                  ? CupertinoIcons.arrow_up
                                  : CupertinoIcons.mic_fill,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
          if (_showJumpToBottom)
            Positioned(
              right: 10,
              bottom: 100,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: _scrollToBottom,
                child: const Icon(CupertinoIcons.chevron_down),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ChatTimelineType { date, unread, message }

class _ChatTimelineEntry {
  const _ChatTimelineEntry._({required this.type, this.label, this.message});

  const _ChatTimelineEntry.date(String label)
    : this._(type: _ChatTimelineType.date, label: label);
  const _ChatTimelineEntry.unread(String label)
    : this._(type: _ChatTimelineType.unread, label: label);
  const _ChatTimelineEntry.message(ChatMessage message)
    : this._(type: _ChatTimelineType.message, message: message);

  final _ChatTimelineType type;
  final String? label;
  final ChatMessage? message;
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            message.message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final alignment = message.isMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.isMe
        ? AppColors.teal
        : Colors.white.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (!message.isMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Text(
              message.sender,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ),
        Row(
          mainAxisAlignment: message.isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMe)
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.ink, AppColors.teal],
                  ),
                ),
              ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isMe ? 18 : 6),
                      bottomRight: Radius.circular(message.isMe ? 6 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.replyTo != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message.replyTo!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (message.attachment != null) ...[
                        if (_isImageAttachment(message.attachment!)) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _attachmentUrl(message.attachment!),
                              height: 170,
                              width: 170,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 90,
                                    width: 170,
                                    alignment: Alignment.center,
                                    color: Colors.black.withValues(alpha: 0.08),
                                    child: const Text('Görsel yüklenemedi'),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else ...[
                          const TagBadge(
                            label: 'Ek dosya',
                            variant: TagBadgeVariant.unread,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _attachmentLabel(message.attachment!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                      if (message.message.trim().isNotEmpty) ...[
                        SelectableText(
                          message.message,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 14.5,
                                height: 1.2,
                                color: message.isMe
                                    ? Colors.white
                                    : AppColors.ink,
                                fontStyle:
                                    message.message.trim() == 'Bu mesaj silindi'
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.time,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10.5,
                                  color: message.isMe
                                      ? Colors.white70
                                      : AppColors.slate,
                                ),
                          ),
                          if (message.isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              _sendStatusIcon(message.sendStatus),
                              size: 12,
                              color: message.sendStatus == ChatSendStatus.failed
                                  ? AppColors.coral
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                      if (message.sendStatus == ChatSendStatus.failed) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Gönderilemedi',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

IconData _sendStatusIcon(ChatSendStatus status) {
  return switch (status) {
    ChatSendStatus.sending => CupertinoIcons.clock,
    ChatSendStatus.sent => CupertinoIcons.check_mark,
    ChatSendStatus.failed => CupertinoIcons.exclamationmark_circle,
  };
}

String _attachmentLabel(String raw) {
  final path = raw.contains(':') ? raw.split(':').last : raw;
  final normalized = path.replaceAll('\\', '/');
  final segments = normalized.split('/');
  return segments.isNotEmpty ? segments.last : raw;
}

String _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'Dosya';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

bool _isImageAttachment(String raw) {
  final path = raw.contains(':') ? raw.split(':').last : raw;
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.heic') ||
      lower.endsWith('.heif');
}

String _attachmentUrl(String raw) {
  if (!raw.contains(':')) return raw;
  final idx = raw.indexOf(':');
  final bucket = raw.substring(0, idx);
  final path = raw.substring(idx + 1);
  return SupabaseService.client.storage.from(bucket).getPublicUrl(path);
}

class _MessageSearchSheet extends StatefulWidget {
  const _MessageSearchSheet({required this.messages});

  final List<ChatMessage> messages;

  @override
  State<_MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _ForwardMessageSheet extends StatelessWidget {
  const _ForwardMessageSheet({
    required this.currentGroupName,
    required this.groups,
  });

  final String currentGroupName;
  final List<GroupItem> groups;

  @override
  Widget build(BuildContext context) {
    final targets = groups
        .where((group) => group.name != currentGroupName)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: GlassCard(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kime ileteceksin?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (targets.isEmpty)
                Text(
                  'İletilecek başka sohbet bulunamadı.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final group = targets[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: group.color.withValues(alpha: 0.18),
                          child: Icon(
                            group.isDirect
                                ? CupertinoIcons.person_fill
                                : CupertinoIcons.person_3_fill,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        title: Text(group.name),
                        subtitle: Text(group.memberCount),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: () => Navigator.of(context).pop(group),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemCount: targets.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageSearchSheetState extends State<_MessageSearchSheet> {
  final TextEditingController controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.messages
        .where(
          (message) =>
              message.message.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: Column(
            children: [
              TextField(
                controller: controller,
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Mesajlarda ara',
                  prefixIcon: Icon(CupertinoIcons.search),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) => GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filtered[index].message,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${filtered[index].sender} • ${filtered[index].time}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemCount: filtered.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
