class RamadanGoal {
  const RamadanGoal({required this.id, required this.title});

  final String id;
  final String title;

  factory RamadanGoal.fromMap(Map<String, Object?> map) =>
      RamadanGoal(id: map['id']! as String, title: map['title']! as String);
}
