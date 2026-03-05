import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/utils/permissions.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../models/issue_type_model.dart';
import '../models/ticket_model.dart';

/// Controller for TicketsScreen. Holds filter state and ticket data.
class TicketsController extends GetxController {
  Permissions get permissions {
    final role = Get.find<HomeController>().currentUser.value?.role ?? Role.client;
    return Permissions.fromRole(role);
  }
  final RxString filter = 'all'.obs; // 'all' | 'open' | 'in-progress' | 'resolved'

  final TicketRepository _ticketRepository = TicketRepository();

  final RxList<IssueTypeModel> issueTypes = <IssueTypeModel>[].obs;
  final RxBool isLoadingIssueTypes = false.obs;

  /// New ticket form state for CreateTicketDialog (matches React newTicket).
  final RxMap<String, String> newTicket = <String, String>{
    'category': '',
    'title': '',
    'description': '',
    'priority': 'medium',
  }.obs;

  /// The selected category id from the dropdown (null = nothing selected).
  final Rxn<int> selectedCategoryId = Rxn<int>();

  /// Attached photos for the new ticket.
  final RxList<File> attachedPhotos = <File>[].obs;

  static const int maxPhotos = 5;

  void addPhoto(File file) {
    if (attachedPhotos.length < maxPhotos) {
      attachedPhotos.add(file);
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < attachedPhotos.length) {
      attachedPhotos.removeAt(index);
    }
  }

  void clearPhotos() {
    attachedPhotos.clear();
  }

  final RxBool isCreatingTicket = false.obs;

  void updateNewTicket(String key, String value) {
    newTicket[key] = value;
    newTicket.refresh();
  }

  /// Fetch issue types from the API.
  Future<void> fetchIssueTypes() async {
    isLoadingIssueTypes.value = true;
    try {
      final result = await _ticketRepository.fetchIssueTypes();
      print('📋 [TicketsController] Fetched ${result.length} issue types');
      for (final t in result) {
        print('   - id=${t.id}, en="${t.issueTypeEn}", it="${t.issueTypeIt}"');
      }
      issueTypes.assignAll(result);
    } catch (e) {
      print('❌ [TicketsController] Error loading issue types: $e');
    } finally {
      isLoadingIssueTypes.value = false;
      print('📋 [TicketsController] isLoading=${isLoadingIssueTypes.value}, count=${issueTypes.length}');
    }
  }

  /// Create a new issue type via API, refresh the list, and return the model.
  Future<IssueTypeModel?> createIssueType({
    required String issueType,
    required String issueTypeIt,
  }) async {
    try {
      final result = await _ticketRepository.createIssueType(
        issueTypeEn: issueType,
        issueTypeIt: issueTypeIt,
      );

      if (result != null) {
        print('✅ [TicketsController] Issue type created: id=${result.id}, en="${result.issueTypeEn}"');
        await fetchIssueTypes();
        return result;
      }

      print('⚠️ [TicketsController] createIssueType returned null');
      return null;
    } catch (e) {
      print('❌ [TicketsController] Error creating issue type: $e');
      return null;
    }
  }

  /// Submits the new ticket to the API.
  /// Returns true on success, false on failure.
  Future<bool> handleCreateTicket(BuildContext? context) async {
    if (isCreatingTicket.value) return false;

    final issueTypeId = selectedCategoryId.value;
    final title = (newTicket['title'] ?? '').trim();
    final description = (newTicket['description'] ?? '').trim();
    final priority = (newTicket['priority'] ?? 'medium').trim();

    if (issueTypeId == null || description.isEmpty) {
      return false;
    }

    isCreatingTicket.value = true;
    try {
      final result = await _ticketRepository.createSupportTicket(
        title: title,
        description: description,
        issueTypeId: issueTypeId,
        priority: priority,
        image: attachedPhotos.isNotEmpty ? attachedPhotos.first : null,
      );

      if (result != null) {
        print('✅ [TicketsController] Ticket created successfully');
        clearPhotos();
        newTicket.assignAll({
          'category': '',
          'title': '',
          'description': '',
          'priority': 'medium',
        });
        selectedCategoryId.value = null;

        fetchMyTickets();

        if (context != null && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        MessagePopupController.showSuccess(
          titleKey: 'ticketSuccessTitle',
          messageKey: 'ticketSuccessMessage',
        );
        return true;
      }

      print('⚠️ [TicketsController] createSupportTicket returned null');
      return false;
    } catch (e) {
      print('❌ [TicketsController] Error creating ticket: $e');
      return false;
    } finally {
      isCreatingTicket.value = false;
    }
  }

  static const List<String> priorityValues = ['low', 'medium', 'high'];
  static final Map<String, String> _priorityKeys = {
    'low': 'priorityLow',
    'medium': 'priorityMedium',
    'high': 'priorityHighUrgent',
  };

  static String priorityLabel(String value) =>
      _priorityKeys[value]?.tr ?? value;

  final RxList<TicketModel> allTickets = <TicketModel>[].obs;
  final RxBool isLoadingTickets = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyTickets();
  }

  /// Fetch the user's support tickets from the API.
  Future<void> fetchMyTickets() async {
    isLoadingTickets.value = true;
    try {
      final result = await _ticketRepository.fetchMyTickets();
      print('🎫 [TicketsController] Fetched ${result.length} tickets');
      allTickets.assignAll(result);
    } catch (e) {
      print('❌ [TicketsController] Error loading tickets: $e');
    } finally {
      isLoadingTickets.value = false;
    }
  }

  List<TicketModel> get filteredTickets {
    if (filter.value == 'all') return allTickets;
    return allTickets.where((t) => t.status == filter.value).toList();
  }

  void setFilter(String value) {
    filter.value = value;
  }

  String tabLabel(String key) {
    if (key == 'all') return 'tutte'.tr;
    if (key == 'open') return 'open'.tr;
    if (key == 'in-progress') return 'inProgress'.tr;
    return 'resolved'.tr;
  }
}
