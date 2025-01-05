class Task {
  int? id;
  int orderIndex;
  String title;
  bool isCompleted;
  DateTime date;

  Task({
    this.id,
    required this.orderIndex,
    required this.title,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'orderIndex': orderIndex,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      orderIndex: map['orderIndex'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      date: DateTime.parse(map['date']),
    );
  }
}