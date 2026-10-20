import 'dart:convert';
import 'package:uth_flow/core/storage/moodle_token_manager.dart';

class ScheduleModel {
  final String tenMonHoc;
  final String? maHocPhan;
  final String? maMonHoc;
  final String? tenPhong;
  final String? timeToDisplay;
  final int? tietBatDau;
  final int? soTiet;
  final int? denTiet;
  final String? ghiChu;
  final String? ngayHoc;
  final String? giangVien;
  final String? link;
  final String? coSo;
  final String? outLineDescription;
  final bool isTamNgung;
  final String? tuGio;
  final String? denGio;
  final bool haveOutlineFile;
  final Map<String, dynamic>? rawJson;

  const ScheduleModel({
    required this.tenMonHoc,
    this.maHocPhan,
    this.maMonHoc,
    this.tenPhong,
    this.timeToDisplay,
    this.tietBatDau,
    this.soTiet,
    this.denTiet,
    this.ghiChu,
    this.ngayHoc,
    this.giangVien,
    this.link,
    this.coSo,
    this.outLineDescription,
    this.isTamNgung = false,
    this.tuGio,
    this.denGio,
    this.haveOutlineFile = false,
    this.rawJson,
  });

  ScheduleModel copyWith({
    String? tenMonHoc,
    String? maHocPhan,
    String? maMonHoc,
    String? tenPhong,
    String? timeToDisplay,
    int? tietBatDau,
    int? soTiet,
    int? denTiet,
    String? ghiChu,
    String? ngayHoc,
    String? giangVien,
    String? link,
    String? coSo,
    String? outLineDescription,
    bool? isTamNgung,
    String? tuGio,
    String? denGio,
    bool? haveOutlineFile,
    Map<String, dynamic>? rawJson,
  }) {
    return ScheduleModel(
      tenMonHoc: tenMonHoc ?? this.tenMonHoc,
      maHocPhan: maHocPhan ?? this.maHocPhan,
      maMonHoc: maMonHoc ?? this.maMonHoc,
      tenPhong: tenPhong ?? this.tenPhong,
      timeToDisplay: timeToDisplay ?? this.timeToDisplay,
      tietBatDau: tietBatDau ?? this.tietBatDau,
      soTiet: soTiet ?? this.soTiet,
      denTiet: denTiet ?? this.denTiet,
      ghiChu: ghiChu ?? this.ghiChu,
      ngayHoc: ngayHoc ?? this.ngayHoc,
      giangVien: giangVien ?? this.giangVien,
      link: link ?? this.link,
      coSo: coSo ?? this.coSo,
      outLineDescription: outLineDescription ?? this.outLineDescription,
      isTamNgung: isTamNgung ?? this.isTamNgung,
      tuGio: tuGio ?? this.tuGio,
      denGio: denGio ?? this.denGio,
      haveOutlineFile: haveOutlineFile ?? this.haveOutlineFile,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  /// Kiểm tra xem môn học này có đang ở trạng thái "Đang sắp xếp" hay không
  bool get isArranging {
    final name = tenMonHoc.trim().toLowerCase();
    return name.isEmpty ||
        name == 'môn học' ||
        name == 'đang sắp xếp' ||
        name.contains('đang sắp xếp');
  }

  String get displayName => isArranging ? 'Đang sắp xếp' : tenMonHoc;

  String? get courseCode {
    if (maHocPhan != null &&
        maHocPhan!.trim().isNotEmpty &&
        maHocPhan != 'UTH') {
      return maHocPhan!.trim();
    }
    if (maMonHoc != null &&
        maMonHoc!.trim().isNotEmpty &&
        maMonHoc != 'UTH') {
      return maMonHoc!.trim();
    }
    return null;
  }

  /// Đường dẫn trực tiếp đến trang môn học trên hệ thống LMS UTH (courses.ut.edu.vn)
  /// Ưu tiên đường dẫn trực tiếp chứa SSO Token được trả về từ API /lichhoc/lichNgay
  String get courseLmsUrl {
    return MoodleTokenManager.buildCourseUrl(
      courseCode: courseCode,
      subjectName: displayName,
      fallbackDirectUrl: link,
    );
  }

  String get roomDisplay {
    final room = (tenPhong ?? '').trim();
    if (room.isEmpty ||
        room == 'Chưa xếp phòng' ||
        room.contains('Chưa xếp phòng') ||
        room == 'Đang sắp xếp phòng') {
      return 'Đang sắp xếp phòng';
    }
    return room;
  }

  String get roomWithCampus {
    final room = roomDisplay;
    final campus = (coSo ?? '').trim();
    if (campus.isNotEmpty && !room.contains(campus)) {
      return '$room ($campus)';
    }
    return room;
  }

  String get periodDisplay {
    final time = (timeToDisplay ?? '').trim();
    if (tietBatDau != null && soTiet != null) {
      final tietKetThuc = tietBatDau! + soTiet! - 1;
      if (time.isEmpty || time == 'Đang sắp xếp' || time == 'Chưa rõ ca học') {
        return 'Tiết $tietBatDau - $tietKetThuc';
      }
      return '$time (Tiết $tietBatDau - $tietKetThuc)'.trim();
    }
    if (time.isEmpty || time == 'Chưa rõ ca học') {
      return 'Đang sắp xếp';
    }
    return time;
  }

  DateTime? get parsedDate {
    if (ngayHoc == null || ngayHoc!.isEmpty) return null;
    try {
      final clean = ngayHoc!.trim().split(' ').first.split('T').first;
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // yyyy-mm-dd
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            // dd-mm-yyyy
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      } else if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // yyyy/mm/dd
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            // dd/mm/yyyy
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }
      return DateTime.tryParse(ngayHoc!);
    } catch (_) {}
    return null;
  }

