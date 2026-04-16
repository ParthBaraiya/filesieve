/// NavigationItem — the four persistent sidebar navigation destinations.
enum NavigationItem {
  scan,
  results,
  settings,
  history,
}

/// ScanSessionStatus — lifecycle state of a scan session.
enum ScanSessionStatus {
  pending,
  scanning,
  done,
  cancelled,
}
