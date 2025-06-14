enum ShiftType { day, night, off }

extension ShiftTypeExtension on ShiftType {
  String get code {
    switch (this) {
      case ShiftType.day:
        return 'P';
      case ShiftType.night:
        return 'Y';
      case ShiftType.off:
        return '';
    }
  }

  String get displayName {
    switch (this) {
      case ShiftType.day:
        return 'Päivä';
      case ShiftType.night:
        return 'Yö';
      case ShiftType.off:
        return 'Vapaa';
    }
  }

  String get fullDisplayName {
    switch (this) {
      case ShiftType.day:
        return 'Päivä (P)';
      case ShiftType.night:
        return 'Yö (Y)';
      case ShiftType.off:
        return 'Vapaa';
    }
  }
}

class ShiftAssignment {
  final ShiftType shiftType;
  final String? housing;

  ShiftAssignment({
    required this.shiftType,
    this.housing,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShiftAssignment &&
        other.shiftType == shiftType &&
        other.housing == housing;
  }

  @override
  int get hashCode => shiftType.hashCode ^ housing.hashCode;
}

class MasterClass {
  final String id;
  final String displayName;
  ShiftType shiftType;

  MasterClass({
    required this.id,
    required this.displayName,
    required this.shiftType,
  });

  factory MasterClass.fromJson(Map<String, dynamic> json) {
    return MasterClass(
      id: json['id'],
      displayName: json['display_name'],
      shiftType: ShiftType.values.firstWhere(
        (e) => e.name == json['shift_type'],
        orElse: () => ShiftType.off,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'shift_type': shiftType.name,
    };
  }

  MasterClass copyWith({
    String? id,
    String? displayName,
    ShiftType? shiftType,
  }) {
    return MasterClass(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      shiftType: shiftType ?? this.shiftType,
    );
  }
}

class HousingUnit {
  final String id;
  final String displayName;
  final ShiftType shiftType;
  int maxCapacity;

  HousingUnit({
    required this.id,
    required this.displayName,
    required this.shiftType,
    required this.maxCapacity,
  });