  /// Kiểm tra ca học có trùng với ngày cụ thể không (khớp date)
  bool matchesDate(DateTime date) {
    final pDate = parsedDate;
    if (pDate != null) {
      return pDate.year == date.year &&
          pDate.month == date.month &&
          pDate.day == date.day;
    }
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final d = date.day.toString();
    final m = date.month.toString();
    final yyyy = date.year.toString();

    final dStr = (ngayHoc ?? '').trim();
    if (dStr.isNotEmpty) {
      if (dStr.contains('$dd/$mm/$yyyy') ||
          dStr.contains('$yyyy-$mm-$dd') ||
          dStr.contains('$yyyy/$mm/$dd') ||
          dStr.contains('$dd-$mm-$yyyy') ||
          dStr.contains('$d/$m/$yyyy') ||
          dStr.contains('$dd/$m/$yyyy') ||
          dStr.contains('$d/$mm/$yyyy') ||
          dStr.contains('$yyyy-$m-$d') ||
          dStr.contains('$yyyy-$mm-$d') ||
          dStr.contains('$yyyy-$m-$dd')) {
        return true;
      }
    }
    if (rawJson != null) {
      final jsonStr = jsonEncode(rawJson);
      if (jsonStr.contains('$dd/$mm/$yyyy') ||
          jsonStr.contains('$yyyy-$mm-$dd') ||
          jsonStr.contains('$yyyy/$mm/$dd') ||
          jsonStr.contains('$dd-$mm-$yyyy') ||
          jsonStr.contains('$d/$m/$yyyy') ||
          jsonStr.contains('$dd/$m/$yyyy') ||
          jsonStr.contains('$d/$mm/$yyyy') ||
          jsonStr.contains('$yyyy-$m-$d') ||
          jsonStr.contains('$yyyy-$mm-$d') ||
          jsonStr.contains('$yyyy-$m-$dd')) {
        return true;
      }
    }
    return false;
  }

  bool get isToday {
    final pDate = parsedDate;
    if (pDate == null) return false;
    final now = DateTime.now();
    return pDate.year == now.year &&
        pDate.month == now.month &&
        pDate.day == now.day;
  }

