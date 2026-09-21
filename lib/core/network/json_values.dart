/// Google Sheets can return the same scalar as a number or as text depending
/// on the cell format. Normalize these values at the API/model boundary.
String? jsonText(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  throw const FormatException('Expected a scalar text value');
}

num? jsonNumber(dynamic value) {
  if (value == null || value == '') return null;
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw const FormatException('Expected a numeric value');
}

bool? jsonBool(dynamic value) {
  if (value == null || value == '') return null;
  if (value is bool) return value;
  if (value == 1 || value == '1') return true;
  if (value == 0 || value == '0') return false;
  if (value is String) {
    if (value.trim().toLowerCase() == 'true') return true;
    if (value.trim().toLowerCase() == 'false') return false;
  }
  throw const FormatException('Expected a boolean value');
}
