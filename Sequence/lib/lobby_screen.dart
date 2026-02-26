import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  String _message = '';
  String? _currentRoomCode;

  // Opret nyt rum
  Future<void> _createRoom() async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final userId = 'player_${DateTime.now().millisecondsSinceEpoch}';

    await _supabase.from('game_rooms').insert({
      'code': code,
      'host_id': userId,
      'players': [userId],
      'board': List.filled(100, null),
      'hands': {},
      'current_turn': 0,
      'status': 'waiting',
    });

    setState(() {
      _currentRoomCode = code;
      _message = 'Rum oprettet!\nKode: $code\nDel med din ven!';
    });

    // Start realtime lytning
    _listenToRoom(code);
  }

  // Join rum
  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _message = 'Koden skal være 6 tegn');
      return;
    }

    final rooms = await _supabase.from('game_rooms').select().eq('code', code);
    if (rooms.isEmpty) {
      setState(() => _message = 'Rum ikke fundet – tjek koden!');
      return;
    }

    setState(() {
      _currentRoomCode = code;
      _message = 'Du er med i rum $code!\nSpillet starter snart...';
    });

    _listenToRoom(code);
  }

  // Realtime lytning (ser ændringer fra modstander)
  void _listenToRoom(String code) {
    _supabase
        .from('game_rooms')
        .stream(primaryKey: ['code'])
        .eq('code', code)
        .listen((data) {
          if (data.isNotEmpty) {
            final room = data.first;
            setState(() {
              _message = 'Rum opdateret!\nSpillere: ${room['players'].length}\nStatus: ${room['status']}';
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wild Jacks Online')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text('Opret nyt rum', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Indtast 6-cifret kode',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text('Join med kode', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 30),
            if (_currentRoomCode != null)
              Text('Aktivt rum: $_currentRoomCode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            const Text('Del koden med en ven og vent på at spillet starter!', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
