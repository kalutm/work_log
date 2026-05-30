import 'package:hive/hive.dart';

import 'package:time_tracker/core/hive/hive_type_ids.dart';

class WorkSessionModel {
  const WorkSessionModel({
    required this.id,
    required this.companyId,
    required this.startTime,
    this.endTime,
    required this.durationInSeconds,
    this.notes,
  });

  final String id;
  final String companyId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationInSeconds;
  final String? notes;

  WorkSessionModel copyWith({
    String? id,
    String? companyId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationInSeconds,
    String? notes,
  }) {
    return WorkSessionModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      notes: notes ?? this.notes,
    );
  }

  factory WorkSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkSessionModel(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationInSeconds: json['durationInSeconds'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationInSeconds': durationInSeconds,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'WorkSessionModel(id: $id, companyId: $companyId, startTime: $startTime, endTime: $endTime, durationInSeconds: $durationInSeconds, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WorkSessionModel &&
            other.id == id &&
            other.companyId == companyId &&
            other.startTime == startTime &&
            other.endTime == endTime &&
            other.durationInSeconds == durationInSeconds &&
            other.notes == notes);
  }

  @override
  int get hashCode =>
      Object.hash(id, companyId, startTime, endTime, durationInSeconds, notes);
}

class WorkSessionModelAdapter extends TypeAdapter<WorkSessionModel> {
  @override
  final int typeId = HiveTypeIds.workSession;

  @override
  WorkSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkSessionModel(
      id: fields[0] as String,
      companyId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
      durationInSeconds: fields[4] as int,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkSessionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.companyId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.durationInSeconds)
      ..writeByte(5)
      ..write(obj.notes);
  }
}
