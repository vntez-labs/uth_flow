class UserModel {
  final String mssv;
  final String? hoDem;
  final String? ten;
  final String? email;
  final String? avatarBase64;
  final String? soDienThoai;
  final String? ngaySinh;
  final String? noiSinh;
  final bool? gioiTinh;
  final String? khoa;
  final String? khoaHoc;
  final String? nganh;
  final String? chuyenNganh;
  final String? heDaoTao;
  final String? loaiHinhDt;

  const UserModel({
    required this.mssv,
    this.hoDem,
    this.ten,
    this.email,
    this.avatarBase64,
    this.soDienThoai,
    this.ngaySinh,
    this.noiSinh,
    this.gioiTinh,
    this.khoa,
    this.khoaHoc,
    this.nganh,
    this.chuyenNganh,
    this.heDaoTao,
    this.loaiHinhDt,
  });

  String get fullName {
    if (hoDem != null && ten != null && hoDem!.isNotEmpty && ten!.isNotEmpty) {
      return '$hoDem $ten'.trim();
    }
    if (ten != null && ten!.isNotEmpty) return ten!;
    if (hoDem != null && hoDem!.isNotEmpty) return hoDem!;
    return mssv;
  }

  String get initials {
    if (ten != null && ten!.trim().isNotEmpty) {
      final trimmedTen = ten!.trim();
      if (hoDem != null && hoDem!.trim().isNotEmpty) {
        return '${hoDem!.trim()[0]}${trimmedTen[0]}'.toUpperCase();
      }
      return trimmedTen.substring(0, trimmedTen.length.clamp(1, 2)).toUpperCase();
    }
    return mssv.substring(0, mssv.length.clamp(1, 2)).toUpperCase();
  }

  String get studentType {
    if (heDaoTao != null && heDaoTao!.isNotEmpty) {
      return '$heDaoTao - ${loaiHinhDt ?? 'chính quy'}';
    }
    return 'Đại học - chính quy';
  }

  /// Giới tính hiển thị (Tại UTH, cờ gioiTinh / isFemale: false là Nam, true là Nữ)
  String get genderText {
    if (gioiTinh == null) return 'Chưa cập nhật';
    return gioiTinh == false ? 'Nam' : 'Nữ';
  }

  static bool? _parseGender(dynamic val) {
    if (val == null) return null;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == '0' || s == 'false' || s == 'nam' || s == 'male') return false;
      if (s == '1' || s == 'true' || s == 'nữ' || s == 'female') return true;
    }
    return null;
  }

  UserModel copyWith({
    String? mssv,
    String? hoDem,
    String? ten,
    String? email,
    String? avatarBase64,
    String? soDienThoai,
    String? ngaySinh,
    String? noiSinh,
    bool? gioiTinh,
    String? khoa,
    String? khoaHoc,
    String? nganh,
    String? chuyenNganh,
    String? heDaoTao,
    String? loaiHinhDt,
  }) {
    return UserModel(
      mssv: mssv ?? this.mssv,
      hoDem: hoDem ?? this.hoDem,
      ten: ten ?? this.ten,
      email: email ?? this.email,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      noiSinh: noiSinh ?? this.noiSinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      khoa: khoa ?? this.khoa,
      khoaHoc: khoaHoc ?? this.khoaHoc,
      nganh: nganh ?? this.nganh,
      chuyenNganh: chuyenNganh ?? this.chuyenNganh,
      heDaoTao: heDaoTao ?? this.heDaoTao,
      loaiHinhDt: loaiHinhDt ?? this.loaiHinhDt,
    );
  }

  Map<String, dynamic> toJson() => {
        'mssv': mssv,
        'hoDem': hoDem,
        'ten': ten,
        'email': email,
        'avatarBase64': avatarBase64,
        'soDienThoai': soDienThoai,
        'ngaySinh': ngaySinh,
        'noiSinh': noiSinh,
        'gioiTinh': gioiTinh,
        'khoa': khoa,
        'khoaHoc': khoaHoc,
        'nganh': nganh,
        'chuyenNganh': chuyenNganh,
        'heDaoTao': heDaoTao,
        'loaiHinhDt': loaiHinhDt,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      mssv: json['mssv'] as String? ??
          json['maSinhVien'] as String? ??
          json['maSV'] as String? ??
          json['userName'] as String? ??
          '',
      hoDem: json['hoDem'] as String? ?? json['ho_dem'] as String?,
      ten: json['ten'] as String?,
      email: json['email'] as String?,
      avatarBase64: json['avatarBase64'] as String?,
      soDienThoai: json['soDienThoai'] as String? ?? json['so_dien_thoai'] as String?,
      ngaySinh: json['ngaySinh'] as String? ?? json['ngaySinh2'] as String? ?? json['ngay_sinh'] as String?,
      noiSinh: json['noiSinh'] as String? ?? json['noiSinhTinh'] as String? ?? json['noi_sinh'] as String?,
      gioiTinh: _parseGender(json['gioiTinh'] ?? json['gioi_tinh'] ?? json['isFemale']),
      khoa: json['khoa'] as String?,
      khoaHoc: json['khoaHoc'] as String? ?? json['khoa_hoc'] as String?,
      nganh: json['nganh'] as String?,
      chuyenNganh: json['chuyenNganh'] as String? ?? json['chuyen_nganh'] as String?,
      heDaoTao: json['heDaoTao'] as String? ?? json['he_dao_tao'] as String?,
      loaiHinhDt: json['loaiHinhDt'] as String? ?? json['loaiHinhDT'] as String? ?? json['loai_hinh_dt'] as String?,
    );
  }
}
