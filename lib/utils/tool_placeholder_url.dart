bool isToolPlaceholderUrl(String? src) {
  if (src == null) return false;
  final t = src.trim();
  if (t.isEmpty) return false;
  if (t == '/tool.png') return true;
  if (t.toLowerCase().endsWith('/tool.png')) return true;
  return false;
}
