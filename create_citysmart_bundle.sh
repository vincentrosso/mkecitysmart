#!/usr/bin/env bash
set -euo pipefail

APP_DIR="CitySmart_App_Bundle"
ZIP_NAME="CitySmart_App_Bundle.zip"

echo "Creating $APP_DIR ..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/backend/routes" "$APP_DIR/lib/citysmart" "$APP_DIR/assets/brand" "$APP_DIR/assets/fonts" "$APP_DIR/docs"

# ---------------- README ----------------
cat > "$APP_DIR/CITYSMART_README.md" <<'EOF'
# CitySmart App Source Bundle (v1.6)
Complete FastAPI + Flutter bundle for the CitySmart application.
Includes:
- Backend APIs for parking, EV, garbage, notifications
- Flutter widgets for UI (splash, map legend, prediction bar)
- Branding (colors, fonts, logo)
- Branding Preview Screen (branding_preview.dart)
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="CitySmart_App_Bundle"
ZIP_NAME="CitySmart_App_Bundle.zip"

echo "Creating $APP_DIR ..."
rm -rf "$APP_DIR" "$ZIP_NAME"
mkdir -p "$APP_DIR"

# --- clone structure ---
mkdir -p "$APP_DIR/backend/routes" "$APP_DIR/lib/citysmart" "$APP_DIR/assets/brand" "$APP_DIR/assets/fonts" "$APP_DIR/docs"

# --- README ---
cat > "$APP_DIR/CITYSMART_README.md" <<'EOF'
# CitySmart App Source Bundle (v1.6)
Complete FastAPI + Flutter bundle for the CitySmart application.
Includes:
- Backend APIs for parking, garbage, EV, notifications
- Flutter widgets for UI & splash screens
- Branding (colors, fonts, logo)
EOF

# --- Minimal backend example ---
cat > "$APP_DIR/backend/main.py" <<'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI(title="CitySmart Backend", version="1.6")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
@app.get("/health") 
def health(): 
    return {"ok": True, "service": "citysmart-backend"}
EOF

cat > "$APP_DIR/backend/requirements.txt" <<'EOF'
fastapi
uvicorn[standard]
SQLAlchemy
requests
python-multipart
EOF

# --- Flutter folder (UI stubs) ---
cat > "$APP_DIR/lib/citysmart/theme.dart" <<'EOF'
import 'package:flutter/material.dart';
class CSTheme {
  static const primary = Color(0xFF7CA726);
  static const secondary = Color(0xFF5E8A45);
  static const accent = Color(0xFFE0B000);
  static ThemeData theme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary),
    fontFamily: 'Inter',
  );
}
EOF

cat > "$APP_DIR/lib/citysmart/splash_screen.dart" <<'EOF'
import 'dart:math';
import 'package:flutter/material.dart';
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashState(); }
class _SplashState extends State<SplashScreen>{
  late bool showSpinner;
  @override void initState(){ super.initState(); showSpinner = Random().nextBool();
    Future.delayed(const Duration(seconds: 2), ()=> Navigator.pushReplacementNamed(context, '/home')); }
  @override Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors:[Color(0xFF7CA726), Color(0xFF5E8A45)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('CitySmart', style: TextStyle(fontSize: 32, color: Color(0xFFE0B000), fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          if (showSpinner) const CircularProgressIndicator(color: Color(0xFFE0B000), strokeWidth: 3)
          else Container(width: 140, height: 6, color: Colors.white24, alignment: Alignment.centerLeft,
            child: Container(width: 120, height: 6, color: const Color(0xFFE0B000))),
        ])),
      ),
    );
  }
}
EOF

# --- Branding ---
cat > "$APP_DIR/assets/brand/color_theme.json" <<'EOF'
{ "primary":"#7CA726", "secondary":"#5E8A45", "accent":"#E0B000", "text":"#1A1A1A", "background":"#FDFDFD" }
EOF

cat > "$APP_DIR/assets/brand/logo_primary.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<rect width="512" height="512" rx="72" fill="#7CA726"/>
<text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle"
font-family="Poppins, Arial" font-size="180" font-weight="700" fill="#E0B000">P</text>
</svg>
EOF

# --- Fonts (download from Google Fonts) ---
curl -L -o "$APP_DIR/assets/fonts/Poppins-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf
curl -L -o "$APP_DIR/assets/fonts/Poppins-Bold.ttf" https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf
curl -L -o "$APP_DIR/assets/fonts/Inter-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bslnt,wght%5D.ttf
curl -L -o "$APP_DIR/assets/fonts/Inter-SemiBold.ttf" https://github.com/google/fonts/raw/main/ofl/inter/static/Inter-SemiBold.ttf

