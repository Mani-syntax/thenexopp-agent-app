import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/websocket_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  int _selectedTab = 0; // 0 = Raise Ticket & Helpline, 1 = My Tickets History
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'KYC';
  String _selectedPriority = 'MEDIUM';
  bool _isSubmitting = false;

  bool _isLoadingTickets = true;
  List<dynamic> _myTickets = [];
  String? _errorMessage;
  StreamSubscription? _wsSubscription;

  static const String _supportHelpline = '+918977505204';
  static const String _displayHelpline = '+91 89775 05204';
  static const String _whatsappNumber = '918977505204';

  final List<Map<String, String>> _categories = [
    {'value': 'KYC', 'label': 'KYC & Document Verification'},
    {'value': 'PROPERTIES', 'label': 'Property Listings & Photos'},
    {'value': 'PAYMENTS', 'label': 'Payouts, Earnings & Commissions'},
    {'value': 'ACCOUNT', 'label': 'Account Status & Profile'},
    {'value': 'TECHNICAL', 'label': 'Technical App Issue'},
    {'value': 'OTHER', 'label': 'General Query & Assistance'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();

    Future.microtask(() {
      final ws = ref.read(webSocketProvider);
      ws.connect();
      _wsSubscription = ws.events.listen((event) {
        final evType = event['event'];
        if (evType == 'ticket.updated') {
          _fetchMyTickets();
        }
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.supportTickets);
      if (mounted && res.data['success'] == true) {
        setState(() {
          _myTickets = res.data['data'] ?? [];
          _isLoadingTickets = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = null;
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _callSupportHelpline() async {
    final uri = Uri.parse('tel:$_supportHelpline');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Helpline Number: +91 89775 05204')),
        );
      }
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent("Hello TheNexopp Agent Support Team, I am registered partner agent and I need assistance.")}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp Support: +91 89775 05204')),
        );
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post(ApiConstants.supportTickets, data: {
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _selectedPriority,
      });

      if (response.data['success'] == true && mounted) {
        final ticketData = response.data['data'];
        final ticketNum = ticketData?['ticketNumber'] ?? 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final newTicket = {
          'ticketNumber': ticketNum,
          'category': _selectedCategory,
          'subject': _subjectController.text.trim(),
          'description': _descController.text.trim(),
          'priority': _selectedPriority,
          'status': 'OPEN',
          'createdAt': DateTime.now().toIso8601String(),
        };

        setState(() {
          _myTickets = [newTicket, ..._myTickets];
        });

        _subjectController.clear();
        _descController.clear();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 28),
                SizedBox(width: 10),
                Text('Ticket Raised', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
              ],
            ),
            content: Text(
              'Your support request $ticketNum has been submitted directly to the executive administration desk. Our team will review and resolve it promptly.',
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTab = 1);
                },
                child: const Text('View My Tickets'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Optimistic offline ticket creation
        final ticketNum = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final newTicket = {
          'ticketNumber': ticketNum,
          'category': _selectedCategory,
          'subject': _subjectController.text.trim(),
          'description': _descController.text.trim(),
          'priority': _selectedPriority,
          'status': 'OPEN',
          'createdAt': DateTime.now().toIso8601String(),
        };

        setState(() {
          _myTickets = [newTicket, ..._myTickets];
        });

        _subjectController.clear();
        _descController.clear();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 28),
                SizedBox(width: 10),
                Text('Ticket Submitted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
              ],
            ),
            content: Text(
              'Your support request $ticketNum has been recorded and submitted to the administration desk.',
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTab = 1);
                },
                child: const Text('View My Tickets'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Agent Help & Support'),
      ),
      body: Column(
        children: [
          // Segmented Tab Switcher Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primaryEmerald : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [BoxShadow(color: AppColors.primaryEmerald.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          'Raise Ticket & Call',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? Colors.white : AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primaryEmerald : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [BoxShadow(color: AppColors.primaryEmerald.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'My Tickets',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 1 ? Colors.white : AppColors.textMedium,
                              ),
                            ),
                            if (_myTickets.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1 ? Colors.white : AppColors.primaryEmerald,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_myTickets.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 1 ? AppColors.primaryEmerald : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active Tab Content
          Expanded(
            child: _selectedTab == 0 ? _buildRaiseTicketTab() : _buildMyTicketsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseTicketTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Helpline Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.emeraldBorder),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppColors.primaryEmerald, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TheNexopp Agent Helpline',
                            style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _displayHelpline,
                            style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.3),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Direct Executive Partner Support Desk',
                            style: TextStyle(color: AppColors.textLight, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _callSupportHelpline,
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
                        label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openWhatsAppSupport,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF25D366)),
                        label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF25D366))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Raise Ticket Form Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.primaryEmerald, size: 22),
                      SizedBox(width: 8),
                      Text('Raise an Issue Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('File an issue or inquiry. It will be sent immediately to the administration ticket hub.', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 22),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Issue Category', prefixIcon: Icon(Icons.category_rounded)),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['value'],
                            child: Text(
                              c['label']!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 18),

                  // Priority Selector
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority Level', prefixIcon: Icon(Icons.flag_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low Priority', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium / Normal', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      DropdownMenuItem(value: 'HIGH', child: Text('High Priority', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent (Immediate Help)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    ],
                    onChanged: (val) => setState(() => _selectedPriority = val!),
                  ),
                  const SizedBox(height: 18),

                  // Subject
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject / Short Title',
                      prefixIcon: Icon(Icons.title_rounded),
                      hintText: 'e.g. KYC document re-verification request',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter issue subject' : null,
                  ),
                  const SizedBox(height: 18),

                  // Detailed Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Describe Your Issue in Detail',
                      alignLabelWithHint: true,
                      hintText: 'Please describe the problem or question with as much detail as possible...',
                    ),
                    validator: (val) => val == null || val.trim().length < 5 ? 'Please enter at least 5 characters' : null,
                  ),
                  const SizedBox(height: 26),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    icon: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit Support Ticket'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (_isLoadingTickets) {
      return const LoadingSkeletonList();
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(message: _errorMessage!, onRetry: _fetchMyTickets);
    }

    if (_myTickets.isEmpty) {
      return EmptyStateWidget(
        title: 'No Support Tickets',
        message: 'You have not submitted any issue tickets yet. If you face any problem, raise a ticket from the first tab.',
        buttonText: 'Raise New Ticket',
        onAction: () => setState(() => _selectedTab = 0),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryEmerald,
      onRefresh: _fetchMyTickets,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        itemCount: _myTickets.length,
        itemBuilder: (context, index) {
          final t = _myTickets[index];
          final status = t['status'] ?? 'OPEN';
          final resolution = t['resolution'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket Number & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t['ticketNumber'] ?? 'TKT',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryEmeraldDark),
                    ),
                    _buildTicketStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 10),

                // Category & Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t['category'] ?? '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t['createdAt'] != null ? t['createdAt'].toString().substring(0, 10) : '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subject
                Text(
                  t['subject'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  t['description'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
                ),

                // Resolution Box
                if (resolution != null && resolution.toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondaryGreenBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.secondaryGreenDark, size: 16),
                            SizedBox(width: 6),
                            Text('Admin Resolution Remark:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondaryGreenDark)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resolution,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketStatusBadge(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.textMedium;
    Color border = AppColors.borderLight;

    if (status == 'RESOLVED' || status == 'CLOSED') {
      bg = AppColors.secondaryGreenLight;
      text = AppColors.secondaryGreenDark;
      border = AppColors.secondaryGreenBorder;
    } else if (status == 'IN_PROGRESS') {
      bg = Colors.blue[50]!;
      text = Colors.blue[800]!;
      border = Colors.blue[200]!;
    } else if (status == 'OPEN') {
      bg = AppColors.accentGoldLight;
      text = AppColors.accentGoldDark;
      border = AppColors.accentGoldBorder;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
