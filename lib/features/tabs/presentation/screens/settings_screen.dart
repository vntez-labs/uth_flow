import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/academic/presentation/controllers/academic_controller.dart';
import 'package:uth_flow/features/academic/presentation/widgets/course_classes_table.dart';
import 'package:uth_flow/features/academic/presentation/widgets/gpa_overview_card.dart';
import 'package:uth_flow/features/academic/presentation/widgets/grades_bar_chart.dart';
import 'package:uth_flow/features/academic/presentation/widgets/progress_donut_chart.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/auth/presentation/widgets/account_switcher_sheet.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/profile_info_card.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/user_profile_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
          style: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Hủy',
              style: GoogleFonts.beVietnamPro(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final user = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);

    // Dữ liệu học tập & điểm số
    final progressAsync = ref.watch(academicProgressProvider);
    final semestersAsync = ref.watch(academicSemestersProvider);
    final coursesAsync = ref.watch(academicCoursesProvider);
    final selectedSemesterId = ref.watch(selectedSemesterProvider);

    final semGpa = ref.watch(semesterGpaProvider);
    final cumGpaAsync = ref.watch(cumulativeGpaProvider);
    final cumGpa = cumGpaAsync.asData?.value ??
        const (
          gpa4: 2.80,
          gpa10: 7.16,
          credits: 32,
          rank: 'Khá',
        );

    final semesters = semestersAsync.asData?.value ??
        const [
          Semester(id: 101, tenDot: 'Học kỳ 2 năm học 2025-2026'),
          Semester(id: 102, tenDot: 'Học kỳ 1 năm học 2026-2027'),
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ sinh viên',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chuyển / Thêm tài khoản',
            icon: const Icon(SolarIconsBold.usersGroupRounded, size: 22),
            onPressed: () => AccountSwitcherSheet.show(context),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(
              SolarIconsBold.logout_2,
              size: 22,
              color: Color(0xFFFF4757),
            ),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(academicProgressProvider);
          ref.invalidate(academicSemestersProvider);
          ref.invalidate(academicCoursesProvider);
          ref.invalidate(cumulativeGpaProvider);
          ref.invalidate(currentUserProvider);
          await ref.read(academicProgressProvider.future);
          await ref.read(academicCoursesProvider.future);
          await ref.read(cumulativeGpaProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. THẺ THÔNG TIN CHÍNH
              UserProfileCard(
                user: user,
                isDark: isDark,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 18),

              // 2. TỔNG QUAN GPA
              GpaOverviewCard(
                cumGpa: cumGpa,
                semGpa: semGpa,
                isDark: isDark,
              ),

              const SizedBox(height: 18),

              // 3. TIẾN ĐỘ HỌC TẬP (DONUT CHART)
              progressAsync.when(
                data: (progress) => ProgressDonutChart(progress: progress),
                loading: () => const ProgressDonutChart(
                  progress: AcademicProgress.fallback,
                ),
                error: (err, stack) => const ProgressDonutChart(
                  progress: AcademicProgress.fallback,
                ),
              ),

              const SizedBox(height: 18),

              // 4. KẾT QUẢ HỌC TẬP (BAR CHART THANG 0-10)
              _buildGradesSection(
                ref,
                semesters,
                coursesAsync,
                selectedSemesterId,
                semGpa,
              ),

              const SizedBox(height: 18),

              // 5. LỚP HỌC PHẦN (TABLE)
              _buildClassesSection(
                ref,
                semesters,
                coursesAsync,
                selectedSemesterId,
              ),

              const SizedBox(height: 20),

              // 6. THẺ THÔNG TIN ĐÀO TẠO
              ProfileInfoCard(
                title: 'Thông tin đào tạo',
                isDark: isDark,
                items: [
                  ProfileRowItem(
                    icon: SolarIconsOutline.buildings,
                    label: 'Khoa / Viện',
                    value: user?.khoa ?? 'Công nghệ Thông tin',
                  ),
                  ProfileRowItem(
                    icon: SolarIconsOutline.diploma,
                    label: 'Ngành học',
                    value: user?.nganh ?? 'Công nghệ Thông tin',
                  ),
                  if (user?.chuyenNganh != null &&
                      user!.chuyenNganh!.isNotEmpty)
                    ProfileRowItem(
                      icon: SolarIconsOutline.book,
                      label: 'Chuyên ngành',
                      value: user.chuyenNganh!,
                    ),
                  if (user?.khoaHoc != null && user!.khoaHoc!.isNotEmpty)
                    ProfileRowItem(
                      icon: SolarIconsOutline.calendarMark,
                      label: 'Khóa học',
                      value: user.khoaHoc!,
                    ),
                  ProfileRowItem(
                    icon: SolarIconsOutline.squareAcademicCap,
                    label: 'Hệ đào tạo',
                    value: user?.studentType ?? 'Đại học - chính quy',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 7. THÔNG TIN CÁ NHÂN
              ProfileInfoCard(
                title: 'Thông tin cá nhân',
                isDark: isDark,
                items: [
                  ProfileRowItem(
                    icon: SolarIconsOutline.calendarDate,
                    label: 'Ngày sinh',
                    value: user?.ngaySinh ?? 'Chưa cập nhật',
                  ),
                  ProfileRowItem(
                    icon: SolarIconsOutline.userHandUp,
                    label: 'Giới tính',
                    value: user?.genderText ?? 'Chưa cập nhật',
                  ),
                  if (user?.soDienThoai != null &&
                      user!.soDienThoai!.isNotEmpty)
                    ProfileRowItem(
                      icon: SolarIconsOutline.phoneCalling,
                      label: 'Số điện thoại',
                      value: user.soDienThoai!,
                    ),
                  if (user?.noiSinh != null && user!.noiSinh!.isNotEmpty)
                    ProfileRowItem(
                      icon: SolarIconsOutline.mapPoint,
                      label: 'Nơi sinh',
                      value: user.noiSinh!,
                    ),
                  ProfileRowItem(
                    icon: SolarIconsOutline.shieldCheck,
                    label: 'Phiên kết nối',
                    value: token != null ? 'Đã liên kết Portal' : 'Chưa có',
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 8. QUẢN LÝ TÀI KHOẢN
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => AccountSwitcherSheet.show(context),
                  icon: const Icon(
                    SolarIconsBold.usersGroupRounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Chuyển / Thêm tài khoản',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 9. NÚT ĐĂNG XUẤT
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(
                    SolarIconsOutline.logout_2,
                    size: 20,
                    color: Color(0xFFFF4757),
                  ),
                  label: Text(
                    'Đăng xuất khỏi thiết bị',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF4757),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor:
                        const Color(0xFFFF4757).withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Đệm đáy tránh bị che bởi thanh điều hướng nổi
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradesSection(
    WidgetRef ref,
    List<Semester> semesters,
    AsyncValue<List<AcademicCourse>> coursesAsync,
    int? selectedSemesterId,
    ({double gpa4, double gpa10, int credits, String rank}) semGpa,
  ) {
    final courses = coursesAsync.asData?.value ??
        const [
          AcademicCourse(
            tenMonHoc: 'Hệ điều hành',
            maHocPhan: 'IT001',
            soTinChi: 3,
            diemTongKet: 4.4,
          ),
          AcademicCourse(
            tenMonHoc: 'Tư duy thiết kế và đổi mới sáng tạo',
            maHocPhan: 'GE002',
            soTinChi: 3,
            diemTongKet: 5.9,
          ),
          AcademicCourse(
            tenMonHoc: 'Quản trị dự án CNTT',
            maHocPhan: 'IT003',
            soTinChi: 3,
            diemTongKet: 6.7,
          ),
          AcademicCourse(
            tenMonHoc: 'Công nghệ phần mềm',
            maHocPhan: 'IT004',
            soTinChi: 3,
            diemTongKet: 7.9,
          ),
          AcademicCourse(
            tenMonHoc: 'Cấu trúc dữ liệu và giải thuật',
            maHocPhan: 'IT005',
            soTinChi: 3,
            diemTongKet: 4.5,
          ),
          AcademicCourse(
            tenMonHoc: 'Lập trình ứng dụng di động',
            maHocPhan: 'IT006',
            soTinChi: 3,
            diemTongKet: 7.3,
          ),
        ];

    return GradesBarChart(
      courses: courses,
      semesters: semesters,
      selectedSemesterId: selectedSemesterId,
      onSemesterChanged: (val) {
        ref.read(selectedSemesterProvider.notifier).select(val);
      },
      semesterGpa: semGpa,
    );
  }

  Widget _buildClassesSection(
    WidgetRef ref,
    List<Semester> semesters,
    AsyncValue<List<AcademicCourse>> coursesAsync,
    int? selectedSemesterId,
  ) {
    final courses = coursesAsync.asData?.value ??
        const [
          AcademicCourse(
            tenMonHoc: 'Hệ điều hành',
            maHocPhan: 'IT001',
            soTinChi: 3,
            diemTongKet: 4.4,
          ),
          AcademicCourse(
            tenMonHoc: 'Tư duy thiết kế và đổi mới sáng tạo',
            maHocPhan: 'GE002',
            soTinChi: 3,
            diemTongKet: 5.9,
          ),
          AcademicCourse(
            tenMonHoc: 'Quản trị dự án CNTT',
            maHocPhan: 'IT003',
            soTinChi: 3,
            diemTongKet: 6.7,
          ),
          AcademicCourse(
            tenMonHoc: 'Công nghệ phần mềm',
            maHocPhan: 'IT004',
            soTinChi: 3,
            diemTongKet: 7.9,
          ),
          AcademicCourse(
            tenMonHoc: 'Cấu trúc dữ liệu và giải thuật',
            maHocPhan: 'IT005',
            soTinChi: 3,
            diemTongKet: 4.5,
          ),
          AcademicCourse(
            tenMonHoc: 'Lập trình ứng dụng di động',
            maHocPhan: 'IT006',
            soTinChi: 3,
            diemTongKet: 7.3,
          ),
        ];

    return CourseClassesTable(
      courses: courses,
      semesters: semesters,
      selectedSemesterId: selectedSemesterId,
      onSemesterChanged: (val) {
        ref.read(selectedSemesterProvider.notifier).select(val);
      },
    );
  }
}
