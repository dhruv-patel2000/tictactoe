// ignore_for_file: public_member_api_docs, sort_constructors_first
// Model: a selectable board dimension (e.g. 3x3, 4x4) offered in game setup.
class MatrixSize {
  final int size;
  final String title;

  const MatrixSize({
    required this.size,
    required this.title,
  });
}
