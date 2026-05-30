import 'package:hive/hive.dart';

import 'package:time_tracker/core/hive/hive_type_ids.dart';

class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    required this.colorCode,
    this.hourlyRate,
  });

  final String id;
  final String name;
  final int colorCode;
  final double? hourlyRate;

  CompanyModel copyWith({
    String? id,
    String? name,
    int? colorCode,
    double? hourlyRate,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorCode: colorCode ?? this.colorCode,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorCode: json['colorCode'] as int,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorCode': colorCode,
      'hourlyRate': hourlyRate,
    };
  }

  @override
  String toString() {
    return 'CompanyModel(id: $id, name: $name, colorCode: $colorCode, hourlyRate: $hourlyRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CompanyModel &&
            other.id == id &&
            other.name == name &&
            other.colorCode == colorCode &&
            other.hourlyRate == hourlyRate);
  }

  @override
  int get hashCode => Object.hash(id, name, colorCode, hourlyRate);
}

class CompanyModelAdapter extends TypeAdapter<CompanyModel> {
  @override
  final int typeId = HiveTypeIds.company;

  @override
  CompanyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorCode: fields[2] as int,
      hourlyRate: (fields[3] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, CompanyModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorCode)
      ..writeByte(3)
      ..write(obj.hourlyRate);
  }
}
