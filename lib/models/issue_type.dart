enum IssueType {
  taste,
  hygiene,
  temperature,
  portionSize,
  quality,
  other;

  String get displayName {
    switch (this) {
      case IssueType.taste: return 'Taste';
      case IssueType.hygiene: return 'Hygiene';
      case IssueType.temperature: return 'Temperature';
      case IssueType.portionSize: return 'Portion Size';
      case IssueType.quality: return 'Quality';
      case IssueType.other: return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case IssueType.taste: return '👅';
      case IssueType.hygiene: return '🧼';
      case IssueType.temperature: return '🌡️';
      case IssueType.portionSize: return '⚖️';
      case IssueType.quality: return '🌟';
      case IssueType.other: return '📝';
    }
  }
}
