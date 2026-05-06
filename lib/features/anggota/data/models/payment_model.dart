class PaymentModel {
  final String? anggotaId;
  final String? periodMulai;
  final String? periodAkhir;
  final int? totalAmount;
  final String? paymentMethod; 
  final String? bank; 
  final String? buktiUrl;

  PaymentModel({
    this.anggotaId,
    this.periodMulai,
    this.periodAkhir,
    this.totalAmount,
    this.paymentMethod,
    this.bank,
    this.buktiUrl,
  });

  Map<String, dynamic> toJson() => {
        'anggota_id': anggotaId,
        'period_mulai': periodMulai,
        'period_akhir': periodAkhir,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        if (bank != null) 'bank': bank,
        if (buktiUrl != null) 'bukti_url': buktiUrl,
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        anggotaId: json['anggota_id'],
        periodMulai: json['period_mulai'],
        periodAkhir: json['period_akhir'],
        totalAmount: json['total_amount'],
        paymentMethod: json['payment_method'],
        bank: json['bank'],
        buktiUrl: json['bukti_url'],
      );
}
