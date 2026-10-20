import 'package:flutter/material.dart';
import 'package:uth_flow/core/storage/moodle_token_manager.dart';

class AcademicProgress {
  final int canDat;
  final int hienTai;

  const AcademicProgress({
    required this.canDat,
    required this.hienTai,
  });

  double get percentage {
    if (canDat <= 0) return 0.0;
    return (hienTai / canDat * 100).clamp(0.0, 100.0);
  }

  factory AcademicProgress.fromJson(Map<String, dynamic> json) {
    return AcademicProgress(
      canDat: (json['canDat'] as num?)?.toInt() ?? 120,
      hienTai: (json['hienTai'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'canDat': canDat,
        'hienTai': hienTai,
      };

  static const fallback = AcademicProgress(
    canDat: 120,
    hienTai: 32,
  );
}

class Semester {
  final int id;
  final String tenDot;

  const Semester({
    required this.id,
    required this.tenDot,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenDot: json['tenDot']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenDot': tenDot,
      };
}

class CourseSubject {
  final String tenMonHoc;
  final String maHocPhan;
  final int soTinChi;

  const CourseSubject({
    required this.tenMonHoc,
    required this.maHocPhan,
    required this.soTinChi,
  });

  factory CourseSubject.fromJson(Map<String, dynamic> json) {
    return CourseSubject(
      tenMonHoc: json['tenMonHoc']?.toString() ?? '',
      maHocPhan: json['maHocPhan']?.toString() ?? '',
      soTinChi: (json['soTinChi'] as num?)?.toInt() ?? 0,
    );
  }
}

class CourseGrade {
  final String lopHocPhan;
  final double? diemTongKet;

  const CourseGrade({
    required this.lopHocPhan,
    this.diemTongKet,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      lopHocPhan: json['lopHocPhan']?.toString() ?? '',
      diemTongKet: (json['diemTongKet'] as num?)?.toDouble(),
    );
  }
}

class AcademicCourse {
  final String tenMonHoc;
  final String maHocPhan;
  final int soTinChi;
  final double? diemTongKet;

  const AcademicCourse({
    required this.tenMonHoc,
    required this.maHocPhan,
    required this.soTinChi,
    this.diemTongKet,
  });

  /// Đường dẫn trực tiếp đến trang môn học trên hệ thống LMS UTH (courses.ut.edu.vn)
  String get courseLmsUrl {
    return MoodleTokenManager.buildCourseUrl(
      courseCode: maHocPhan,
      subjectName: tenMonHoc,
    );
  }

  bool get hasGrade => diemTongKet != null;

  /// Quy đổi điểm hệ 4.0 và xếp loại theo quy chế UTH
  GpaInfo get gpaInfo {
    if (diemTongKet == null) {
      return const GpaInfo(
        gpa4: 0.0,
        letter: '--',
        text: 'Chưa có',
        color: Color(0xFF9E9E9E),
      );
    }
    final score = diemTongKet!;
    if (score >= 8.5) {
      return const GpaInfo(
        gpa4: 4.0,
        letter: 'A',
        text: 'Xuất sắc',
        color: Color(0xFF10B981),
      );
    }
    if (score >= 8.0) {
      return const GpaInfo(
        gpa4: 3.5,
        letter: 'B+',
        text: 'Giỏi',
        color: Color(0xFF2563EB),
      );
    }
    if (score >= 7.0) {
      return const GpaInfo(
        gpa4: 3.0,
        letter: 'B',
        text: 'Khá',
        color: Color(0xFF3B82F6),
      );
    }
    if (score >= 6.5) {
      return const GpaInfo(
        gpa4: 2.5,
        letter: 'C+',
        text: 'TB Khá',
        color: Color(0xFFF59E0B),
      );
    }
    if (score >= 5.5) {
      return const GpaInfo(
        gpa4: 2.0,
        letter: 'C',
        text: 'Trung bình',
        color: Color(0xFFF97316),
      );
    }
    if (score >= 5.0) {
      return const GpaInfo(
        gpa4: 1.5,
        letter: 'D+',
        text: 'TB Yếu',
        color: Color(0xFFEAB308),
      );
    }
    if (score >= 4.0) {
      return const GpaInfo(
        gpa4: 1.0,
        letter: 'D',
        text: 'Yếu',
        color: Color(0xFFCA8A04),
      );
    }
    return const GpaInfo(
      gpa4: 0.0,
      letter: 'F',
      text: 'Kém',
      color: Color(0xFFEF4444),
    );
  }
}

class GpaInfo {
  final double gpa4;
  final String letter;
  final String text;
  final Color color;

  const GpaInfo({
    required this.gpa4,
    required this.letter,
    required this.text,
    required this.color,
  });
}
