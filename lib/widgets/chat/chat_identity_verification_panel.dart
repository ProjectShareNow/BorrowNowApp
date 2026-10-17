import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/service_registry.dart';
import 'live_evidence_capture_card.dart';

/// Photo Evidence Card displayed above the chat message input box.
///
/// Provides live camera photo capture for item handover and return condition,
/// with image preview, retake, confirmation, and Firebase Storage upload.
/// Identity verification has been removed from this panel.
class ChatPhotoEvidenceCard extends StatelessWidget {
  final ChatModel chat;
  final TransactionModel? transaction;
  final UserModel currentUser;
  final VoidCallback onRefresh;

  const ChatPhotoEvidenceCard({
    super.key,
    required this.chat,
    required this.transaction,
    required this.currentUser,
    required this.onRefresh,
  });

  bool get _isLender =>
      currentUser.uid == chat.lenderId ||
      currentUser.uid == chat.ownerId ||
      (transaction != null && currentUser.uid == transaction!.ownerId);

  bool get _isBorrower =>
      currentUser.uid == chat.borrowerId ||
      (transaction != null && currentUser.uid == transaction!.borrowerId);

  bool get _isReturnStage =>
      transaction != null && transaction!.isReturnRequested;

  @override
  Widget build(BuildContext context) {
    final txn = transaction;
    final isReturn = _isReturnStage;
    final isParticipant = _isLender || _isBorrower;

    final canCapture = isReturn ? _isBorrower : _isLender;
    final disabledReason = !isParticipant
        ? 'Unauthorized to capture photo for this transaction.'
        : (canCapture
            ? ''
            : (isReturn
                ? 'Only the borrower can capture return photo.'
                : 'Only the lender can capture handover photo.'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: LiveEvidenceCaptureCard(
        title: isReturn
            ? 'Return Item Condition Photo'
            : 'Handover Item Condition Photo',
        description: isReturn
            ? 'Capture fresh photo of the item condition upon return.'
            : 'Capture fresh photo of the item condition before handover.',
        existingPhotoUrl: isReturn
            ? (txn?.returnPhotoUrl ?? '')
            : (txn?.handoverPhotoUrl ?? ''),
        isEnabled: canCapture && isParticipant,
        disabledReason: disabledReason,
        onUpload: (file) async {
          TransactionModel? activeTxn = txn;
          if (activeTxn == null) {
            try {
              activeTxn = await ServiceRegistry.transactionService
                  .getOrCreateTransactionForChat(
                requestId: chat.requestId,
                itemId: chat.itemId,
                itemName: chat.itemName,
                itemPhotoUrl: chat.itemPhotoUrl,
                borrowerId: chat.borrowerId,
                lenderId: chat.lenderId.isNotEmpty
                    ? chat.lenderId
                    : chat.ownerId,
                borrowerName: chat.borrowerName,
                lenderName: chat.lenderName.isNotEmpty
                    ? chat.lenderName
                    : chat.ownerName,
              );
            } catch (_) {}
          }

          if (isReturn) {
            final res = await ServiceRegistry.storageService
                .uploadReturnEvidencePhoto(
              file: file,
              transactionId: activeTxn?.id ?? chat.id,
            );
            if (activeTxn != null) {
              await ServiceRegistry.transactionService.confirmReturnPhoto(
                transactionId: activeTxn.id,
                currentUserId: currentUser.uid,
                photoUrl: res['downloadUrl']!,
                storagePath: res['storagePath']!,
              );
            }
            onRefresh();
            return res;
          } else {
            final res = await ServiceRegistry.storageService
                .uploadHandoverEvidencePhoto(
              file: file,
              transactionId: activeTxn?.id ?? chat.id,
            );
            if (activeTxn != null) {
              await ServiceRegistry.transactionService.confirmHandoverPhoto(
                transactionId: activeTxn.id,
                lenderId: currentUser.uid,
                photoUrl: res['downloadUrl']!,
                storagePath: res['storagePath']!,
              );
            }
            onRefresh();
            return res;
          }
        },
        onPhotoConfirmed: () {
          onRefresh();
        },
      ),
    );
  }
}

/// Backwards compatible alias for any remaining references.
typedef ChatIdentityVerificationPanel = ChatPhotoEvidenceCard;