  bool get isTomorrow {
    final pDate = parsedDate;
    if (pDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return pDate.year == tomorrow.year &&
        pDate.month == tomorrow.month &&
        pDate.day == tomorrow.day;
  }

  /// Nhãn hiển thị ngày theo định dạng: "T2, 13/6" hoặc "CN, 14/6"
  String get dateLabelShort {
    final pDate = parsedDate;
    if (pDate == null) return '';
    final weekdayStr = switch (pDate.weekday) {
      DateTime.monday => 'T2',
      DateTime.tuesday => 'T3',
      DateTime.wednesday => 'T4',
      DateTime.thursday => 'T5',
      DateTime.friday => 'T6',
      DateTime.saturday => 'T7',
      DateTime.sunday => 'CN',
      _ => '',
    };
    return '$weekdayStr, ${pDate.day}/${pDate.month}';
  }

  bool get isElearning {
    final room = (tenPhong ?? '').toLowerCase();
    final note = (ghiChu ?? '').toLowerCase();
    final name = tenMonHoc.toLowerCase();
    return room.contains('e-learning') ||
        room.contains('elearning') ||
        room.contains('online') ||
        room.contains('trực tuyến') ||
        note.contains('e-learning') ||
        note.contains('elearning') ||
        name.contains('e-learning') ||
        name.contains('elearning');
  }

  bool get hasDefiniteEndTime {
    if (timeToDisplay == null || !timeToDisplay!.contains('-')) return false;
    final parts = timeToDisplay!.split('-');
    if (parts.length != 2) return false;
    final startStr = parts[0].trim();
    final endStr = parts[1].trim();
    if (endStr.isEmpty || startStr == endStr) return false;
    final endParts = endStr.split(':');
    if (endParts.length != 2) return false;
    return true;
  }

  String get startTime {
    if (timeToDisplay != null && timeToDisplay!.contains('-')) {
      final s = timeToDisplay!.split('-').first.trim();
      if (s.isNotEmpty) return s;
    }
    if (timeToDisplay != null && timeToDisplay!.isNotEmpty) {
      return timeToDisplay!.trim();
    }
    return '--:--';
  }

  DateTime get classDateTime {
    final now = DateTime.now();
    final baseDate = parsedDate ?? now;
    int hour = 0;
    int minute = 0;
    try {
      final sTime = startTime;
      final parts = sTime.split(':');
      if (parts.length >= 2) {
        hour = int.parse(parts[0].trim());
        minute = int.parse(parts[1].trim());
      }
    } catch (_) {}
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  bool get isLive {
    if (isFinished) return false;
    if (!isToday) return false;

    final now = DateTime.now();

    // Đối với E-learning không có giờ kết thúc xác định:
    // Hiển thị đang diễn ra nếu hiện tại đã sau giờ bắt đầu
    if (isElearning && !hasDefiniteEndTime) {
      try {
        final startParts = startTime.split(':');
        if (startParts.length == 2) {
          final start = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]),
          );
          return now.isAfter(start);
        }
      } catch (_) {}
      return false;
    }

    if (!hasDefiniteEndTime) return false;

