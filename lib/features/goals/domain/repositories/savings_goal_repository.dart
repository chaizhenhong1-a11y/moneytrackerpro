import '../entities/savings_goal.dart';

abstract interface class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAll();
  Future<void> replaceAll(List<SavingsGoal> goals);
}
