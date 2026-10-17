/// The current time as epoch milliseconds (a named function so database
/// column defaults can point at it).
int nowMs() => DateTime.now().millisecondsSinceEpoch;
