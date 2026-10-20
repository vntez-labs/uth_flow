import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/academic/data/repositories/academic_repository.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/auth/data/repositories/auth_repository.dart';
import 'package:uth_flow/features/auth/data/services/uth_portal_service.dart';
import 'package:uth_flow/features/auth/domain/models/auth_state.dart';
import 'package:uth_flow/features/auth/domain/models/saved_account_model.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/moodle/data/repositories/moodle_repository.dart';
import 'package:uth_flow/features/moodle/data/services/uth_moodle_service.dart';
import 'package:uth_flow/features/schedule/data/repositories/schedule_repository.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';
import 'package:uth_flow/features/tabs/data/repositories/portal_menu_repository.dart';

class FakePortalService extends UthPortalService {
  int getTodayScheduleCalls = 0;
  int getWeeklyScheduleCalls = 0;
  int getMonthlyScheduleCalls = 0;

  List<ScheduleModel> stubDailyClasses = [];
  List<MonthScheduleDay> stubMonthlyDays = [];

  @override
  Future<List<ScheduleModel>> getTodaySchedule(String token, {DateTime? date}) async {
    getTodayScheduleCalls++;
    return stubDailyClasses;
  }

  @override
  Future<List<ScheduleModel>> getWeeklySchedule(String token, {DateTime? date}) async {
    getWeeklyScheduleCalls++;
    return stubDailyClasses;
  }

  @override
  Future<List<MonthScheduleDay>> getMonthlySchedule(String token, {DateTime? date}) async {
    getMonthlyScheduleCalls++;
    return stubMonthlyDays;
  }

  @override
  Future<List<Semester>> getSemesters(String token) async {
    return [
      const Semester(id: 1, tenDot: 'Học kỳ 1 2026-2027'),
    ];
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  AuthState getInitialAuthState() => const AuthState();

  @override
  Future<List<SavedAccount>> getSavedAccounts() async => [];

  @override
  Future<({UserModel user, String token})> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String?> refreshToken() async => 'new_fresh_token';

  @override
  Future<void> removeAccount(String mssv) async {}

  @override
  Future<({UserModel user, String token})> switchAccount(SavedAccount account) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> syncAvatar(String token, UserModel currentUser) async => null;
}

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<({String? username, String? password})> getCredentials() async {
    return (username: null, password: null);
  }
}