  factory HousingUnit.fromJson(Map<String, dynamic> json) {
    return HousingUnit(
      id: json['id'],
      displayName: json['display_name'],
      shiftType: ShiftType.values.firstWhere(
        (e) => e.name == json['shift_type'],
        orElse: () => ShiftType.off,
      ),
      maxCapacity: json['max_capacity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'shift_type': shiftType.name,
      'max_capacity': maxCapacity,
    };
  }

  HousingUnit copyWith({
    String? id,
    String? displayName,
    ShiftType? shiftType,
    int? maxCapacity,
  }) {
    return HousingUnit(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      shiftType: shiftType ?? this.shiftType,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }
}

class Worker {
  final int? id; // Database ID
  final String name;
  final String profession;
  final String? masterClassId;
  final String? housingId;

  Worker({
    this.id,
    required this.name,
    required this.profession,
    this.masterClassId,
    this.housingId,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'],
      name: json['name'],
      profession: json['profession'],
      masterClassId: json['master_class_id'],
      housingId: json['housing_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profession': profession,
      'master_class_id': masterClassId,
      'housing_id': housingId,
    };
  }

  Worker copyWith({
    int? id,
    String? name,
    String? profession,
    String? masterClassId,
    String? housingId,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      masterClassId: masterClassId ?? this.masterClassId,
      housingId: housingId ?? this.housingId,
    );
  }
}

class ProfessionCapacity {
  final int? id; // Database ID
  final String profession;
  int maxDayCapacity;
  int maxNightCapacity;
  bool availableAtNight;

  ProfessionCapacity({
    this.id,
    required this.profession,
    required this.maxDayCapacity,
    required this.maxNightCapacity,
    required this.availableAtNight,
  });

  factory ProfessionCapacity.fromJson(Map<String, dynamic> json) {
    return ProfessionCapacity(
      id: json['id'],
      profession: json['profession'],
      maxDayCapacity: json['max_day_capacity'],
      maxNightCapacity: json['max_night_capacity'],
      availableAtNight: json['available_at_night'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profession': profession,
      'max_day_capacity': maxDayCapacity,
      'max_night_capacity': maxNightCapacity,
      'available_at_night': availableAtNight,
    };
  }

  ProfessionCapacity copyWith({
    int? id,
    String? profession,
    int? maxDayCapacity,
    int? maxNightCapacity,
    bool? availableAtNight,
  }) {
    return ProfessionCapacity(
      id: id ?? this.id,
      profession: profession ?? this.profession,
      maxDayCapacity: maxDayCapacity ?? this.maxDayCapacity,
      maxNightCapacity: maxNightCapacity ?? this.maxNightCapacity,
      availableAtNight: availableAtNight ?? this.availableAtNight,
    );
  }
}

class Constants {
  static const List<String> professions = [
    'Työnjohtaja',
    'Varu 1',
    'Varu 2',
    'Varu 3',
    'Varu 4',
    'Pasta 1',
    'Pasta 2',
    'Huoltomies',
    'Tarvikeauto',
    'ICT',
    'Pora',
  ];

  static List<ProfessionCapacity> getDefaultProfessionCapacities() {
    return [
      ProfessionCapacity(profession: 'Työnjohtaja', maxDayCapacity: 1, maxNightCapacity: 1, availableAtNight: true),
      ProfessionCapacity(profession: 'Varu 1', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Varu 2', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Varu 3', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Varu 4', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Pasta 1', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Pasta 2', maxDayCapacity: 2, maxNightCapacity: 2, availableAtNight: true),
      ProfessionCapacity(profession: 'Huoltomies', maxDayCapacity: -1, maxNightCapacity: 0, availableAtNight: false), // -1 = unlimited
      ProfessionCapacity(profession: 'Tarvikeauto', maxDayCapacity: 1, maxNightCapacity: 1, availableAtNight: true),
      ProfessionCapacity(profession: 'ICT', maxDayCapacity: 2, maxNightCapacity: 0, availableAtNight: false),
      ProfessionCapacity(profession: 'Pora', maxDayCapacity: 1, maxNightCapacity: 0, availableAtNight: false),
    ];
  }

  static const List<String> peopleNames = [
    'Sauli Mustajärvi',
    'Jari Kapraali',
    'Mika Kumpulainen',
    'Eetu Savunen',
    'Ossi Littow',
    'Tomi Peltoniemi',
    'Julius Kasurinen',
    'Esa Vaattovaara',
    'Elias Hauta-Heikkilä',
    'Mikko Korpela',
    'Miikka Ylitalo',
    'Henri Tyrvinen',
    'Morten Labba',
    'Kalle Körkkö',
    'Pekka Puttinen',
    'Eemeli Kirkkala',
    'Janne Haara',
    'Samuli Talgren',
    'Sauli Juntikka',
    'Jarno Haapapuro',
    'Juho Yliportimo',
    'Sami Svenn',
    'Arttu Örn',
    'Juho Keinänen',
    'Marko Keränen',
    'Arttu Lahdenpera',
    'Toni Hannnuniemi',
    'Aleksi Jolma',
    'Hannu Jauhojarvi',
    'Vili Pahkamaa',
    'Jarno Ylipekkala',
    'Tero Kallijarvi',
    'Robert Paivinen',
    'Tiina Romppanen',
    'Anssi Tumelius',
    'Janne Joensuu',
    'Ella-Maria Heikinmatti',
    'Aki Marjetta',
    'Veikka Tikkanen',
    'Viljami Pakanen',
    'Maria Kuronen',
    'Jimmy Arnberg',
    'Ville Seilola',
    'Joni Alakulppi',
    'Tuomo Vanhatapio',
    'Samuli Syvajärvi',
    'Antti Lehto',
    'Mikko Tammiela',
    'Pekka Palosaari',
    'Ville Ojala',
    'Joni Väätäinen',
    'Joona Rissanen',
    'Asko Tammela',
    'Eemeli Körkkö',
    'Niko Kymäläinen',
    'Kaarlo Kyngäs',
    'Kim Bergvall',
    'Jussi Satta',
    'Janne Yrjys',
    'Toni Kortesalmi',
  ];

  static List<MasterClass> getDefaultMasterClasses() {
    return [
      MasterClass(id: 'A', displayName: 'A', shiftType: ShiftType.day),
      MasterClass(id: 'B', displayName: 'B', shiftType: ShiftType.night),
      MasterClass(id: 'C', displayName: 'C', shiftType: ShiftType.day),
      MasterClass(id: 'D', displayName: 'D', shiftType: ShiftType.night),
    ];
  }

  static List<HousingUnit> getDefaultHousingUnits() {
    return [
      HousingUnit(id: 'eta-a-day', displayName: 'Etelärakka A', shiftType: ShiftType.day, maxCapacity: 4),
      HousingUnit(id: 'eta-a-night', displayName: 'Etelärakka A', shiftType: ShiftType.night, maxCapacity: 4),
      HousingUnit(id: 'eta-b-day', displayName: 'Etelärakka B', shiftType: ShiftType.day, maxCapacity: 4),
      HousingUnit(id: 'eta-b-night', displayName: 'Etelärakka B', shiftType: ShiftType.night, maxCapacity: 4),
      HousingUnit(id: 'levi-a-day', displayName: 'Levijärvi A', shiftType: ShiftType.day, maxCapacity: 4),
      HousingUnit(id: 'levi-b-night', displayName: 'Levijärvi B', shiftType: ShiftType.night, maxCapacity: 4),
      HousingUnit(id: 'levi-a', displayName: 'Levijärvi A', shiftType: ShiftType.off, maxCapacity: 4),
    ];
  }

  static ProfessionCapacity? getProfessionCapacity(String profession, List<ProfessionCapacity> capacities) {
    try {
      return capacities.firstWhere((cap) => cap.profession == profession);
    } catch (e) {
      return null;
    }
  }

  static const List<String> weekDays = [
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
  ];
} 