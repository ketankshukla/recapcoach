class AppConfig {
  const AppConfig({
    required this.minTrialDays,
    required this.freeTierLimit,
    required this.monthlyProductId,
    required this.annualProductId,
  });

  final int minTrialDays;
  final int freeTierLimit;
  final String monthlyProductId;
  final String annualProductId;

  static const AppConfig defaults = AppConfig(
    minTrialDays: 3,
    freeTierLimit: 3,
    monthlyProductId: 'pro_monthly',
    annualProductId: 'pro_annual',
  );
}
