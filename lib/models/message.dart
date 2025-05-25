import 'package:isar/isar.dart';
import 'session.dart';

part 'message.g.dart';

@Collection()
class Message {
  Id id = Isar.autoIncrement;
  late String role;
  late String content;
  DateTime timestamp = DateTime.now();
  
  // 关联到Session的链接
  final session = IsarLink<Session>();

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}