import 'package:flutter/material.dart';
import 'compaction_test_page.dart';
import 'concrete_inspection_page.dart';
import 'daily_field_report_page.dart';
import 'daily_photo_report_page.dart';
import 'field_compaction_page.dart';
import 'footing_inspection_page.dart';

/// Returns the form page that matches a task's type; unmatched types use the compaction test form.
Widget taskFormPage(String taskType, int taskId) {
  if (isConcreteInspectionType(taskType)) {
    return ConcreteInspectionPage(taskId: taskId);
  }
  if (isFootingInspectionType(taskType)) {
    return FootingInspectionPage(taskId: taskId);
  }
  if (isFieldCompactionType(taskType)) {
    return FieldCompactionPage(taskId: taskId);
  }
  if (isDailyPhotoReportType(taskType)) {
    return DailyPhotoReportPage(taskId: taskId);
  }
  if (isDailyFieldReportType(taskType)) {
    return DailyFieldReportPage(taskId: taskId);
  }
  return CompactionTestPage(taskId: taskId);
}
