class CategoryBudget {
  const CategoryBudget({
    required this.categoryId,
    required this.monthlyLimit,
  });

  final String categoryId;
  final double monthlyLimit;

  CategoryBudget copyWith({double? monthlyLimit}) => CategoryBudget(
        categoryId: categoryId,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      );
}
