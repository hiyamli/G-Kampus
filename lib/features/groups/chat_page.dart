import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
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
  String? replyTo;
  String? pendingAttachment;

  @override
  void initState() {
    super.initState();
    messages = List.of(
      appRepository.conversationMessages[widget.group.name] ??
          appRepository.chatMessages,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
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
    scrollController.animateTo(
      scrollController.position.maxScrollExtent + 140,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _setAttachment(String value) {
    setState(() => pendingAttachment = value);
  }

  void _openDetails() {
    if (widget.group.isDirect) {
      Navigator.of(context).push(
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

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupInfoPage(group: widget.group)),
    );
  }

  void _searchMessages() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MessageSearchSheet(messages: messages),
    );
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty && pendingAttachment == null) return;

    final message = ChatMessage(
      sender: 'Zeynep',
      message: text.isEmpty ? 'Ek dosya paylasildi.' : text,
      time: TimeOfDay.now().format(context),
      isMe: true,
      replyTo: replyTo,
      attachment: pendingAttachment,
    );

    setState(() {
      messages = [...messages, message];
      appRepository.conversationMessages[widget.group.name] =
          List<ChatMessage>.from(messages);
      messageController.clear();
      replyTo = null;
      pendingAttachment = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _showMessageActions(
    LongPressStartDetails details,
    ChatMessage message,
  ) async {
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
      items: const [
        PopupMenuItem(value: 'reply', child: Text('Mesaj Cevapla')),
        PopupMenuItem(value: 'forward', child: Text('Mesaj İlet')),
      ],
    );

    if (selected == 'reply') {
      setState(() => replyTo = message.message);
    }
    if (selected == 'forward' && mounted) {
      await _showForwardSheet(message);
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

    final forwarded = ChatMessage(
      sender: 'Zeynep',
      message: sourceMessage.message,
      time: TimeOfDay.now().format(context),
      isMe: true,
      attachment: sourceMessage.attachment,
    );

    final existing =
        appRepository.conversationMessages[target.name] ?? <ChatMessage>[];
    appRepository.conversationMessages[target.name] = [...existing, forwarded];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mesaj ${target.name} sohbetine iletildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      body: Column(
        children: [
          const SizedBox(height: 28),
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.group.color, AppColors.ink],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.group.isDirect
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.person_3_fill,
                    color: Colors.white,
                  ),
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.group.memberCount,
                          style: Theme.of(context).textTheme.bodyMedium,
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
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 18),
              itemBuilder: (context, index) {
                final message = messages[index];
                if (message.isSystem) {
                  return _MessageBubble(message: message);
                }
                return GestureDetector(
                  onLongPressStart: (details) =>
                      _showMessageActions(details, message),
                  child: _MessageBubble(message: message),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: messages.length,
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        const Icon(CupertinoIcons.reply, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            replyTo != null
                                ? 'Reply: $replyTo'
                                : 'Ek: $pendingAttachment',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            replyTo = null;
                            pendingAttachment = null;
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
                      onTap: () => _setAttachment('meeting_notes.pdf'),
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
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _setAttachment('campus_photo.png'),
                              icon: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 18,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Mesaj',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
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
                      width: 42,
                      height: 42,
                      child: FloatingActionButton(
                        heroTag: null,
                        elevation: 0,
                        onPressed: _sendMessage,
                        child: const Icon(CupertinoIcons.arrow_up, size: 18),
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
              style: Theme.of(context).textTheme.bodySmall,
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
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.ink, AppColors.teal],
                  ),
                ),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyTo != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.replyTo!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message.attachment != null) ...[
                      const TagBadge(
                        label: 'Ek dosya',
                        variant: TagBadgeVariant.unread,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.attachment!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: message.isMe ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.time,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: message.isMe ? Colors.white70 : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
