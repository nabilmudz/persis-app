import '../datasources/user_remote_datasource.dart'; 
import '../models/transaction_item_model.dart';

class AnggotaRepository {
  final UserRemoteDataSource userRemoteDataSource;

  AnggotaRepository(this.userRemoteDataSource);

  Future<Map<String, dynamic>> login(String emailOrNpa, String password) async {
    try {
      return await userRemoteDataSource.login(emailOrNpa, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> activateUser(String id) async {
    try {
      return await userRemoteDataSource.activate(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionItemModel>> getRiwayatIuran(String userId, {int? year}) async {
    try {
      return await userRemoteDataSource.getRiwayatIuran(userId, year: year);
    } catch (e) {
      rethrow;
    }
  }

}
