enum CompatibilitySeverity { compatible, warning, incompatible }

class CompatibilityIssue {
  final String code;
  final CompatibilitySeverity severity;
  final String message;
  final String? suggestion;

  const CompatibilityIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.suggestion,
  });
}

class CompatibilitySummary {
  final List<CompatibilityIssue> issues;

  const CompatibilitySummary(this.issues);

  CompatibilitySeverity get severity {
    if (issues.any(
      (issue) => issue.severity == CompatibilitySeverity.incompatible,
    )) {
      return CompatibilitySeverity.incompatible;
    }
    if (issues.any(
      (issue) => issue.severity == CompatibilitySeverity.warning,
    )) {
      return CompatibilitySeverity.warning;
    }
    return CompatibilitySeverity.compatible;
  }
}
