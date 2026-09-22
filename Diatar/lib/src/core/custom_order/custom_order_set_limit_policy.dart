import '../../models/custom_order_set.dart';

class CustomOrderSetLimitPolicy {
  const CustomOrderSetLimitPolicy();

  int evictionIndex(
    List<CustomOrderSet> sets, {
    required int maximumCount,
    Set<String> protectedIds = const <String>{},
  }) {
    if (sets.length < maximumCount || sets.isEmpty) {
      return -1;
    }

    int oldestIndex = -1;
    for (int i = 0; i < sets.length; i++) {
      if (protectedIds.contains(sets[i].id)) {
        continue;
      }
      if (oldestIndex < 0 || sets[i].lastUsed < sets[oldestIndex].lastUsed) {
        oldestIndex = i;
      }
    }
    return oldestIndex;
  }
}
