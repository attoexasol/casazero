import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class Ticket {
  final String id;
  final String subject;
  final String status; // 'open', 'in-progress', 'resolved'
  final String date;
  final String category;

  Ticket({
    required this.id,
    required this.subject,
    required this.status,
    required this.date,
    required this.category,
  });
}

class SuggestedPrompt {
  final IconData icon;
  final String text;
  final String category;

  SuggestedPrompt({
    required this.icon,
    required this.text,
    required this.category,
  });
}

class AIScreen extends StatefulWidget {
  const AIScreen({Key? key}) : super(key: key);

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _loading = false;
  bool _showAssistance = true;

  late AnimationController _iconRotationController;

  @override
  void initState() {
    super.initState();

    // Initialize with greeting message
    _messages.add(Message(
      id: '1',
      role: 'assistant',
      content: 'Ciao! Come posso aiutarti oggi?',
      timestamp: DateTime.now(),
    ));

    // Icon rotation animation
    _iconRotationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _iconRotationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    if (_inputController.text.trim().isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: _inputController.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _loading = true;
      _showAssistance = false;
    });

    _inputController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      final aiMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content:
        'Capisco che stai chiedendo informazioni su ${userMessage.content}. In base ai dati della tua residenza, posso aiutarti. Questa Ã¨ una risposta demo che mostra come CasaZero AI fornirebbe informazioni contestuali sulla tua casa, documenti e necessitÃ  di manutenzione.',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _loading = false;
      });
      _scrollToBottom();
    });
  }

  void _handlePromptClick(String prompt) {
    _inputController.text = prompt;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.amber.shade100;
      case 'in-progress':
        return Colors.blue.shade100;
      case 'resolved':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'open':
        return Colors.amber.shade700;
      case 'in-progress':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Aperto';
      case 'in-progress':
        return 'In Corso';
      case 'resolved':
        return 'Risolto';
      default:
        return status;
    }
  }

  List<SuggestedPrompt> _getSuggestedPrompts() {
    return [
      SuggestedPrompt(
        icon: Icons.description,
        text: 'Dove posso trovare il mio contratto?',
        category: 'Documenti',
      ),
      SuggestedPrompt(
        icon: Icons.build,
        text: 'Quando Ã¨ prevista la prossima manutenzione?',
        category: 'Manutenzione',
      ),
      SuggestedPrompt(
        icon: Icons.bolt,
        text: 'Come posso ridurre il mio consumo energetico?',
        category: 'Energia',
      ),
      SuggestedPrompt(
        icon: Icons.description,
        text: 'Quali documenti servono per le tasse?',
        category: 'Documenti',
      ),
    ];
  }

  List<Ticket> _getRecentTickets() {
    return [
      Ticket(
        id: 'T-001',
        subject: 'Rumore eccessivo dall\'unitÃ  superiore',
        status: 'in-progress',
        date: '2 Nov 2025',
        category: 'Disturbo',
      ),
      Ticket(
        id: 'T-002',
        subject: 'Perdita d\'acqua nel bagno',
        status: 'resolved',
        date: '28 Ott 2025',
        category: 'Idraulica',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // NO SCAFFOLD - This screen is wrapped by MainScaffold
    return Column(
      children: [
        // Premium Header
        _buildHeader(),

        // Messages Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0) + (_showAssistance && _messages.length == 1 ? 1 : 0),
            itemBuilder: (context, index) {
              // Show assistance section
              if (_showAssistance && _messages.length == 1 && index == _messages.length) {
                return _buildAssistanceSection();
              }

              // Show loading indicator
              if (index == _messages.length) {
                return _buildLoadingIndicator();
              }

              // Show message
              final message = _messages[index];
              return _buildMessageBubble(message, index);
            },
          ),
        ),

        // Input Area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Animated AI Icon
                  AnimatedBuilder(
                    animation: _iconRotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: ((_iconRotationController.value * 2) % 1) * 0.175, // ~10 degrees oscillation
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF6B8E23),
                                const Color(0xFF9ACD32),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B8E23).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CasaZero AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Il tuo assistente intelligente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B8E23).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le risposte AI sono generate in base ai dati della tua residenza. Per decisioni critiche, verifica con documenti ufficiali.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B8E23), Color(0xFF556B2F)],
          )
              : null,
          color: isUser ? null : Colors.white,
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CasaZero AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isUser ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: isUser ? Colors.white70 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF6B8E23),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sto pensando...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildAssistanceSection() {
    final tickets = _getRecentTickets();
    final prompts = _getSuggestedPrompts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Assistenza Header
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B8E23).withOpacity(0.2),
                    const Color(0xFF6B8E23).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                size: 18,
                color: Color(0xFF6B8E23),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Assistenza',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // New Ticket Button
        InkWell(
          onTap: () {
            // Handle new ticket
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B8E23).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuova Richiesta di Assistenza',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Apri un ticket di supporto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 16),

        // Recent Tickets
        if (tickets.isNotEmpty) ...[
          Text(
            'Ticket Recenti',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...tickets.asMap().entries.map((entry) {
            final idx = entry.key;
            final ticket = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  // Handle ticket tap
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.subject,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.id,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStatusText(ticket.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusTextColor(ticket.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket.date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'â€¢',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ticket.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (200 + idx * 100).ms)
                .slideY(begin: 0.2, end: 0);
          }).toList(),
          const SizedBox(height: 24),
        ],

        // Suggested Prompts
        Text(
          'Esempi di Domande:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ...prompts.asMap().entries.map((entry) {
          final idx = entry.key;
          final prompt = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _handlePromptClick(prompt.text),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6B8E23).withOpacity(0.2),
                            const Color(0xFF6B8E23).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        prompt.icon,
                        size: 20,
                        color: const Color(0xFF6B8E23),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B8E23).withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFF6B8E23).withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prompt.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B8E23),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (400 + idx * 100).ms)
              .slideY(begin: 0.1, end: 0);
        }).toList(),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: 'Chiedimi qualsiasi cosa sulla tua casa...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F7).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF6B8E23).withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6B8E23),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B8E23), Color(0xFF556B2F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B8E23).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_inputController.text.trim().isEmpty || _loading)
                        ? null
                        : _handleSend,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.send,
                        color: (_inputController.text.trim().isEmpty || _loading)
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms);
  }
}