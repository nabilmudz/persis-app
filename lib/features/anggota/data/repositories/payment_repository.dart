import 'dart:io';
import '../datasources/payment_remote_datasource.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepository(this.remoteDataSource);

  Future<Map<String, dynamic>> submitPayment(PaymentModel payment) async {
    try {
      return await remoteDataSource.submitPayment(payment);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadBukti(File imageFile) async {
    try {
      return await remoteDataSource.uploadBukti(imageFile);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQrisDetail() async {
    try {
      return await remoteDataSource.getQrisDetail();
    } catch (e) {
      rethrow;
    }
  }
}
