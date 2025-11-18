import 'package:flutter/material.dart';

class BrandingPreviewPage extends StatelessWidget {
  const BrandingPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CitySmart Branding Preview',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF7CA726),
        foregroundColor: const Color(0xFF0B0C10),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Header(),
          SizedBox(height: 16),
          _SectionHeader('Palette'),
          _Palette(),
          SizedBox(height: 10),
          _SectionHeader('Typography'),
          _Typography(),
          SizedBox(height: 16),
          _SectionHeader('Buttons'),
          _Buttons(),
          SizedBox(height: 16),
          _SectionHeader('Chips'),
          _Chips(),
          SizedBox(height: 16),
          _SectionHeader('Input & Cards'),
          _InputCard(),
          SizedBox(height: 16),
          _SectionHeader('Module Tiles'),
          _Tiles(),
          SizedBox(height: 16),
          _SectionHeader('Ad Placeholder (Banner)'),
          _AdPlaceholder(),
          SizedBox(height: 24),
          _Footer(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override Widget build(BuildContext context){
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF7CA726), Color(0xFF5E8A45)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Center(
        child: Text('CitySmart',
          style: TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w700,
            fontSize: 36, color: Color(0xFFE0B000))),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette();
  @override Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 12, children: const [
    _ColorTile('Primary #7CA726', Color(0xFF7CA726)),
    _ColorTile('Secondary #5E8A45', Color(0xFF5E8A45)),
    _ColorTile('Accent #E0B000', Color(0xFFE0B000)),
    _ColorTile('Text #1A1A1A', Color(0xFF1A1A1A)),
    _ColorTile('BG #FDFDFD', Color(0xFFFDFDFD), outlined: true),
  ]);
}

class _Typography extends StatelessWidget {
  const _Typography();
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('H1 — Poppins Bold 28',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 28)),
      SizedBox(height: 6),
      Text('H2 — Poppins Bold 22',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22)),
      SizedBox(height: 6),
      Text('Body — Inter Regular 16. Clean, modern, legible.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
    ]
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();
  @override Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 12, children: [
    ElevatedButton.icon(
      onPressed: (){}, icon: const Icon(Icons.directions_car),
      label: const Text('Parking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0B000),
        foregroundColor: const Color(0xFF0B0C10),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
      ),
    ),
    OutlinedButton.icon(
      onPressed: (){}, icon: const Icon(Icons.delete_outline),
      label: const Text('Garbage'),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0B000), width: 1.5),
        foregroundColor: const Color(0xFFE0B000),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    ),
    TextButton.icon(
      onPressed: (){}, icon: const Icon(Icons.flash_on),
      label: const Text('EV Chargers'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5E8A45),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    ),
  ]);
}

class _Chips extends StatelessWidget {
  const _Chips();
  @override Widget build(BuildContext context) => Wrap(spacing: 10, children: const [
    Chip(label: Text('Tow Alert'), avatar: Icon(Icons.local_towing, size: 18)),
    Chip(label: Text('Snow Emergency'), avatar: Icon(Icons.ac_unit, size: 18)),
    Chip(label: Text('Reminder'), avatar: Icon(Icons.notifications_active, size: 18)),
  ]);
}

class _InputCard extends StatelessWidget {
  const _InputCard();
  @override Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFE0B000), width: 1.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Address', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: '123 W Main St',
            hintStyle: TextStyle(fontFamily: 'Inter'),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7CA726)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0B000), width: 2),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            suffixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: 10),
        Text('Tip: set garbage reminders in Settings → Notifications.',
            style: TextStyle(fontFamily: 'Inter', color: Colors.black54)),
      ]),
    ),
  );
}

class _Tiles extends StatelessWidget {
  const _Tiles();
  @override Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 12, children: const [
    _Tile(icon: Icons.local_parking, label: 'Parking', color: Color(0xFFE0B000)),
    _Tile(icon: Icons.delete_sweep_outlined, label: 'Garbage', color: Color(0xFF7CA726)),
    _Tile(icon: Icons.electrical_services, label: 'EV', color: Color(0xFF1ABC9C)),
    _Tile(icon: Icons.handyman_outlined, label: 'Maintenance', color: Colors.orangeAccent),
    _Tile(icon: Icons.receipt_long_outlined, label: 'Tickets', color: Colors.deepPurpleAccent),
  ]);
}

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();
  @override Widget build(BuildContext context) => Container(
    height: 56,
    decoration: BoxDecoration(
      color: Colors.black12, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black26),
    ),
    child: const Center(
      child: Text('AdMob Banner (ca-app-pub-xxxx/yyyy)',
        style: TextStyle(fontFamily: 'Inter', color: Colors.black54)),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override Widget build(BuildContext context){
    return Align(
      alignment: Alignment.center,
      child: Text('Smarter Cities. Connected Communities.',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text; const _SectionHeader(this.text, {super.key});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
    child: Text(text,
      style: const TextStyle(
        fontFamily: 'Poppins', fontWeight: FontWeight.w700,
        fontSize: 18, color: Color(0xFF1A1A1A))),
  );
}

class _ColorTile extends StatelessWidget {
  final String label; final Color color; final bool outlined;
  const _ColorTile(this.label, this.color, {this.outlined=false, super.key});
  @override Widget build(BuildContext context) => Container(
    width: 170, height: 56,
    decoration: BoxDecoration(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: outlined ? color : Colors.transparent, width: 1.5),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(label,
      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
        color: outlined ? color : _on(color))),
  );

  Color _on(Color c){
    final y = (299*c.red + 587*c.green + 114*c.blue)/1000;
    return y > 128 ? Colors.black87 : Colors.white;
  }
}

class _Tile extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _Tile({required this.icon, required this.label, required this.color, super.key});
  @override Widget build(BuildContext context) => Container(
    width: 150, height: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 1.5),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color),
      SizedBox(height: 6),
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
    ]),
  );
}