    try {
      final parts = timeToDisplay!.split('-');
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      final start = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  bool get isFinished {
    final now = DateTime.now();
    final pDate = parsedDate;

    if (pDate != null) {
      final classDateOnly = DateTime(pDate.year, pDate.month, pDate.day);
      final todayDateOnly = DateTime(now.year, now.month, now.day);

      // Nếu ngày của ca học là ngày trong quá khứ -> Đã kết thúc
      if (classDateOnly.isBefore(todayDateOnly)) {
        return true;
      }
      // Nếu ca học là của ngày tương lai (ngày mai, 2 ngày sau, v.v.) -> Chưa kết thúc
      if (classDateOnly.isAfter(todayDateOnly)) {
        return false;
      }
    } else {
      // Chưa rõ ngày học -> không coi là đã kết thúc
      return false;
    }

    // Các ca trong ngày hôm nay:
    // Nếu là E-learning có thời gian bắt đầu nhưng không có kết thúc:
    // Giữ hiển thị cả ngày, không coi là kết thúc trong hôm nay.
    // Đến ngày hôm sau (bắt đầu khóa mới) thì classDateOnly.isBefore(todayDateOnly) sẽ tự kết thúc.
    if (isElearning && !hasDefiniteEndTime) {
      return false;
    }

    // Nếu không có thời gian kết thúc xác định -> không coi là đã kết thúc trong ngày
    if (!hasDefiniteEndTime) return false;

    try {
      final parts = timeToDisplay!.split('-');
      final endParts = parts[1].trim().split(':');

      final end = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      return now.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'tenMonHoc': tenMonHoc,
        'maHocPhan': maHocPhan,
        'maMonHoc': maMonHoc,
        'tenPhong': tenPhong,
        'timeToDisplay': timeToDisplay,
        'tietBatDau': tietBatDau,
        'soTiet': soTiet,
        'denTiet': denTiet,
        'ghiChu': ghiChu,
        'ngayHoc': ngayHoc,
        'giangVien': giangVien,
        'link': link,
        'coSo': coSo,
        'outLineDescription': outLineDescription,
        'isTamNgung': isTamNgung,
        'tuGio': tuGio,
        'denGio': denGio,
        'haveOutlineFile': haveOutlineFile,
      };

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    // 1. Tên môn học
    final rawName = json['tenMonHoc'] ??
        json['nameToDisplay'] ??
        json['ten_mon_hoc'] ??
        json['tenHocPhan'] ??
        json['ten_hoc_phan'] ??
        json['lopHocPhan'] ??
        json['tenLopHocPhan'] ??
        json['tenMon'] ??
        json['ten_mon'] ??
        json['subject'] ??
        json['subjectName'] ??
        json['courseName'] ??
        json['name'] ??
        json['title'];
    final strName = rawName?.toString().trim() ?? '';
    final tenMonHoc = (strName.isNotEmpty && strName != 'Môn học')
        ? strName
        : 'Đang sắp xếp';

    // 2. Mã lớp / Mã học phần
    final rawCode = json['maLopHocPhan'] ??
        json['maHocPhan'] ??
        json['ma_hoc_phan'] ??
        json['ma_lop_hoc_phan'] ??
        json['maLop'] ??
        json['ma_lop'] ??
        json['maMonHoc'] ??
        json['ma_mon_hoc'] ??
        json['maMon'] ??
        json['code'] ??
        json['courseCode'];
    final strCode = rawCode?.toString().trim() ?? '';
    final maHocPhan = (strCode.isNotEmpty && strCode != 'UTH')
        ? strCode
        : null;

    // 3. Phòng học
    final rawRoom = json['roomToDisplay'] ??
        json['tenPhong'] ??
        json['ten_phong'] ??
        json['phongHoc'] ??
        json['tenPhongHoc'] ??
        json['phong'] ??
        json['room'] ??
        json['roomName'];
    final strRoom = rawRoom?.toString().trim() ?? '';
    final tenPhong = (strRoom.isNotEmpty && strRoom != 'Chưa xếp phòng')
        ? strRoom
        : 'Đang sắp xếp phòng';

    // 4. Giờ học / Tiết học
    final tuGioStr = json['tuGio']?.toString().trim();
    final denGioStr = json['denGio']?.toString().trim();
    final rawTime = json['timeToDisplay'] ??
        (tuGioStr != null && denGioStr != null && tuGioStr.isNotEmpty && denGioStr.isNotEmpty
            ? '$tuGioStr - $denGioStr'
            : null) ??
        json['thoiGian'] ??
        json['thoi_gian'] ??
        json['gioHoc'] ??
        json['gio_hoc'] ??
        json['caHoc'] ??
        json['ca_hoc'] ??
        json['tietHoc'] ??
        json['thoiGianHoc'] ??
        json['time'];
    final strTime = rawTime?.toString().trim() ?? '';
    final timeToDisplay = (strTime.isNotEmpty && strTime != 'Chưa rõ ca học')
        ? strTime
        : 'Đang sắp xếp';

    // 5. Tiết bắt đầu & Số tiết
    int? tietBatDau = json['tuTiet'] is int
        ? json['tuTiet'] as int
        : int.tryParse(json['tuTiet']?.toString() ?? '');
    tietBatDau ??= json['tietBatDau'] is int
        ? json['tietBatDau'] as int
        : int.tryParse(json['tietBatDau']?.toString() ?? '');

    final denTiet = json['denTiet'] is int
        ? json['denTiet'] as int
        : int.tryParse(json['denTiet']?.toString() ?? '');

    int? soTiet = json['soTiet'] is int
        ? json['soTiet'] as int
        : int.tryParse(json['soTiet']?.toString() ?? '');
    if (soTiet == null && tietBatDau != null && denTiet != null && denTiet >= tietBatDau) {
      soTiet = denTiet - tietBatDau + 1;
    }

    // 6. Link trực tiếp LMS (kèm SSO JWT token từ API UTH Portal)
    final rawLink = json['link'] ??
        json['url'] ??
        json['lmsUrl'] ??
        json['linkLms'] ??
        json['courseUrl'];
    final strLink = rawLink?.toString().trim();
    final link = (strLink != null && strLink.isNotEmpty) ? strLink : null;

    if (link != null) {
      MoodleTokenManager.updateFromUrl(link);
    }

    // 7. Ngày học
    final rawDate = json['ngayHoc'] ??
        json['ngay'] ??
        json['date'] ??
        json['timeStart'] ??
        json['ngayBatDau'] ??
        json['ngayDay'] ??
        json['ngay_day'] ??
        json['ngay_hoc'] ??
        json['thoiGianHoc'] ??
        json['thoiGian'] ??
        json['thoi_gian'] ??
        json['studyDate'] ??
        json['startDate'] ??
        json['start_time'] ??
        json['start'] ??
        json['ngayHocDuKien'];

    return ScheduleModel(
      tenMonHoc: tenMonHoc,
      maHocPhan: maHocPhan,
      maMonHoc: json['maMonHoc']?.toString(),
      tenPhong: tenPhong,
      timeToDisplay: timeToDisplay,
      tietBatDau: tietBatDau,
      soTiet: soTiet,
      denTiet: denTiet,
      ghiChu: json['noteToDisplay']?.toString() ??
          json['ghiChu']?.toString() ??
          json['ghi_chu']?.toString(),
      ngayHoc: rawDate?.toString(),
      giangVien: json['tenGiangVien']?.toString() ??
          json['giangVien']?.toString() ??
          json['giang_vien']?.toString(),
      link: link,
      coSo: json['coSoToDisplay']?.toString() ?? json['coSo']?.toString(),
      outLineDescription: json['outLineDescription']?.toString() ??
          json['outlineDescription']?.toString() ??
          json['moTaMonHoc']?.toString(),
      isTamNgung: json['isTamNgung'] == true,
      tuGio: tuGioStr,
      denGio: denGioStr,
      haveOutlineFile: json['haveOutlineFile'] == true,
      rawJson: json,
    );
  }
}

/// Môn học tóm tắt trong một ngày từ API lịch tháng (/lichhoc/thang)
class MonthScheduleSubject {
  final String name;
  final String nameToDisplay;
  final String? color;

