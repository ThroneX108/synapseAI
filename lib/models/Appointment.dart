/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the Appointment type in your schema. */
class Appointment extends amplify_core.Model {
  static const classType = const _AppointmentModelType();
  final String id;
  final StudentProfile? _student;
  final CounselorProfile? _counselor;
  final amplify_core.TemporalDate? _date;
  final String? _timeSlot;
  final AppointmentStatus? _status;
  final String? _topic;
  final String? _meetingLink;
  final String? _counselorNotes;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  AppointmentModelIdentifier get modelIdentifier {
      return AppointmentModelIdentifier(
        id: id
      );
  }
  
  StudentProfile? get student {
    return _student;
  }
  
  CounselorProfile? get counselor {
    return _counselor;
  }
  
  amplify_core.TemporalDate get date {
    try {
      return _date!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get timeSlot {
    try {
      return _timeSlot!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  AppointmentStatus get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get topic {
    return _topic;
  }
  
  String? get meetingLink {
    return _meetingLink;
  }
  
  String? get counselorNotes {
    return _counselorNotes;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Appointment._internal({required this.id, student, counselor, required date, required timeSlot, required status, topic, meetingLink, counselorNotes, createdAt, updatedAt}): _student = student, _counselor = counselor, _date = date, _timeSlot = timeSlot, _status = status, _topic = topic, _meetingLink = meetingLink, _counselorNotes = counselorNotes, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Appointment({String? id, StudentProfile? student, CounselorProfile? counselor, required amplify_core.TemporalDate date, required String timeSlot, required AppointmentStatus status, String? topic, String? meetingLink, String? counselorNotes}) {
    return Appointment._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      student: student,
      counselor: counselor,
      date: date,
      timeSlot: timeSlot,
      status: status,
      topic: topic,
      meetingLink: meetingLink,
      counselorNotes: counselorNotes);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Appointment &&
      id == other.id &&
      _student == other._student &&
      _counselor == other._counselor &&
      _date == other._date &&
      _timeSlot == other._timeSlot &&
      _status == other._status &&
      _topic == other._topic &&
      _meetingLink == other._meetingLink &&
      _counselorNotes == other._counselorNotes;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Appointment {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("student=" + (_student != null ? _student!.toString() : "null") + ", ");
    buffer.write("counselor=" + (_counselor != null ? _counselor!.toString() : "null") + ", ");
    buffer.write("date=" + (_date != null ? _date!.format() : "null") + ", ");
    buffer.write("timeSlot=" + "$_timeSlot" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("topic=" + "$_topic" + ", ");
    buffer.write("meetingLink=" + "$_meetingLink" + ", ");
    buffer.write("counselorNotes=" + "$_counselorNotes" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Appointment copyWith({StudentProfile? student, CounselorProfile? counselor, amplify_core.TemporalDate? date, String? timeSlot, AppointmentStatus? status, String? topic, String? meetingLink, String? counselorNotes}) {
    return Appointment._internal(
      id: id,
      student: student ?? this.student,
      counselor: counselor ?? this.counselor,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      meetingLink: meetingLink ?? this.meetingLink,
      counselorNotes: counselorNotes ?? this.counselorNotes);
  }
  
  Appointment copyWithModelFieldValues({
    ModelFieldValue<StudentProfile?>? student,
    ModelFieldValue<CounselorProfile?>? counselor,
    ModelFieldValue<amplify_core.TemporalDate>? date,
    ModelFieldValue<String>? timeSlot,
    ModelFieldValue<AppointmentStatus>? status,
    ModelFieldValue<String?>? topic,
    ModelFieldValue<String?>? meetingLink,
    ModelFieldValue<String?>? counselorNotes
  }) {
    return Appointment._internal(
      id: id,
      student: student == null ? this.student : student.value,
      counselor: counselor == null ? this.counselor : counselor.value,
      date: date == null ? this.date : date.value,
      timeSlot: timeSlot == null ? this.timeSlot : timeSlot.value,
      status: status == null ? this.status : status.value,
      topic: topic == null ? this.topic : topic.value,
      meetingLink: meetingLink == null ? this.meetingLink : meetingLink.value,
      counselorNotes: counselorNotes == null ? this.counselorNotes : counselorNotes.value
    );
  }
  
  Appointment.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _student = json['student'] != null
        ? json['student']['serializedData'] != null
          ? StudentProfile.fromJson(new Map<String, dynamic>.from(json['student']['serializedData']))
          : StudentProfile.fromJson(new Map<String, dynamic>.from(json['student']))
        : null,
      _counselor = json['counselor'] != null
        ? json['counselor']['serializedData'] != null
          ? CounselorProfile.fromJson(new Map<String, dynamic>.from(json['counselor']['serializedData']))
          : CounselorProfile.fromJson(new Map<String, dynamic>.from(json['counselor']))
        : null,
      _date = json['date'] != null ? amplify_core.TemporalDate.fromString(json['date']) : null,
      _timeSlot = json['timeSlot'],
      _status = amplify_core.enumFromString<AppointmentStatus>(json['status'], AppointmentStatus.values),
      _topic = json['topic'],
      _meetingLink = json['meetingLink'],
      _counselorNotes = json['counselorNotes'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'student': _student?.toJson(), 'counselor': _counselor?.toJson(), 'date': _date?.format(), 'timeSlot': _timeSlot, 'status': amplify_core.enumToString(_status), 'topic': _topic, 'meetingLink': _meetingLink, 'counselorNotes': _counselorNotes, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'student': _student,
    'counselor': _counselor,
    'date': _date,
    'timeSlot': _timeSlot,
    'status': _status,
    'topic': _topic,
    'meetingLink': _meetingLink,
    'counselorNotes': _counselorNotes,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AppointmentModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AppointmentModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final STUDENT = amplify_core.QueryField(
    fieldName: "student",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'StudentProfile'));
  static final COUNSELOR = amplify_core.QueryField(
    fieldName: "counselor",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'CounselorProfile'));
  static final DATE = amplify_core.QueryField(fieldName: "date");
  static final TIMESLOT = amplify_core.QueryField(fieldName: "timeSlot");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final TOPIC = amplify_core.QueryField(fieldName: "topic");
  static final MEETINGLINK = amplify_core.QueryField(fieldName: "meetingLink");
  static final COUNSELORNOTES = amplify_core.QueryField(fieldName: "counselorNotes");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Appointment";
    modelSchemaDefinition.pluralName = "Appointments";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "counselorID",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "studentID",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["studentID", "date"], name: "byStudent"),
      amplify_core.ModelIndex(fields: const ["counselorID", "date"], name: "byCounselor")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Appointment.STUDENT,
      isRequired: false,
      targetNames: ['studentID'],
      ofModelName: 'StudentProfile'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Appointment.COUNSELOR,
      isRequired: false,
      targetNames: ['counselorID'],
      ofModelName: 'CounselorProfile'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.DATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.date)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.TIMESLOT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.TOPIC,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.MEETINGLINK,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Appointment.COUNSELORNOTES,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _AppointmentModelType extends amplify_core.ModelType<Appointment> {
  const _AppointmentModelType();
  
  @override
  Appointment fromJson(Map<String, dynamic> jsonData) {
    return Appointment.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Appointment';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Appointment] in your schema.
 */
class AppointmentModelIdentifier implements amplify_core.ModelIdentifier<Appointment> {
  final String id;

  /** Create an instance of AppointmentModelIdentifier using [id] the primary key. */
  const AppointmentModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'AppointmentModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is AppointmentModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}