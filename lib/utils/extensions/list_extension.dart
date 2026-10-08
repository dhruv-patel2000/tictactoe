/// Adds an index-aware `any` to List, used where both the element and its
/// position matter (e.g. scanning board rows/columns).
extension IndexedAny<E> on List<E> {
  /// Checks if any element in the list satisfies the given [test] function.
  /// Provides the element and its index to the [test] function.
  /// Returns true if any element satisfies the condition.
  bool indexedAny(bool Function(E element, int index) test) {
    for (var i = 0; i < length; i++) {
      if (test(this[i], i)) {
        return true;
      }
    }
    return false;
  }
}
