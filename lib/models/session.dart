import 'package:isar/isar.dart';

part 'session.g.dart';

@Collection()
class Session {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  List<Message> messages = [];
  DateTime createTime = DateTime.now();
  DateTime updateTime = DateTime.now();
}

@embedded
class Message {
  late String role;
  late String content;
  DateTime timestamp = DateTime.now();
}
