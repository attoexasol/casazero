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

  void updateNewTicket(String key, String value) {
    newTicket[key] = value;
    newTicket.refresh();
  }

  /// Fetch issue types from the API.
  Future<void> fetchIssueTypes() async {
    isLoadingIssueTypes.value = true;
    try {
      final result = await _ticketRepository.fetchIssueTypes();
      issueTypes.assignAll(result);
    } catch (e) {
      print('❌ [TicketsController] Error loading issue types: $e');
    } finally {
      isLoadingIssueTypes.value = false;
    }
  }

  /// Create a new issue type. Currently a local stub; API integration to follow.
  Future<IssueTypeModel?> createIssueType({
    required String issueType,
    required String issueTypeIt,
  }) async {
    try {
      // TODO: Replace with actual API call, e.g.:
      // final result = await _ticketRepository.createIssueType(
      //   issueType: issueType,
      //   issueTypeIt: issueTypeIt,
      // );
      // if (result != null) { ... }

      // For now, create a local entry with a temporary negative id.
      final tempId = -(DateTime.now().millisecondsSinceEpoch);
      final newType = IssueTypeModel(id: tempId, issueType: issueType);
      issueTypes.add(newType);
      return newType;
    } catch (e) {
      print('❌ [TicketsController] Error creating issue type: $e');
      return null;
    }
  }

  /// Called when user taps Create Ticket in the dialog. Pops the dialog.
  void handleCreateTicket(BuildContext? context) {
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    MessagePopupController.showSuccess(
      titleKey: 'ticketSuccessTitle',
      messageKey: 'ticketSuccessMessage',
    );
  }

  static const List<String> priorityValues = ['low', 'medium', 'high'];
  static final Map<String, String> _priorityKeys = {
    'low': 'priorityLow',
    'medium': 'priorityMedium',
    'high': 'priorityHighUrgent',
  };

  static String priorityLabel(String value) =>
      _priorityKeys[value]?.tr ?? value;

  static final List<TicketModel> allTickets = [
    const TicketModel(
      id: '1',
      title: 'Bathroom sink faucet leaking',
      category: 'Plumbing',
      description:
          'The main bathroom sink faucet has a slow leak that needs attention.',
      status: 'in-progress',
      priority: 'high',
      created: 'Oct 30, 2025',
      updated: '2 hours ago',
      attachments: 2,
      updates: 3,
      assignedTo: 'Mario Rossi - Plumber',
      createdBy: 'Marco (Unit 4B)',
    ),
    const TicketModel(
      id: '2',
      title: 'Living room light switch not working',
      category: 'Electrical',
      description: 'The main light switch in the living room is unresponsive.',
      status: 'open',
      priority: 'medium',
      created: 'Nov 1, 2025',
      updated: '1 day ago',
      attachments: 1,
      createdBy: 'Marco (Unit 4B)',
    ),
    const TicketModel(
      id: '3',
      title: 'Window condensation issue',
      category: 'Building Envelope',
      description: 'Excessive condensation forming on bedroom windows.',
      status: 'resolved',
      priority: 'low',
      created: 'Oct 15, 2025',
      updated: '5 days ago',
      attachments: 3,
      updates: 5,
      assignedTo: 'Giuseppe Verdi - Building Manager',
      createdBy: 'Marco (Unit 4B)',
    ),
    const TicketModel(
      id: '4',
      title: 'Common area heating not working',
      category: 'HVAC',
      description: 'Hallway heating system needs attention.',
      status: 'open',
      priority: 'high',
      created: 'Nov 2, 2025',
      updated: '3 hours ago',
      createdBy: 'Lucia (Unit 2A)',
    ),
  ];

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
