import 'provider.dart';
import 'package:isar/isar.dart';

part 'model.g.dart';

@Collection()
class Model {
  Id id = Isar.autoIncrement;
  late String modelId;
  final provider = IsarLink<Provider>();
}
