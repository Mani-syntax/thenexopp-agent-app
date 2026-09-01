import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'KYC';
  String _selectedPriority = 'MEDIUM';
  bool _isSubmitting = false;

  bool _isLoadingTickets = true;
  List<dynamic> _myTickets = [];
  String? _errorMessage;

  static const String _supportHelpline = '+918977505204';
  static const String _displayHelpline = '+91 89775 05204';

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
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          _errorMessage = 'Unable to fetch your support tickets';
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _callSupportHelpline() async {
    final uri = Uri.parse('tel:$_supportHelpline');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
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
        final ticketNum = ticketData?['ticketNumber'] ?? 'TKT-NEW';

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
                  _tabController.animateTo(1);
                  _fetchMyTickets();
                },
                child: const Text('View My Tickets'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit ticket. Please check connection and retry.'), backgroundColor: AppColors.statusError),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryEmerald,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primaryEmerald,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Raise Ticket & Call'),
            Tab(text: 'My Tickets History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRaiseTicketTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildRaiseTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Phone Call Helpline Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryEmeraldDark, AppColors.primaryEmerald],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryEmerald.withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Support Helpline',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _displayHelpline,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Partner executive assistance',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _callSupportHelpline,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.primaryEmeraldDark),
                  label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmeraldDark)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryEmeraldDark,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Issue Category', prefixIcon: Icon(Icons.category_rounded)),
                    items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 18),

                  // Priority Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority Level', prefixIcon: Icon(Icons.flag_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low Priority')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium / Normal')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High Priority')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent (Immediate Help)')),
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
                    validator: (val) => val == null || val.trim().length < 10 ? 'Please enter at least 10 characters' : null,
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
        onAction: () => _tabController.animateTo(0),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
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
