import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../habits/habit_db.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  int _streak = 0;
  int _totalRoutines = 0;
  int _totalHabits = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final routines = await HabitDB.getAllRoutines();
    int habitCount = 0;
    for (final r in routines) {
      final habits = await HabitDB.getHabitsForRoutine(r.id);
      habitCount += habits.length;
    }
    final streak = await HabitDB.getCurrentStreak();

    setState(() {
      _totalRoutines = routines.length;
      _totalHabits = habitCount;
      _streak = streak;
    });
  }

  String get _initials {
    final name = _user?.displayName ?? _user?.email ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      children: [
        // ── AVATAR + NAME ─────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                child: _user?.photoURL == null
                    ? Text(
                        _initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                _user?.displayName ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── STATS ROW ─────────────────────────────────
        Row(
          children: [
            _StatCard(
              label: 'Streak',
              value: '$_streak 🔥',
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Routines',
              value: '$_totalRoutines',
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Habits',
              value: '$_totalHabits',
              color: Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── SETTINGS SECTION ──────────────────────────
        _SectionHeader(label: 'ACCOUNT'),
        const SizedBox(height: 8),

        _SettingsTile(
          icon: Icons.person_outline,
          label: 'Display name',
          subtitle: _user?.displayName ?? 'Not set',
          onTap: () => _editDisplayName(),
        ),

        _SettingsTile(
          icon: Icons.email_outlined,
          label: 'Email',
          subtitle: _user?.email ?? '',
          onTap: null, // read-only for now
        ),

        const SizedBox(height: 24),

        _SectionHeader(label: 'PREFERENCES'),
        const SizedBox(height: 8),

        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Manage alarm & reminder settings',
          onTap: () {}, // placeholder
        ),

        const SizedBox(height: 32),

        // ── LOGOUT ────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _user?.displayName ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _user?.updateDisplayName(controller.text.trim());
      setState(() {}); // refresh display
    }
  }
}

// ── STAT CARD ──────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION HEADER ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

// ── SETTINGS TILE ──────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withOpacity(0.3),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
