import 'package:flutter/material.dart';

enum ScopeType { universite, fakulte, bolum, ders }

ScopeType scopeTypeFromString(String value) {
  return ScopeType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ScopeType.universite,
  );
}

Color colorFromJson(dynamic value) {
  if (value is int) return Color(value);
  if (value is String) {
    var hex = value.trim().toUpperCase();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return const Color(0xFF000000);
}

int colorToJson(Color color) => color.toARGB32();

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.number,
    required this.department,
    required this.grade,
    required this.gpa,
    required this.bio,
    required this.role,
    required this.courseCount,
    required this.notificationsEnabled,
  });

  final String name;
  final String number;
  final String department;
  final String grade;
  final String gpa;
  final String bio;
  final String role;
  final int courseCount;
  final bool notificationsEnabled;

  StudentProfile copyWith({String? bio}) {
    return StudentProfile(
      name: name,
      number: number,
      department: department,
      grade: grade,
      gpa: gpa,
      bio: bio ?? this.bio,
      role: role,
      courseCount: courseCount,
      notificationsEnabled: notificationsEnabled,
    );
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] as String,
      number: json['number'] as String,
      department: json['department'] as String,
      grade: json['grade'] as String,
      gpa: json['gpa'] as String,
      bio: json['bio'] as String,
      role: json['role'] as String,
      courseCount: json['courseCount'] as int,
      notificationsEnabled: json['notificationsEnabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'department': department,
      'grade': grade,
      'gpa': gpa,
      'bio': bio,
      'role': role,
      'courseCount': courseCount,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.course,
    required this.time,
    required this.location,
    required this.instructor,
    required this.color,
    required this.badge,
    required this.credit,
    required this.ects,
    required this.examSummary,
    required this.letter,
  });

  final String course;
  final String time;
  final String location;
  final String instructor;
  final Color color;
  final String badge;
  final String credit;
  final String ects;
  final String examSummary;
  final String letter;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      course: json['course'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      instructor: json['instructor'] as String,
      color: colorFromJson(json['color']),
      badge: json['badge'] as String,
      credit: json['credit'] as String,
      ects: json['ects'] as String,
      examSummary: json['examSummary'] as String,
      letter: json['letter'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'time': time,
      'location': location,
      'instructor': instructor,
      'color': colorToJson(color),
      'badge': badge,
      'credit': credit,
      'ects': ects,
      'examSummary': examSummary,
      'letter': letter,
    };
  }
}

class AssignmentItem {
  const AssignmentItem({
    required this.title,
    required this.course,
    required this.description,
    required this.deadline,
    required this.timeLeft,
    required this.status,
    required this.documentInfo,
    required this.submissionNote,
    required this.isCompleted,
    required this.isOverdue,
  });

  final String title;
  final String course;
  final String description;
  final String deadline;
  final String timeLeft;
  final String status;
  final String? documentInfo;
  final String? submissionNote;
  final bool isCompleted;
  final bool isOverdue;

  AssignmentItem copyWith({
    String? timeLeft,
    String? status,
    String? documentInfo,
    String? submissionNote,
    bool? isCompleted,
    bool? isOverdue,
  }) {
    return AssignmentItem(
      title: title,
      course: course,
      description: description,
      deadline: deadline,
      timeLeft: timeLeft ?? this.timeLeft,
      status: status ?? this.status,
      documentInfo: documentInfo ?? this.documentInfo,
      submissionNote: submissionNote ?? this.submissionNote,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      title: json['title'] as String,
      course: json['course'] as String,
      description: json['description'] as String,
      deadline: json['deadline'] as String,
      timeLeft: json['timeLeft'] as String,
      status: json['status'] as String,
      documentInfo: json['documentInfo'] as String?,
      submissionNote: json['submissionNote'] as String?,
      isCompleted: json['isCompleted'] as bool,
      isOverdue: json['isOverdue'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'course': course,
      'description': description,
      'deadline': deadline,
      'timeLeft': timeLeft,
      'status': status,
      'documentInfo': documentInfo,
      'submissionNote': submissionNote,
      'isCompleted': isCompleted,
      'isOverdue': isOverdue,
    };
  }
}

class AnnouncementItem {
  const AnnouncementItem({
    required this.title,
    required this.description,
    required this.scope,
    required this.date,
    required this.isNew,
  });

  final String title;
  final String description;
  final ScopeType scope;
  final String date;
  final bool isNew;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      title: json['title'] as String,
      description: json['description'] as String,
      scope: scopeTypeFromString(json['scope'] as String),
      date: json['date'] as String,
      isNew: json['isNew'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'scope': scope.name,
      'date': date,
      'isNew': isNew,
    };
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.range,
    required this.color,
  });

  final String title;
  final String range;
  final Color color;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] as String,
      range: json['range'] as String,
      color: colorFromJson(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'range': range, 'color': colorToJson(color)};
  }
}

class GroupItem {
  const GroupItem({
    required this.name,
    required this.memberCount,
    required this.muted,
    required this.color,
    this.avatarIndex = 0,
    this.isDirect = false,
    this.mutedUntil,
  });

  final String name;
  final String memberCount;
  final bool muted;
  final Color color;
  final int avatarIndex;
  final bool isDirect;
  final String? mutedUntil;

  GroupItem copyWith({
    String? name,
    String? memberCount,
    bool? muted,
    int? avatarIndex,
    bool? isDirect,
    String? mutedUntil,
  }) {
    return GroupItem(
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      muted: muted ?? this.muted,
      color: color,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      isDirect: isDirect ?? this.isDirect,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      name: json['name'] as String,
      memberCount: json['memberCount'] as String,
      muted: json['muted'] as bool,
      color: colorFromJson(json['color']),
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      isDirect: json['isDirect'] as bool? ?? false,
      mutedUntil: json['mutedUntil'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'memberCount': memberCount,
      'muted': muted,
      'color': colorToJson(color),
      'avatarIndex': avatarIndex,
      'isDirect': isDirect,
      'mutedUntil': mutedUntil,
    };
  }
}

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.isMe,
    this.replyTo,
    this.attachment,
    this.isSystem = false,
  });

  final String sender;
  final String message;
  final String time;
  final bool isMe;
  final String? replyTo;
  final String? attachment;
  final bool isSystem;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] as String,
      message: json['message'] as String,
      time: json['time'] as String,
      isMe: json['isMe'] as bool,
      replyTo: json['replyTo'] as String?,
      attachment: json['attachment'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'time': time,
      'isMe': isMe,
      'replyTo': replyTo,
      'attachment': attachment,
      'isSystem': isSystem,
    };
  }
}

class StudentOption {
  const StudentOption({
    required this.name,
    required this.number,
    required this.role,
  });

  final String name;
  final String number;
  final String role;

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    return StudentOption(
      name: json['name'] as String,
      number: json['number'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'number': number, 'role': role};
  }
}