# --- Docs ---
cat > "$APP_DIR/docs/INTEGRATION_STEPS.md" <<'EOF'
# Integration Steps

1. Place bundle contents into your repository root:
   - backend/
   - lib/citysmart/
   - assets/brand/
   - assets/fonts/
   - docs/

2. Backend quickstart:
   - python3 -m venv .venv
   - source .venv/bin/activate
   - pip install -r backend/requirements.txt
   - uvicorn backend.main:app --reload --port 8000

3. Flutter wiring (if not already present):
   - Add a route '/branding' that navigates to BrandingPreviewPage
   - Add a Drawer item "Branding Preview" that calls Navigator.pushNamed('/branding')
   - In pubspec.yaml add:
     - assets: assets/brand/, assets/fonts/
     - fonts: Poppins and Inter families (weights as provided)

4. Run app:
   - flutter pub get
   - flutter run

5. Notes:
   - Fonts: Poppins, Inter
   - Theme colors in assets/brand/color_theme.json

EOF

# --- Zip the bundle ---
zip -qr "$ZIP_NAME" "$APP_DIR"

# --- Summary ---
BUNDLE_SIZE=$(du -h "$ZIP_NAME" | awk '{print $1}')
echo "✅ Created $ZIP_NAME (${BUNDLE_SIZE})"
ls -la "$APP_DIR" | sed 's/^/  /'
    if (d != null) setState(()=> _when = DateTime(d.year, d.month, d.day, _when.hour));
  }
  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour:_when.hour, minute:0));
    if (t != null) setState(()=> _when = DateTime(_when.year, _when.month, _when.day, t.hour));
  }
  @override Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF0B0C10).withOpacity(.85),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0B000), width: 1.5)),
      child: Row(children: [
        InkWell(onTap: _pickDate, child: const Icon(Icons.calendar_month, color: Color(0xFFE0B000))),
        const SizedBox(width: 8),
        InkWell(onTap: _pickTime, child: const Icon(Icons.access_time, color: Color(0xFFE0B000))),
        const Spacer(),
        TextButton.icon(
          style: TextButton.styleFrom(backgroundColor: const Color(0xFFE0B000), foregroundColor: const Color(0xFF0B0C10)),
          onPressed: ()=> widget.onApply(_when),
          icon: const Icon(Icons.refresh),
          label: const Text("Preview"),
        ),
      ]),
    );
  }
}
EOF

# Branding preview screen
cat > "$APP_DIR/lib/citysmart/branding_preview.dart" <<'EOF'
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
EOF

# ---------------- Branding ----------------
cat > "$APP_DIR/assets/brand/color_theme.json" <<'EOF'
{ "primary":"#7CA726", "secondary":"#5E8A45", "accent":"#E0B000", "text":"#1A1A1A", "background":"#FDFDFD" }
EOF

cat > "$APP_DIR/assets/brand/logo_primary.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<rect width="512" height="512" rx="72" fill="#7CA726"/>
<text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle"
font-family="Poppins, Arial" font-size="180" font-weight="700" fill="#E0B000">P</text>
</svg>
EOF

# ---------------- Fonts (download) ----------------
curl -L -o "$APP_DIR/assets/fonts/Poppins-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf
curl -L -o "$APP_DIR/assets/fonts/Poppins-Bold.ttf" https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf
curl -L -o "$APP_DIR/assets/fonts/Inter-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bslnt,wght%5D.ttf
curl -L -o "$APP_DIR/assets/fonts/Inter-SemiBold.ttf" https://github.com/google/fonts/raw/main/ofl/inter/static/Inter-SemiBold.ttf

# ---------------- Docs ----------------
cat > "$APP_DIR/docs/INTEGRATION_STEPS.md" <<'EOF'
# Integration Steps
1) Place contents into your repo root.
2) Backend:
   python -m venv .venv && source .venv/bin/activate
   pip install -r backend/requirements.txt
   uvicorn backend.main:app --reload
3) Flutter:
   Add dependencies to pubspec.yaml (http, google_maps_flutter, firebase_core, firebase_messaging, etc.)
   flutter pub get && flutter run
4) (Optional) Fonts are in assets/fonts and referenced by branding/demo screens.
EOF

# ---------------- Zip it ----------------
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$APP_DIR" >/dev/null
echo "✅ Created $ZIP_NAME in $(pwd)"
