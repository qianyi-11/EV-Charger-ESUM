import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/floating_orbs.dart';
import '../services/ticket_service.dart';
import '../services/auth_service.dart';
import '../models/support_ticket.dart';
import 'new_ticket_screen.dart';

class MyTicketScreen extends StatefulWidget {
  const MyTicketScreen({super.key});

  @override
  State<MyTicketScreen> createState() => _MyTicketScreenState();
}

class _MyTicketScreenState extends State<MyTicketScreen> {
  final TicketService _ticketService = TicketService.instance;

  @override
  void initState() {
    super.initState();
    _ticketService.addListener(_onTicketsChanged);
    AuthService.instance.addListener(_onAuthChanged);
    _ticketService.load();
  }

  @override
  void dispose() {
    _ticketService.removeListener(_onTicketsChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onTicketsChanged() {
    if (mounted) setState(() {});
  }

  void _onAuthChanged() {
    _ticketService.load();
  }

  Future<void> _openNewTicket() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewTicketScreen()),
    );
    if (created == true) {
      await _ticketService.load();
    }
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'complete':
        return 'Complete';
      default:
        return 'Open';
    }
  }

  String _issueTypeLabel(SupportTicket ticket) {
    if (ticket.issueType != null && ticket.issueType!.isNotEmpty) {
      return ticket.issueType!;
    }
    if (ticket.describeIssue != null && ticket.describeIssue!.isNotEmpty) {
      return ticket.describeIssue!;
    }
    return ticket.faultyComponent;
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;
    final tickets = _ticketService.tickets;

    return Scaffold(
      backgroundColor: adaptive.background,
      body: FloatingOrbsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tickets',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: adaptive.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tickets created under your account',
                  style: TextStyle(color: adaptive.textSecondary),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _openNewTicket,
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      'New Ticket',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: tickets.isEmpty
                      ? Center(
                          child: GlassContainer(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 48,
                                  color: AppColors.electricBlue.withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tickets yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: adaptive.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap New Ticket to create a support request.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: adaptive.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: tickets.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final adaptive = context.adaptive;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ticketRow('Ticket ID', ticket.ticketIdLabel, adaptive),
          const SizedBox(height: 10),
          _ticketRow('Issue type', _issueTypeLabel(ticket), adaptive),
          const SizedBox(height: 10),
          _ticketRow('Status', _formatStatus(ticket.status), adaptive),
          const SizedBox(height: 10),
          _ticketRow('Date', _formatDate(ticket.createdAt), adaptive),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value, AdaptiveTheme adaptive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              color: adaptive.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: adaptive.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
