import 'package:persis_app/features/anggota/data/models/role_model.dart';

// 1. Objek Role sebagai Anggota biasa
final roleAnggota = RoleModel(type: RoleType.anggota);

// 2. Objek Role sebagai Bendahara Pimpinan Jamaah (PJ)
final roleBendaharaPJ = RoleModel(type: RoleType.bendaharaPJ);

// 3. Objek Role sebagai Bendahara Pimpinan Cabang (PC)
final roleBendaharaPC = RoleModel(type: RoleType.bendaharaPC);

// 4. Objek Role sebagai Bendahara Pimpinan Daerah (PD)
final roleBendaharaPD = RoleModel(type: RoleType.bendaharaPD);

// 5. Objek Role sebagai Admin (Pusat/Sistem)
final roleAdmin = RoleModel(type: RoleType.admin);
