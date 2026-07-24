import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_remote_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_enum_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late TaskRemoteDsImpl remoteDs;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockQuery mockQuery;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockQuery = MockQuery();
    remoteDs = TaskRemoteDsImpl(mockFirestore);

    // Common stubs
    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
    when(() => mockDocument.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
    when(() => mockCollection.limit(any())).thenReturn(mockQuery);
    when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
    when(() => mockQuery.limit(any())).thenReturn(mockQuery);
  });

  const tTaskModel = TaskModel(
    id: '1',
    title: 'Test',
    description: 'Desc',
    priority: TaskPriorityModel.high,
    dueDate: '2023-10-27',
    status: TaskStatusModel.pending,
  );

  group('getTasks', () {
    test('should throw ForbiddenFailure when Firestore throws permission-denied', () async {
      when(() => mockQuery.get()).thenThrow(FirebaseException(plugin: 'firestore', code: 'permission-denied'));
      expect(() => remoteDs.getTasks(userId: '123'), throwsA(isA<ForbiddenFailure>()));
    });
  });

  group('createTask', () {
    test('should throw ConflictFailure when document already exists', () async {
      when(() => mockDocument.set(any())).thenThrow(FirebaseException(plugin: 'firestore', code: 'already-exists'));
      expect(() => remoteDs.createTask(userId: '123', task: tTaskModel), throwsA(isA<ConflictFailure>()));
    });
  });

  group('updateTask', () {
    test('should throw NotFoundFailure when document missing', () async {
      when(() => mockDocument.update(any())).thenThrow(FirebaseException(plugin: 'firestore', code: 'not-found'));
      expect(() => remoteDs.updateTask(userId: '123', task: tTaskModel), throwsA(isA<NotFoundFailure>()));
    });
  });

  group('deleteTask', () {
    test('should throw ServerFailure on internal error', () async {
      when(() => mockDocument.delete()).thenThrow(FirebaseException(plugin: 'firestore', code: 'internal'));
      expect(() => remoteDs.deleteTask(userId: '123', taskId: '1'), throwsA(isA<ServerFailure>()));
    });
  });
}
