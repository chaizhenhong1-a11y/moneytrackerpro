import '../../../transactions/domain/entities/transaction_category.dart';

abstract interface class CategoryRepository {
  Future<List<TransactionCategory>> getAll();
  Future<void> replaceAll(List<TransactionCategory> categories);
}
