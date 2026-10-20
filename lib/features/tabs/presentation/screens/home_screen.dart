import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_deadlines_section.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_header_widget.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_schedule_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledPastHeader = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final topPadding = MediaQuery.paddingOf(context).top;
    final threshold = topPadding + 140;
    final isPast =
        _scrollController.hasClients && _scrollController.offset > threshold;
    if (isPast != _isScrolledPastHeader) {
      setState(() {
        _isScrolledPastHeader = isPast;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isScrolledPastHeader
          ? (isDark ? Brightness.light : Brightness.dark)
          : Brightness.light,
      statusBarBrightness: _isScrolledPastHeader
          ? (isDark ? Brightness.dark : Brightness.light)
          : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER (CHỨA THỐNG KÊ NHANH, TỔNG QUAN GPA & TÀI KHOẢN)
                HomeHeaderWidget(),

                SizedBox(height: 24),

                // 2. HÔM NAY (LỊCH HỌC)
                HomeScheduleSection(),

                SizedBox(height: 34),

                // 3. DEADLINE (BÀI TẬP MOODLE)
                HomeDeadlinesSection(),

                // Đệm đáy tránh bị che bởi thanh điều hướng nổi
                SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
