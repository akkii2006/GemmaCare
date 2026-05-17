class Appointment {
  final int? id;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime dateTime;
  final String notes;
  final bool isUpcoming;
  final String prepChecklist;
  final String questionsToAsk;
  final String postNotes;
  final String aiSummary;

  const Appointment({
    this.id,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.dateTime,
    required this.notes,
    required this.isUpcoming,
    this.prepChecklist = '',
    this.questionsToAsk = '',
    this.postNotes = '',
    this.aiSummary = '',
  });

  Appointment copyWith({
    int? id,
    String? doctorName,
    String? specialty,
    String? hospital,
    DateTime? dateTime,
    String? notes,
    bool? isUpcoming,
    String? prepChecklist,
    String? questionsToAsk,
    String? postNotes,
    String? aiSummary,
  }) => Appointment(
    id: id ?? this.id,
    doctorName: doctorName ?? this.doctorName,
    specialty: specialty ?? this.specialty,
    hospital: hospital ?? this.hospital,
    dateTime: dateTime ?? this.dateTime,
    notes: notes ?? this.notes,
    isUpcoming: isUpcoming ?? this.isUpcoming,
    prepChecklist: prepChecklist ?? this.prepChecklist,
    questionsToAsk: questionsToAsk ?? this.questionsToAsk,
    postNotes: postNotes ?? this.postNotes,
    aiSummary: aiSummary ?? this.aiSummary,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctorName': doctorName,
    'specialty': specialty,
    'hospital': hospital,
    'dateTime': dateTime.toIso8601String(),
    'notes': notes,
    'isUpcoming': isUpcoming ? 1 : 0,
    'prepChecklist': prepChecklist,
    'questionsToAsk': questionsToAsk,
    'postNotes': postNotes,
    'aiSummary': aiSummary,
  };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
    id: map['id'],
    doctorName: map['doctorName'] ?? '',
    specialty: map['specialty'] ?? '',
    hospital: map['hospital'] ?? '',
    dateTime: DateTime.parse(map['dateTime']),
    notes: map['notes'] ?? '',
    isUpcoming: (map['isUpcoming'] ?? 1) == 1,
    prepChecklist: map['prepChecklist'] ?? '',
    questionsToAsk: map['questionsToAsk'] ?? '',
    postNotes: map['postNotes'] ?? '',
    aiSummary: map['aiSummary'] ?? '',
  );
}
