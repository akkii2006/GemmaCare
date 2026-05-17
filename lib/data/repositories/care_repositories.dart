import '../local/database/doctor_dao.dart';
import '../local/database/hospital_dao.dart';
import '../local/database/pharmacy_dao.dart';
import '../models/doctor_model.dart';
import '../models/hospital_model.dart';
import '../models/pharmacy_model.dart';

class DoctorRepository {
  final DoctorDao _dao = DoctorDao();

  Future<List<Doctor>> getAll() => _dao.getAll();
  Future<void> insertAll(List<Doctor> doctors) => _dao.insertAll(doctors);
  Future<void> clear() => _dao.clear();
}

class HospitalRepository {
  final HospitalDao _dao = HospitalDao();

  Future<List<Hospital>> getAll() => _dao.getAll();
  Future<void> insertAll(List<Hospital> hospitals) => _dao.insertAll(hospitals);
  Future<void> clear() => _dao.clear();
}

class PharmacyRepository {
  final PharmacyDao _dao = PharmacyDao();

  Future<List<Pharmacy>> getAll() => _dao.getAll();
  Future<void> insertAll(List<Pharmacy> pharmacies) => _dao.insertAll(pharmacies);
  Future<void> clear() => _dao.clear();
}
