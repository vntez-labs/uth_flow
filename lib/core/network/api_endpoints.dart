class ApiEndpoints {
  static const String portalBaseUrl = 'https://portal.ut.edu.vn/api/v1';
  static const String moodleBaseUrl = 'https://courses.ut.edu.vn';
  static const String paymentBaseUrl = 'https://payment.ut.edu.vn';
  static const String supportBaseUrl = 'https://support.ut.edu.vn';
  static const String thnnBaseUrl = 'https://thnn.ut.edu.vn';

  // Portal user
  static const String userLogin = '$portalBaseUrl/user/login';
  static const String userSummaryProfile = '$portalBaseUrl/user/getSummaryProfile';
  static const String userImageBinary = '$portalBaseUrl/user/imageBinary';

  // Schedule
  static const String scheduleDaily = '$portalBaseUrl/lichhoc/lichNgay';
  static const String scheduleWeekly = '$portalBaseUrl/lichhoc/tuan';
  static const String scheduleMonthly = '$portalBaseUrl/lichhoc/thang';

  // Academic
  static const String academicProgress = '$portalBaseUrl/hoctap/tiendo';
  static const String academicSemesters = '$portalBaseUrl/hoctap/hocky';
  static const String academicCoursesBySemester = '$portalBaseUrl/hoctap/montheoky';
  static const String academicGradesBySemester = '$portalBaseUrl/hoctap/kqtheoky';
  static const String academicTranscript = '$portalBaseUrl/hoctap/bangdiem';

  // Menus
  static const String menuSide = '$portalBaseUrl/menu/sideMenu';
  static const String menuMain = '$portalBaseUrl/menu/mainMenu';

  // Notifications
  static const String notifications = '$portalBaseUrl/notification/getNote';
}
