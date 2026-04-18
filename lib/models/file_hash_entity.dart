import 'package:objectbox/objectbox.dart';

@Entity()
class FileHashEntity {
  @Id()
  int id;

  @Index()
  String path;

  int size;
  int lastModified;
  String? partialHash;
  String? fullHash;

  FileHashEntity({
    this.id = 0,
    required this.path,
    required this.size,
    required this.lastModified,
    this.partialHash,
    this.fullHash,
  });
}