void main() {
  group('AcademicRepository', () {
    late AcademicRepository repository;

    setUp(() {
      repository = AcademicRepositoryImpl(
        portalService: FakePortalService(),
        authRepository: FakeAuthRepository(),
      );
    });

    test('calculateSemesterGpa computes weighted averages and rank accurately', () {
      const courses = [
        AcademicCourse(
          tenMonHoc: 'Lập trình di động',
          maHocPhan: 'IT006',
          soTinChi: 3,
          diemTongKet: 8.5, // GPA 4.0: 3.5
        ),
        AcademicCourse(
          tenMonHoc: 'Kiến trúc phần mềm',
          maHocPhan: 'IT007',
          soTinChi: 3,
          diemTongKet: 7.0, // GPA 4.0: 3.0
        ),
      ];

      final gpa = repository.calculateSemesterGpa(courses);

      expect(gpa.credits, 6);
      expect(gpa.gpa10, 7.75);
      expect(gpa.gpa4, 3.5);
      expect(gpa.rank, 'Giỏi');
    });

    test('calculateSemesterGpa handles empty courses list', () {
      final gpa = repository.calculateSemesterGpa([]);
      expect(gpa.credits, 0);
      expect(gpa.gpa4, 0.0);
      expect(gpa.rank, 'Chưa có');
    });

    test('getSemesters returns fallback when token is empty', () async {
      final result = await repository.getSemesters('');
      expect(result, isNotEmpty);
      expect(result, AcademicRepositoryImpl.fallbackSemesters);
    });
  });

  group('ScheduleRepository', () {
    late ScheduleRepository repository;

    setUp(() {
      repository = ScheduleRepositoryImpl(
        portalService: FakePortalService(),
      );
    });

    test('getDailySchedule returns empty DailyScheduleData when token is empty', () async {
      final data = await repository.getDailySchedule('');
      expect(data.todayClasses, isEmpty);
      expect(data.tomorrowClasses, isEmpty);
      expect(data.isTodayFinished, isFalse);
    });

    test('DailyScheduleData sorts upcoming classes chronologically', () {
      final morningClass = ScheduleModel(
        tenMonHoc: 'Môn sáng',
        ngayHoc: '2026-10-20',
        tietBatDau: 1,
        soTiet: 3,
        timeToDisplay: '07:00 - 09:30',
      );
      final afternoonClass = ScheduleModel(
        tenMonHoc: 'Môn chiều',
        ngayHoc: '2026-10-20',
        tietBatDau: 7,
        soTiet: 3,
        timeToDisplay: '13:00 - 15:30',
      );

      final data = DailyScheduleData(
        todayClasses: [afternoonClass, morningClass],
      );

      final upcoming = data.upcomingSchedule;
      expect(upcoming.first.tenMonHoc, 'Môn sáng');
      expect(upcoming.last.tenMonHoc, 'Môn chiều');
    });

    test('ScheduleModel.fromJson correctly parses daily schedule response with direct LMS SSO link', () {
      final userSampleJson = {
        "id": 1460713,
        "tenMonHoc": "Hệ điều hành",
        "isTamNgung": false,
        "tenPhong": "B304 - CS1 (P.Thạnh Mỹ Tây, TP.HCM)",
        "tuTiet": 4,
        "denTiet": 6,
        "tuGio": "09:25",
        "denGio": "11:55",
        "ghiChu": "",
        "maLopHocPhan": "012012500102",
        "maMonHoc": "125001",
        "idMonHocNCT": null,
        "link": "https://courses.ut.edu.vn/course/view.php?idnumber=77012012500102&token=sample_jwt_token_123",
        "nameToDisplay": "Hệ điều hành - 012012500102",
        "roomToDisplay": "B304 - CS1 (P.Thạnh Mỹ Tây, TP.HCM)",
        "timeToDisplay": "09:25 - 11:55",
        "noteToDisplay": "",
        "coSoToDisplay": "Cơ sở 1",
        "haveOutlineFile": true,
        "outLineDescription": "Môn học cung cấp nội dung...",
        "text1": null,
        "text2": null,
        "text3": null,
        "haveBook": false
      };

      final model = ScheduleModel.fromJson(userSampleJson);

      expect(model.tenMonHoc, 'Hệ điều hành');
      expect(model.maHocPhan, '012012500102');
      expect(model.maMonHoc, '125001');
      expect(model.courseCode, '012012500102');
      expect(model.tietBatDau, 4);
      expect(model.soTiet, 3); // 6 - 4 + 1
      expect(model.periodDisplay, '09:25 - 11:55 (Tiết 4 - 6)');
      expect(model.roomDisplay, 'B304 - CS1 (P.Thạnh Mỹ Tây, TP.HCM)');
      expect(model.link, 'https://courses.ut.edu.vn/course/view.php?idnumber=77012012500102&token=sample_jwt_token_123');
      // URL LMS phải là link trực tiếp có token SSO, không redirect sang search.php
      expect(model.courseLmsUrl, 'https://courses.ut.edu.vn/course/view.php?idnumber=77012012500102&token=sample_jwt_token_123');
    });

    test('ScheduleModel.courseLmsUrl uses extracted Moodle SSO token for courses without direct link', () {
      final modelWithoutLink = ScheduleModel(
        tenMonHoc: 'Mạng máy tính',
        maHocPhan: '012012500999',
      );

      // Vì token đã được trích xuất từ bài test trước ('sample_jwt_token_123')
      expect(
        modelWithoutLink.courseLmsUrl,
        'https://courses.ut.edu.vn/course/view.php?idnumber=77012012500999&token=sample_jwt_token_123',
      );
    });

    test('ScheduleModel.matchesDate accurately matches multiple date formats and JSON structures', () {
      final model1 = ScheduleModel(
        tenMonHoc: 'Kiến trúc máy tính',
        ngayHoc: '20/10/2026',
      );
      final model2 = ScheduleModel(
        tenMonHoc: 'Toán rời rạc',
        ngayHoc: '2026-10-20T00:00:00',
      );
      final model3 = ScheduleModel(
        tenMonHoc: 'Lập trình Web',
        rawJson: {
          'studyDate': '20/10/2026 09:25:00',
        },
      );

      final targetDate = DateTime(2026, 10, 20);
      final otherDate = DateTime(2026, 10, 21);

      expect(model1.matchesDate(targetDate), isTrue);
      expect(model1.matchesDate(otherDate), isFalse);

      expect(model2.matchesDate(targetDate), isTrue);
      expect(model2.matchesDate(otherDate), isFalse);

      expect(model3.matchesDate(targetDate), isTrue);
      expect(model3.matchesDate(otherDate), isFalse);
    });

    test('ScheduleModel parses campus, outline description, and suspended status', () {
      final raw = {
        'tenMonHoc': 'Hệ điều hành nâng cao',
        'coSoToDisplay': 'Cơ sở 1',
        'tenPhong': 'B304 - CS1',
        'outLineDescription': 'Mô tả chi tiết đề cương môn học',
        'isTamNgung': true,
      };

      final model = ScheduleModel.fromJson(raw);

      expect(model.coSo, 'Cơ sở 1');
      expect(model.roomDisplay, 'B304 - CS1');
      expect(model.roomWithCampus, 'B304 - CS1 (Cơ sở 1)');
      expect(model.outLineDescription, 'Mô tả chi tiết đề cương môn học');
      expect(model.isTamNgung, isTrue);
    });

    test('MonthScheduleDay parses exact UTH monthly schedule response format', () {
      final json = {
        'date': '31/10/2026',
        'total': 2,
        'subjects': [
          {
            'name': 'Hệ điều hành',
            'nameToDisplay': 'Hệ điều hành',
            'color': '#50E3C2'
          },
          {
            'name': 'Tư duy thiết kế và đổi mới sáng tạo',
            'nameToDisplay': 'Tư duy thiết kế và đổi mới sáng tạo',
            'color': '#4A90E2'
          }
        ]
      };

      final day = MonthScheduleDay.fromJson(json);
      expect(day.date, '31/10/2026');
      expect(day.total, 2);
      expect(day.subjects.length, 2);
      expect(day.subjects[0].name, 'Hệ điều hành');
      expect(day.subjects[0].color, '#50E3C2');
      expect(day.subjects[1].name, 'Tư duy thiết kế và đổi mới sáng tạo');
      expect(day.matchesDate(DateTime(2026, 10, 31)), isTrue);
      expect(day.matchesDate(DateTime(2026, 10, 30)), isFalse);
    });

    test('ScheduleRepositoryImpl caches monthly, weekly, and daily schedules avoiding redundant fetches', () async {
      final fakePortal = FakePortalService();
      final repo = ScheduleRepositoryImpl(portalService: fakePortal);
      repo.clearCache();

      final targetDate = DateTime(2026, 10, 31);
      final emptyDate = DateTime(2026, 10, 20);

      fakePortal.stubMonthlyDays = [
        const MonthScheduleDay(
          date: '31/10/2026',
          total: 2,
          subjects: [
            MonthScheduleSubject(name: 'Hệ điều hành', nameToDisplay: 'Hệ điều hành'),
            MonthScheduleSubject(name: 'Tư duy thiết kế', nameToDisplay: 'Tư duy thiết kế'),
          ],
        ),
      ];

      fakePortal.stubDailyClasses = [
        const ScheduleModel(
          tenMonHoc: 'Hệ điều hành',
          ngayHoc: '31/10/2026',
          link: 'https://courses.ut.edu.vn/course/view.php?idnumber=123',
        ),
      ];

      // 1. Fetch monthly schedule
      final monthResult1 = await repo.getMonthlySchedule('test_token', date: targetDate);
      expect(monthResult1.length, 1);
      expect(fakePortal.getMonthlyScheduleCalls, 1);

      // 2. Fetch monthly schedule again for same month -> must return from cache
      final monthResult2 = await repo.getMonthlySchedule('test_token', date: targetDate);
      expect(monthResult2.length, 1);
      expect(fakePortal.getMonthlyScheduleCalls, 1); // Not incremented

      // 3. Query a date with 0 classes in month cache (20/10/2026) -> must return [] immediately without network
      final emptyResult = await repo.getScheduleByDate('test_token', emptyDate);
      expect(emptyResult, isEmpty);
      expect(fakePortal.getTodayScheduleCalls, 0); // Zero network calls!

      // 4. Query date with classes (31/10/2026) -> fetches once from daily API and caches
      final classes1 = await repo.getScheduleByDate('test_token', targetDate);
      expect(classes1.length, 1);
      expect(fakePortal.getTodayScheduleCalls, 1);

      // 5. Query 31/10/2026 again -> must return from dailyCache immediately
      final classes2 = await repo.getScheduleByDate('test_token', targetDate);
      expect(classes2.length, 1);
      expect(fakePortal.getTodayScheduleCalls, 1); // Still 1! No additional call!
    });
  });

  group('MoodleRepository', () {
    test('throws CHUA_CO_MAT_KHAU when credentials are not available', () async {
      final repository = MoodleRepositoryImpl(
        moodleService: UthMoodleService(),
        secureStorage: FakeSecureStorageService(),
      );

      expect(
        () => repository.getDeadlines(user: null),
        throwsA(predicate((e) => e.toString().contains('CHUA_CO_MAT_KHAU'))),
      );
    });
  });

  group('PortalMenuRepository', () {
    test('returns empty lists when token is empty', () async {
      final repository = PortalMenuRepositoryImpl(
        portalService: FakePortalService(),
      );

      final sideMenu = await repository.getSideMenu('');
      final mainMenu = await repository.getMainMenu('');

      expect(sideMenu, isEmpty);
      expect(mainMenu, isEmpty);
    });
  });
}