  const MonthScheduleSubject({
    required this.name,
    required this.nameToDisplay,
    this.color,
  });

  factory MonthScheduleSubject.fromJson(Map<String, dynamic> json) {
    return MonthScheduleSubject(
      name: json['name']?.toString() ?? '',
      nameToDisplay: json['nameToDisplay']?.toString() ??
          json['name']?.toString() ??
          '',
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameToDisplay': nameToDisplay,
        'color': color,
      };
}

/// Dữ liệu tóm tắt lịch học của 1 ngày trong tháng từ API /lichhoc/thang
class MonthScheduleDay {
  final String date; // dd/MM/yyyy hoặc yyyy-MM-dd
  final int total;
  final List<MonthScheduleSubject> subjects;

  const MonthScheduleDay({
    required this.date,
    required this.total,
    this.subjects = const [],
  });

  factory MonthScheduleDay.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subjects'];
    final List<MonthScheduleSubject> subs = [];
    if (rawSubs is List) {
      for (final s in rawSubs) {
        if (s is Map) {
          subs.add(
            MonthScheduleSubject.fromJson(Map<String, dynamic>.from(s)),
          );
        }
      }
    }

    final totalVal = json['total'] is int
        ? json['total'] as int
        : int.tryParse(json['total']?.toString() ?? '') ?? subs.length;

    return MonthScheduleDay(
      date: json['date']?.toString() ?? '',
      total: totalVal,
      subjects: subs,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'total': total,
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  DateTime? get parsedDate {
    if (date.isEmpty) return null;
    try {
      final clean = date.trim().split(' ').first;
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } else if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  bool matchesDate(DateTime target) {
    final pDate = parsedDate;
    if (pDate != null) {
      return pDate.year == target.year &&
          pDate.month == target.month &&
          pDate.day == target.day;
    }
    final dd = target.day.toString().padLeft(2, '0');
    final mm = target.month.toString().padLeft(2, '0');
    final yyyy = target.year.toString();
    final d = target.day.toString();
    final m = target.month.toString();
    return date.contains('$dd/$mm/$yyyy') ||
        date.contains('$d/$m/$yyyy') ||
        date.contains('$yyyy-$mm-$dd');
  }
}
