abstract class Failure implements Exception {
  final String message;
  Failure({this.message = 'Oops..Something went wrong'});
  @override
  String toString() {
    return message;
  }
}
