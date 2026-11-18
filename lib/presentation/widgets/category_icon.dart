import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/models/category.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.category,
    this.spendingBreakdown = false,
    this.budgetContext = false,
    this.size = 24,
    super.key,
  });
  final Category category;
  final bool spendingBreakdown;
  final bool budgetContext;
  final double size;
  IconData get icon => switch (category) {
    Category.food => Icons.restaurant_outlined,
    Category.transport => Icons.directions_car_outlined,
    Category.shopping => Icons.shopping_bag_outlined,
    Category.leisure => Icons.sports_esports_outlined,
    Category.health => Icons.favorite_border,
    Category.education => Icons.menu_book_outlined,
    Category.housing => Icons.home_outlined,
    Category.otherExpense => Icons.more_horiz,
    Category.salary => Icons.arrow_upward,
    Category.otherIncome => Icons.account_balance_wallet_outlined,
  };

  Color get foreground => switch (category) {
    Category.food =>
      spendingBreakdown
          ? FinancialVisualTokens.shopping
          : FinancialVisualTokens.food,
    Category.transport =>
      budgetContext ? AppColors.primary : FinancialVisualTokens.transport,
    Category.leisure => FinancialVisualTokens.leisure,
    Category.shopping => FinancialVisualTokens.shopping,
    _ => AppColors.primary,
  };
  Color get background => switch (category) {
    Category.food =>
      spendingBreakdown
          ? FinancialVisualTokens.shoppingSurface
          : FinancialVisualTokens.foodSurface,
    Category.transport =>
      budgetContext
          ? FinancialVisualTokens.incomeSurface
          : FinancialVisualTokens.transportSurface,
    Category.leisure => FinancialVisualTokens.leisureSurface,
    Category.shopping => FinancialVisualTokens.shoppingSurface,
    _ => FinancialVisualTokens.incomeSurface,
  };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Icon(icon, color: foreground, size: size),
    ),
  );
}
