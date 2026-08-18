enum ChildGender { male, female, other }

extension ChildGenderApi on ChildGender {
  String get apiValue => switch (this) {
        ChildGender.male => 'MALE',
        ChildGender.female => 'FEMALE',
        ChildGender.other => 'OTHER',
      };

  String get label => switch (this) {
        ChildGender.male => '남아',
        ChildGender.female => '여아',
        ChildGender.other => '기타',
      };

  static ChildGender? fromApiValue(String? value) => switch (value) {
        'MALE' => ChildGender.male,
        'FEMALE' => ChildGender.female,
        'OTHER' => ChildGender.other,
        _ => null,
      };
}

class Child {
  const Child({
    required this.id,
    required this.nickname,
    required this.gender,
    required this.birthDate,
  });

  final String id;
  final String nickname;
  final ChildGender? gender;
  final DateTime birthDate;

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
  }

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        gender: ChildGenderApi.fromApiValue(json['gender'] as String?),
        birthDate: DateTime.parse(json['birthDate'] as String),
      );
}
