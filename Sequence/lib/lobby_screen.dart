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

  // Opret nyt rum
  Future<void> _createRoom() async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final userId = 'player1'; // senere erstattes med rigtig login

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
      _message = 'Rum oprettet! Kode: $code\nDel den med din ven!';
    });
  }

  // Join med kode
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
      _message = 'Du er nu med i rum $code!\nSpillet starter snart...';
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
              child: const Text('Opret nyt rum'),
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
              child: const Text('Join med kode'),
            ),
            const SizedBox(height: 30),
            Text(_message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
