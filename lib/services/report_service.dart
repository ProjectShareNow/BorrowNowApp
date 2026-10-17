import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/report_model.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class ReportService {
  final FirebaseFirestore? firestore;

  ReportService({this.firestore});

  /// Submit a new report or dispute
  Future<String> submitReport(ReportModel report) async {
    final reportId = report.id.isNotEmpty
        ? report.id
        : FirestoreIdGenerator.generateId('reports');
    final newReport = report.copyWith(id: reportId);

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore
          .collection('reports')
          .doc(reportId)
          .set(newReport.toMap());
    } else {
      InMemoryStore.instance.reports[reportId] = newReport;
      InMemoryStore.instance.notifyReports();
    }

    return reportId;
  }

  /// Stream of reports submitted by a specific student
  Stream<List<ReportModel>> getMyReportsStream(String userId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ReportModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.reportsStream.map(
        (list) =>
            list.where((r) => r.reporterId == userId).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of all reports for admin review
  Stream<List<ReportModel>> getAllReportsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ReportModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.reportsStream.map(
        (list) =>
            List<ReportModel>.from(list)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Admin updates report status and resolution notes
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String? adminNotes,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final doc = await firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) throw Exception('Report not found.');
      final report = ReportModel.fromFirestore(doc);

      await firestore.collection('reports').doc(reportId).update({
        'status': status,
        'adminNotes': adminNotes,
        'updatedAt': Timestamp.now(),
      });

      // Notify reporter of resolution
      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: report.reporterId,
        senderId: 'admin',
        senderName: 'Admin Team',
        type: 'admin_notice',
        title: 'Report Update: Status $status',
        message:
            'Your report regarding "${report.reason}" has been marked as $status. Notes: ${adminNotes ?? "None"}',
        relatedId: reportId,
      );
      await firestore
          .collection('notifications')
          .doc(notif.id)
          .set(notif.toMap());
    } else {
      final report = InMemoryStore.instance.reports[reportId];
      if (report == null) throw Exception('Report not found.');

      final updated = report.copyWith(
        status: status,
        adminNotes: adminNotes,
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.reports[reportId] = updated;

      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: report.reporterId,
        senderId: 'admin',
        senderName: 'Admin Team',
        type: 'admin_notice',
        title: 'Report Update: Status $status',
        message:
            'Your report regarding "${report.reason}" has been marked as $status. Notes: ${adminNotes ?? "None"}',
        relatedId: reportId,
      );
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyReports();
      InMemoryStore.instance.notifyNotifications();
    }
  }
}
