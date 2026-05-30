/// Internal JSON parsing helpers shared by the model classes.
///
/// Not exported from the public barrel.
library;

/// Parses a required ISO-8601 date string into a UTC [DateTime].
///
/// Throws a [FormatException] if [value] is absent or not a valid date, so the
/// transport layer can surface it as an `AuthUnknownException`.
DateTime parseRequiredDate(Object? value) {
  final parsed = parseOptionalDate(value);
  if (parsed == null) {
    throw FormatException('Expected an ISO-8601 date string', value);
  }
  return parsed;
}

/// Parses an optional ISO-8601 date string into a UTC [DateTime], or `null`.
DateTime? parseOptionalDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed?.toUtc();
  }
  return null;
}

/// Serializes a [DateTime] to a UTC ISO-8601 string.
String encodeDate(DateTime value) => value.toUtc().toIso8601String();

/// Returns the entries of [json] whose keys are not in [knownKeys], used to
/// capture server `additionalFields` and plugin extensions on open model
/// shapes such as `User` and `Session`.
Map<String, Object?> extractAdditionalFields(
  Map<String, dynamic> json,
  Set<String> knownKeys,
) {
  final extra = <String, Object?>{};
  for (final entry in json.entries) {
    if (!knownKeys.contains(entry.key)) {
      extra[entry.key] = entry.value;
    }
  }
  return extra;
}
