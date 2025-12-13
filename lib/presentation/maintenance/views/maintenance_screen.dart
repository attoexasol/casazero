// presentation/maintenance/views/maintenance_screen.dart
// COMPLETE MAINTENANCE SCREEN - WITH REACT-STYLE DIALOG (100% UI MATCH)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

// ============================================================================
// MODELS
// ============================================================================

enum MaintenancePriority { facoltative, obbligatorie, condominiali, personal }

enum MaintenanceStatus { pending, inProgress, completed, overdue }

class MaintenanceTask {
  final String id;
  final String title;
  final String category;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String frequency;
  final String? nextDue;
  final List<TaskAttachment>? attachments;
  final List<TaskContact>? contacts;
  final String? lastCompleted;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.frequency,
    this.nextDue,
    this.attachments,
    this.contacts,
    this.lastCompleted,
  });
}

class TaskAttachment {
  final String name;
  final String type;
  final String url;

  TaskAttachment({
    required this.name,
    required this.type,
    required this.url,
  });
}

class TaskContact {
  final String name;
  final String role;
  final String? phone;
  final String? email;

  TaskContact({
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class MaintenanceScreen extends StatefulWidget {
  final String role; // 'client', 'admin', 'super-admin'
  final VoidCallback onAskAI;

  const MaintenanceScreen({
    Key? key,
    required this.role,
    required this.onAskAI,
  }) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'all';
  String? _expandedCard;
  late AnimationController _fabController;

  // Dialog form state
  String _taskTitle = '';
  String _selectedCategory = '';
  String _selectedFrequency = '';
  String _taskNotes = '';
  File? _selectedFile;

  // Categories
  final List<Map<String, String>> _maintenanceCategories = [
    {'value': 'hvac', 'label': 'HVAC'},
    {'value': 'plumbing', 'label': 'Plumbing'},
    {'value': 'electrical', 'label': 'Electrical'},
    {'value': 'appliances', 'label': 'Appliances'},
    {'value': 'exterior', 'label': 'Exterior'},
    {'value': 'other', 'label': 'Other'},
  ];

  // Frequency options
  final List<Map<String, String>> _frequencyOptions = [
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'quarterly', 'label': 'Quarterly'},
    {'value': 'biannual', 'label': 'Bi-annual'},
    {'value': 'annual', 'label': 'Annual'},
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ============================================================================
  // PRIORITY & STATUS STYLING
  // ============================================================================

  Map<MaintenancePriority, Map<String, Color>> get _priorityColors => {
        MaintenancePriority.facoltative: {
          'bg': const Color(0xFFCFE2D7),
          'text': const Color(0xFF2D5F3F),
          'border': const Color(0xFFA8C9B5),
        },
        MaintenancePriority.obbligatorie: {
          'bg': const Color(0xFFFFE6B3),
          'text': const Color(0xFF8B5E00),
          'border': const Color(0xFFF4D399),
        },
        MaintenancePriority.condominiali: {
          'bg': const Color(0xFFD7E2EA),
          'text': const Color(0xFF2C5F7F),
          'border': const Color(0xFFB5CFE0),
        },
        MaintenancePriority.personal: {
          'bg': const Color(0xFFE8F5E9),
          'text': const Color(0xFF6A8F7B),
          'border': const Color(0xFF6A8F7B),
        },
      };

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.amber.shade100;
      case MaintenanceStatus.inProgress:
        return Colors.blue.shade100;
      case MaintenanceStatus.completed:
        return Colors.green.shade100;
      case MaintenanceStatus.overdue:
        return Colors.red.shade100;
    }
  }

  Color _getStatusTextColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.amber.shade700;
      case MaintenanceStatus.inProgress:
        return Colors.blue.shade700;
      case MaintenanceStatus.completed:
        return Colors.green.shade700;
      case MaintenanceStatus.overdue:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'In Attesa';
      case MaintenanceStatus.inProgress:
        return 'In Corso';
      case MaintenanceStatus.completed:
        return 'Completato';
      case MaintenanceStatus.overdue:
        return 'Scaduto';
    }
  }

  String _getPriorityLabel(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.facoltative:
        return 'Facoltative';
      case MaintenancePriority.obbligatorie:
        return 'Obbligatorie';
      case MaintenancePriority.condominiali:
        return 'Condominiali';
      case MaintenancePriority.personal:
        return 'Personal';
    }
  }

  // ============================================================================
  // MOCK DATA
  // ============================================================================

  List<MaintenanceTask> _getMockTasks() {
    return [
      MaintenanceTask(
        id: 'p1',
        title: 'Filter Replacement - Kitchen Hood',
        category: 'Appliances',
        description:
            'Replace grease filters in kitchen ventilation hood for optimal performance.',
        priority: MaintenancePriority.personal,
        status: MaintenanceStatus.pending,
        frequency: 'Every 3 months',
        nextDue: '10 Nov 2025',
        lastCompleted: '10 Aug 2025',
      ),
      MaintenanceTask(
        id: 'p2',
        title: 'Fridge Coil Cleaning',
        category: 'Appliances',
        description:
            'Clean refrigerator coils to improve efficiency and reduce energy consumption.',
        priority: MaintenancePriority.personal,
        status: MaintenanceStatus.inProgress,
        frequency: 'Every 6 months',
        nextDue: '5 Dec 2025',
        attachments: [
          TaskAttachment(name: 'cleaning_guide.pdf', type: 'PDF', url: '#'),
        ],
      ),
      MaintenanceTask(
        id: '1',
        title: 'Ispezione Annuale Sistema HVAC',
        category: 'Climatizzazione',
        description:
            'Ispezione annuale e sostituzione dei filtri per il sistema di riscaldamento, ventilazione e climatizzazione.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.overdue,
        frequency: 'Annualmente',
        nextDue: '30 Ott 2025',
        lastCompleted: '28 Ott 2024',
        attachments: [
          TaskAttachment(
              name: 'Certificato_Ispezione_2024.pdf', type: 'PDF', url: '#'),
          TaskAttachment(name: 'Manuale_HVAC.pdf', type: 'PDF', url: '#'),
        ],
        contacts: [
          TaskContact(
            name: 'TechClima Services',
            role: 'Specialista HVAC',
            phone: '+39 02 1234 5678',
            email: 'info@techclima.it',
          ),
        ],
      ),
      MaintenanceTask(
        id: '2',
        title: 'Controllo Sicurezza Ascensore',
        category: 'Struttura',
        description:
            'Ispezione annuale obbligatoria dell\'ascensore per la sicurezza e la certificazione.',
        priority: MaintenancePriority.condominiali,
        status: MaintenanceStatus.completed,
        frequency: 'Annualmente',
        nextDue: '15 Gen 2026',
        lastCompleted: '15 Gen 2025',
      ),
      MaintenanceTask(
        id: '3',
        title: 'Pulizia Grondaie e Sistema di Drenaggio',
        category: 'Esterno',
        description:
            'Rimozione di detriti e controllo del corretto funzionamento delle grondaie.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Semestrale',
        nextDue: '1 Dic 2025',
      ),
    ];
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final tasks = _getMockTasks();
    final filteredTasks = _activeFilter == 'all'
        ? tasks
        : tasks
            .where((t) =>
                _getPriorityLabel(t.priority).toLowerCase() == _activeFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(filteredTasks[index], index)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * index))
                              .slideY(begin: 0.1, end: 0);
                        },
                      ),
              ),
            ],
          ),
          _buildFAB(),
        ],
      ),
    );
  }

  // ============================================================================
  // FILTER BAR
  // ============================================================================

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'Tutte', 'count': 5},
      {'id': 'personal', 'label': 'Personal', 'count': 2},
      {'id': 'facoltative', 'label': 'Facoltative', 'count': 1},
      {'id': 'obbligatorie', 'label': 'Obbligatorie', 'count': 1},
      {'id': 'condominiali', 'label': 'Condominiali', 'count': 1},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: filters.map((filter) {
              final isActive = _activeFilter == filter['id'];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isActive,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isActive ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filter['count']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xff388E3C),
                  side: BorderSide(
                    color:
                        isActive ? const Color(0xFF6A8F7B) : Colors.grey.shade300,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _activeFilter = filter['id'] as String;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TASK CARD
  // ============================================================================

  Widget _buildTaskCard(MaintenanceTask task, int index) {
    final isExpanded = _expandedCard == task.id;
    final isOverdue = task.status == MaintenanceStatus.overdue;
    final priorityStyle = _priorityColors[task.priority]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: Colors.red.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedCard = isExpanded ? null : task.id;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact View
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges and Expand Icon
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Priority Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityStyle['bg'],
                                  border: Border.all(
                                    color: priorityStyle['border']!,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getPriorityLabel(task.priority),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: priorityStyle['text'],
                                  ),
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(task.status),
                                  border: Border.all(
                                    color: _getStatusTextColor(task.status)
                                        .withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getStatusLabel(task.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusTextColor(task.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category and Frequency
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.frequency,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dates
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (task.nextDue != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isOverdue
                                    ? Colors.red.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Scadenza: ${task.nextDue}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red.shade600
                                      : Colors.grey.shade600,
                                  fontWeight: isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        if (task.lastCompleted != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ultima: ${task.lastCompleted}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expanded Detail View
              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                Container(
                  color: const Color(0xFFFAF9F7).withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Description
                      Text(
                        'Descrizione Completa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      // Attachments
                      if (task.attachments != null &&
                          task.attachments!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Allegati',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...task.attachments!.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF6A8F7B).withOpacity(0.2),
                                        const Color(0xFF6A8F7B).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    size: 16,
                                    color: Color(0xFF6A8F7B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        file.type,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.file_download_outlined,
                                  size: 18,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Contacts
                      if (task.contacts != null &&
                          task.contacts!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Contatti',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...task.contacts!.map((contact) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  contact.role,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (contact.phone != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        contact.phone!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (contact.email != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        contact.email!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      // Action Buttons
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Mark as complete
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: const Color(0xFF6A8F7B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Segna Completato',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A8F7B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onAskAI,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A8F7B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Chiedi a AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FLOATING ACTION BUTTON
  // ============================================================================

  Widget _buildFAB() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: const Color(0xff388E3C),
          elevation: 4,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // REACT-STYLE CREATE DIALOG - 100% UI MATCH
  // ============================================================================

  void _showCreateDialog() {
    // Reset form state
    _taskTitle = '';
    _selectedCategory = '';
    _selectedFrequency = '';
    _taskNotes = '';
    _selectedFile = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildDialogHeader(),

                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleInput(setState),
                            const SizedBox(height: 16),
                            _buildCategoryDropdown(setState),
                            const SizedBox(height: 16),
                            _buildFrequencyDropdown(setState),
                            const SizedBox(height: 16),
                            _buildNotesInput(setState),
                            const SizedBox(height: 16),
                            _buildFileUpload(setState),
                          ],
                        ),
                      ),

                      // Footer with buttons
                      _buildDialogFooter(context),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Maintenance Task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a personal maintenance task to track',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() {
              _taskTitle = value;
            });
          },
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Filter replacement',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6A8F7B),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              hint: Text(
                'Select category',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: _maintenanceCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['value'],
                  child: Text(category['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedFrequency.isEmpty ? null : _selectedFrequency,
              hint: Text(
                'Select frequency',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: _frequencyOptions.map((frequency) {
                return DropdownMenuItem<String>(
                  value: frequency['value'],
                  child: Text(frequency['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() {
              _taskNotes = value;
            });
          },
          maxLines: 3,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'Add any additional details...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6A8F7B),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFile(setState),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7).withOpacity(0.5),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedFile != null
                ? _buildSelectedFile(setState)
                : _buildFileUploadPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadPlaceholder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.upload_rounded,
          size: 20,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          'Attach file or photo',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFile(StateSetter setState) {
    final fileName = _selectedFile!.path.split('/').last;
    final fileSize = _selectedFile!.lengthSync();
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);

    return Row(
      children: [
        const Icon(
          Icons.attach_file_rounded,
          size: 20,
          color: Color(0xFF6A8F7B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$fileSizeMB MB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            setState(() {
              _selectedFile = null;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(StateSetter setState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDialogFooter(BuildContext context) {
    final isFormValid = _taskTitle.isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _selectedFrequency.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel Button
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Create Button
          ElevatedButton(
            onPressed: isFormValid ? () => _handleCreateTask(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFormValid ? const Color(0xFF6A8F7B) : Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateTask(BuildContext context) {
    final taskData = {
      'title': _taskTitle,
      'category': _selectedCategory,
      'frequency': _selectedFrequency,
      'notes': _taskNotes,
      'file': _selectedFile?.path,
    };

    print('Creating maintenance task: $taskData');

    // TODO: Call your API or controller
    // Example: await _controller.createMaintenanceTask(taskData);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Maintenance task created successfully'),
        backgroundColor: const Color(0xFF6A8F7B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Refresh the maintenance list
    // _controller.fetchMaintenanceTasks();
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Maintenance Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first maintenance task to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}