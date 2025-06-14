import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_data.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Authentication
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Workers CRUD
  static Future<List<Worker>> getWorkers() async {
    final response = await _client
        .from('workers')
        .select()
        .eq('user_id', currentUser!.id);
    
    return (response as List)
        .map((json) => Worker.fromJson(json))
        .toList();
  }
  
  static Future<Worker> createWorker(Worker worker) async {
    final response = await _client
        .from('workers')
        .insert({
          'user_id': currentUser!.id,
          'name': worker.name,
          'profession': worker.profession,
          'master_class_id': worker.masterClassId,
          'housing_id': worker.housingId,
        })
        .select()
        .single();
    
    return Worker.fromJson(response);
  }
  
  static Future<Worker> updateWorker(int id, Worker worker) async {
    final response = await _client
        .from('workers')
        .update({
          'name': worker.name,
          'profession': worker.profession,
          'master_class_id': worker.masterClassId,
          'housing_id': worker.housingId,
        })
        .eq('id', id)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    
    return Worker.fromJson(response);
  }
  
  static Future<void> deleteWorker(int id) async {
    await _client
        .from('workers')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }
  
  // Master Classes CRUD
  static Future<List<MasterClass>> getMasterClasses() async {
    final response = await _client
        .from('master_classes')
        .select()
        .eq('user_id', currentUser!.id);
    
    return (response as List)
        .map((json) => MasterClass.fromJson(json))
        .toList();
  }
  
  static Future<MasterClass> updateMasterClass(String id, MasterClass masterClass) async {
    final response = await _client
        .from('master_classes')
        .update({
          'display_name': masterClass.displayName,
          'shift_type': masterClass.shiftType.name,
        })
        .eq('id', id)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    
    return MasterClass.fromJson(response);
  }
  
  // Housing Units CRUD
  static Future<List<HousingUnit>> getHousingUnits() async {
    final response = await _client
        .from('housing_units')
        .select()
        .eq('user_id', currentUser!.id);
    
    return (response as List)
        .map((json) => HousingUnit.fromJson(json))
        .toList();
  }
  
  static Future<HousingUnit> createHousingUnit(HousingUnit unit) async {
    final response = await _client
        .from('housing_units')
        .insert({
          'id': unit.id,
          'user_id': currentUser!.id,
          'display_name': unit.displayName,
          'shift_type': unit.shiftType.name,
          'max_capacity': unit.maxCapacity,
        })
        .select()
        .single();
    
    return HousingUnit.fromJson(response);
  }
  
  static Future<HousingUnit> updateHousingUnit(String id, HousingUnit unit) async {
    final response = await _client
        .from('housing_units')
        .update({
          'display_name': unit.displayName,
          'shift_type': unit.shiftType.name,
          'max_capacity': unit.maxCapacity,
        })
        .eq('id', id)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    
    return HousingUnit.fromJson(response);
  }
  
  static Future<void> deleteHousingUnit(String id) async {
    await _client
        .from('housing_units')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }
  
  // Profession Capacities CRUD
  static Future<List<ProfessionCapacity>> getProfessionCapacities() async {
    final response = await _client
        .from('profession_capacities')
        .select()
        .eq('user_id', currentUser!.id)
        .order('profession');
    
    return (response as List)
        .map((json) => ProfessionCapacity.fromJson(json))
        .toList();
  }
  
  static Future<ProfessionCapacity> createProfessionCapacity(ProfessionCapacity capacity) async {
    final response = await _client
        .from('profession_capacities')
        .insert({
          'user_id': currentUser!.id,
          'profession': capacity.profession,
          'max_day_capacity': capacity.maxDayCapacity,
          'max_night_capacity': capacity.maxNightCapacity,
          'available_at_night': capacity.availableAtNight,
        })
        .select()
        .single();
    
    return ProfessionCapacity.fromJson(response);
  }
  
  static Future<ProfessionCapacity> updateProfessionCapacity(int id, ProfessionCapacity capacity) async {
    final response = await _client
        .from('profession_capacities')
        .update({
          'profession': capacity.profession,
          'max_day_capacity': capacity.maxDayCapacity,
          'max_night_capacity': capacity.maxNightCapacity,
          'available_at_night': capacity.availableAtNight,
        })
        .eq('id', id)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    
    return ProfessionCapacity.fromJson(response);
  }
  
  static Future<void> deleteProfessionCapacity(int id) async {
    await _client
        .from('profession_capacities')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }
} 