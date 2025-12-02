import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  bool _isCreateDialogOpen = false;
  File? _selectedFile;
  late AnimationController _fabController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = '';
  String _selectedFrequency = '';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Animate FAB on init
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _fabController.dispose();
    super.dispose();
  }

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
        'Ispezione annuale e sostituzione dei filtri per il sistema di riscaldamento, ventilazione e climatizzazione. Richiesto per la conformitÃ  alla garanzia e per garantire l\'efficienza energetica ottimale.',
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
        title: 'Controllo Pressione Caldaia',
        category: 'Riscaldamento',
        description:
        'Controllo di routine della pressione e ottimizzazione del sistema. Raccomandato per prestazioni ottimali ed efficienza energetica.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 6 mesi',
        nextDue: '15 Nov 2025',
        lastCompleted: '10 Mag 2025',
      ),
      MaintenanceTask(
        id: '3',
        title: 'Ispezione Sicurezza Ascensore',
        category: 'Sistemi Edificio',
        description:
        'Ispezione di sicurezza obbligatoria secondo le normative edilizie. Gestito dall\'amministratore condominiale.',
        priority: MaintenancePriority.condominiali,
        status: MaintenanceStatus.inProgress,
        frequency: 'Annualmente',
        nextDue: '8 Nov 2025',
        attachments: [
          TaskAttachment(
              name: 'Certificato_Sicurezza.pdf', type: 'PDF', url: '#'),
        ],
        contacts: [
          TaskContact(
            name: 'SafeLift Italia',
            role: 'Ispettore Certificato',
            phone: '+39 02 9876 5432',
          ),
        ],
      ),
      MaintenanceTask(
        id: '4',
        title: 'Sostituzione Batterie Rilevatori di Fumo',
        category: 'Sicurezza',
        description:
        'Sostituire le batterie in tutti i rilevatori di fumo per garantire il corretto funzionamento. Requisito di sicurezza critico.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 12 mesi',
        nextDue: '20 Nov 2025',
        lastCompleted: '18 Nov 2024',
      ),
      MaintenanceTask(
        id: '5',
        title: 'Manutenzione Scaldabagno',
        category: 'Idraulica',
        description:
        'Decalcificazione e controllo dell\'efficienza. Aiuta a prevenire guasti e prolunga la vita dell\'apparecchiatura.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 18 mesi',
        nextDue: '1 Dic 2025',
        lastCompleted: '1 Giu 2024',
      ),
      MaintenanceTask(
        id: '6',
        title: 'Ispezione Guarnizioni Finestre',
        category: 'Involucro Edificio',
        description:
        'Controllare e mantenere le guarnizioni delle finestre per l\'efficienza energetica. Raccomandato prima della stagione invernale.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Annualmente',
        nextDue: '5 Nov 2025',
      ),
      MaintenanceTask(
        id: '7',
        title: 'Controllo Estintori',
        category: 'Sicurezza',
        description:
        'Ispezione annuale obbligatoria di tutte le attrezzature antincendio.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.pending,
        frequency: 'Annualmente',
        nextDue: '12 Nov 2025',
        lastCompleted: '10 Nov 2024',
        contacts: [
          TaskContact(name: 'FireSafe Solutions', role: 'Ispettore Sicurezza'),
        ],
      ),
      MaintenanceTask(
        id: '8',
        title: 'Aggiornamento Illuminazione Aree Comuni',
        category: 'Sistemi Edificio',
        description:
        'Progetto di aggiornamento LED per corridoi e spazi comuni dell\'edificio. Gestito dall\'amministratore.',
        priority: MaintenancePriority.condominiali,
        status: MaintenanceStatus.pending,
        frequency: 'Progetto una tantum',
        nextDue: '25 Nov 2025',
      ),
    ];
  }

  List<MaintenanceTask> _getFilteredTasks() {
    final allTasks = _getMockTasks();
    if (_activeFilter == 'all') return allTasks;

    return allTasks.where((task) {
      switch (_activeFilter) {
        case 'personal':
          return task.priority == MaintenancePriority.personal;
        case 'facoltative':
          return task.priority == MaintenancePriority.facoltative;
        case 'obbligatorie':
          return task.priority == MaintenancePriority.obbligatorie;
        case 'condominiali':
          return task.priority == MaintenancePriority.condominiali;
        case 'pending':
          return task.status == MaintenanceStatus.pending;
        case 'overdue':
          return task.status == MaintenanceStatus.overdue;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _handleCreateTask() {
    print('Creating task: ${_titleController.text}');
    setState(() {
      _isCreateDialogOpen = false;
      _titleController.clear();
      _notesController.clear();
      _selectedCategory = '';
      _selectedFrequency = '';
      _selectedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    // NO SCAFFOLD - This screen is wrapped by MainScaffold
    return Stack(
      children: [
        Column(
          children: [
            // Filter Pills
            _buildFilterBar(),

            // Tasks List
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(filteredTasks[index], index);
                },
              ),
            ),
          ],
        ),

        // Floating Action Button
        _buildFAB(),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'Tutte', 'count': 14},
      {'id': 'personal', 'label': 'Personal', 'count': 2},
      {'id': 'facoltative', 'label': 'Facoltative', 'count': 3},
      {'id': 'obbligatorie', 'label': 'Obbligatorie', 'count': 5},
      {'id': 'condominiali', 'label': 'Condominiali', 'count': 4},
      {'id': 'pending', 'label': 'In Attesa', 'count': 6},
      {'id': 'overdue', 'label': 'Scadute', 'count': 2},
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
                          color: isActive ? Colors.white : Colors.grey.shade700,
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
                  selectedColor: const Color(0xFF6B8E23),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFF6B8E23)
                        : Colors.grey.shade300,
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
                                    color:
                                    _getStatusTextColor(task.status)
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
                          'â€¢',
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
                                        const Color(0xFF6B8E23)
                                            .withOpacity(0.2),
                                        const Color(0xFF6B8E23)
                                            .withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    size: 16,
                                    color: Color(0xFF6B8E23),
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
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        file.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade100,
                                        Colors.blue.shade50,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
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
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () {
                                            // Handle phone call
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 14,
                                                color: Color(0xFF6B8E23),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                contact.phone!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF6B8E23),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (contact.email != null) ...[
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () {
                                            // Handle email
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.email_outlined,
                                                size: 14,
                                                color: Color(0xFF6B8E23),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                contact.email!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF6B8E23),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Action Buttons
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              print('Mark complete: ${task.id}');
                            },
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Segna Completato'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8E23),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              print('Schedule: ${task.id}');
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('Programma'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onAskAI,
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 16),
                            label: const Text('Chiedi AI'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
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
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (index * 50).ms);
  }

  Widget _buildFAB() {
    return Positioned(
      bottom: 96,
      right: 24,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isCreateDialogOpen = true;
            });
            _showCreateDialog();
          },
          backgroundColor: const Color(0xFF4CAF47),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Maintenance Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a personal maintenance task to track',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Title
              const Text('Title',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Filter replacement',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  hintText: 'Select category',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'appliances', child: Text('Appliances')),
                  DropdownMenuItem(value: 'hvac', child: Text('HVAC')),
                  DropdownMenuItem(value: 'plumbing', child: Text('Plumbing')),
                  DropdownMenuItem(value: 'electrical', child: Text('Electrical')),
                  DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Frequency
              const Text('Frequency',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFrequency.isEmpty ? null : _selectedFrequency,
                decoration: const InputDecoration(
                  hintText: 'Select frequency',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                  DropdownMenuItem(
                      value: 'biannually', child: Text('Every 6 months')),
                  DropdownMenuItem(value: 'annually', child: Text('Annually')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes
              const Text('Notes (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add any additional details...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // File Upload
              const Text('Attachment (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F7).withOpacity(0.5),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFile == null
                      ? Column(
                    children: [
                      Icon(Icons.upload_file,
                          color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Attach file or photo',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      const Icon(Icons.attach_file,
                          color: Color(0xFF6A8F7B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isCreateDialogOpen = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _titleController.text.isEmpty ||
                _selectedCategory.isEmpty ||
                _selectedFrequency.isEmpty
                ? null
                : () {
              _handleCreateTask();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A8F7B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

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