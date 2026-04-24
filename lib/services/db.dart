import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _db => Supabase.instance.client;

/// Central data-access service.
/// Column names use snake_case PostgreSQL conventions — adjust if your schema differs.
class DbService {
  // ── Customers ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCustomers() =>
      _db.from('Customers').select('customer_id, company_name').order('customer_id');

  static Future<Map<String, dynamic>?> getCustomer(String id) =>
      _db.from('Customers').select().eq('customer_id', id).maybeSingle();

  static Future<void> upsertCustomer(Map<String, dynamic> data) =>
      _db.from('Customers').upsert(data, onConflict: 'customer_id');

  static Future<void> deleteCustomer(String id) =>
      _db.from('Customers').delete().eq('customer_id', id);

  // ── Projects ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProjects({bool activeOnly = false}) async {
    if (activeOnly) {
      return await _db
          .from('Projects')
          .select('project_id, project_name, active_project')
          .eq('active_project', true)
          .order('project_id');
    }
    return await _db
        .from('Projects')
        .select('project_id, project_name, active_project')
        .order('project_id');
  }

  static Future<List<Map<String, dynamic>>> getProjectsByCustomer(String customerId) =>
      _db
          .from('Projects')
          .select('project_id, project_name, active_project')
          .eq('customer_id', customerId)
          .order('project_id');

  static Future<Map<String, dynamic>?> getProject(String id) =>
      _db.from('Projects').select().eq('project_id', id).maybeSingle();

  static Future<void> upsertProject(Map<String, dynamic> data) =>
      _db.from('Projects').upsert(data, onConflict: 'project_id');

  static Future<void> deleteProject(String id) =>
      _db.from('Projects').delete().eq('project_id', id);

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllTasks() =>
      _db
          .from('Tasks')
          .select('id, project_id, sequence, task_type, extended')
          .order('project_id')
          .order('sequence');

  static Future<List<Map<String, dynamic>>> getTasks(String projectId) =>
      _db.from('Tasks').select().eq('project_id', projectId).order('sequence');

  static Future<Map<String, dynamic>> insertTask(Map<String, dynamic> data) async {
    final res = await _db.from('Tasks').insert(data).select().single();
    return res;
  }

  static Future<void> updateTask(int id, Map<String, dynamic> data) =>
      _db.from('Tasks').update(data).eq('id', id);

  static Future<void> deleteTask(int id) =>
      _db.from('Tasks').delete().eq('id', id);

  // ── TaskCodes ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTaskCodes() =>
      _db.from('TaskCodes').select().order('task_code_id');

  static Future<void> upsertTaskCode(Map<String, dynamic> data) =>
      _db.from('TaskCodes').upsert(data, onConflict: 'task_code_id');

  // ── TaskCodeExt ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTaskCodeExts() =>
      _db.from('TaskCodeExt').select().order('task_code_id');

  static Future<void> upsertTaskCodeExt(Map<String, dynamic> data) =>
      _db.from('TaskCodeExt').upsert(data, onConflict: 'task_code_id');

  // ── BillingCodes ───────────────────────────────────────────────────────── 

  static Future<List<Map<String, dynamic>>> getBillingCodes() =>
      _db.from('BillingCodes').select().order('billing_code_id');

  static Future<void> upsertBillingCode(Map<String, dynamic> data) =>
      _db.from('BillingCodes').upsert(data, onConflict: 'billing_code_id');

  // ── ProjectBilling ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProjectBilling(String projectId) =>
      _db.from('ProjectBilling').select().eq('project_id', projectId);

  static Future<Map<String, dynamic>> insertProjectBilling(Map<String, dynamic> data) async {
    final res = await _db.from('ProjectBilling').insert(data).select().single();
    return res;
  }

  static Future<void> updateProjectBilling(int id, Map<String, dynamic> data) =>
      _db.from('ProjectBilling').update(data).eq('id', id);

  static Future<void> deleteProjectBilling(int id) =>
      _db.from('ProjectBilling').delete().eq('id', id);

  // ── Molds ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMolds() =>
      _db.from('Molds').select().order('mold_number');

  static Future<void> upsertMold(Map<String, dynamic> data) =>
      _db.from('Molds').upsert(data, onConflict: 'mold_number');

  // ── Proctors ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProctors(String projectId) =>
      _db.from('Proctors').select().eq('project_id', projectId).order('soil_no');

  static Future<List<Map<String, dynamic>>> getAllProctors({bool activeOnly = false}) async {
    if (activeOnly) {
      return await _db
          .from('Proctors')
          .select('id, project_id, soil_no, max_dry_density, optimum_moisture, soil_classification, Projects!inner(active_project)')
          .eq('Projects.active_project', true)
          .order('project_id')
          .order('soil_no');
    }
    return await _db
        .from('Proctors')
        .select('id, project_id, soil_no, max_dry_density, optimum_moisture, soil_classification')
        .order('project_id')
        .order('soil_no');
  }

  static Future<Map<String, dynamic>> insertProctor(Map<String, dynamic> data) async {
    final res = await _db.from('Proctors').insert(data).select().single();
    return res;
  }

  static Future<void> updateProctor(int id, Map<String, dynamic> data) =>
      _db.from('Proctors').update(data).eq('id', id);

  static Future<void> deleteProctor(int id) =>
      _db.from('Proctors').delete().eq('id', id);

  // ── Employees ─────────────────────────────────────────────────────────────

  static Future<List<String>> getEmployeeIds() async {
    final rows = await _db
        .from('Employees')
        .select('employee_id')
        .order('employee_id');
    return rows.map<String>((r) => r['employee_id'] as String).toList();
  }
}
