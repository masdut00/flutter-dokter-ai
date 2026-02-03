import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data'; 
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'UPH HealthAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // PERUBAHAN DISINI: Jangan langsung ke MainPage, tapi ke Satpam dulu
      home: const SplashPage(), 
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _cekLoginAwal();
  }

  void _cekLoginAwal() async {
    // Tunggu 2 detik biar logonya kelihatan (estetika)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      // Kalau sudah login, langsung ke Dashboard Utama
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MainPage())
      );
    } else {
      // Kalau belum, lempar ke Halaman Login Khusus
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("MediLife AI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white), // Loading muter-muter
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isRegisterMode = false;

  Future<void> _prosesLoginAtauRegister() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_isRegisterMode) {
      // LOGIKA REGISTER
      if (_userController.text.isEmpty || _passController.text.isEmpty) return;
      
      await prefs.setString('saved_username', _userController.text);
      await prefs.setString('saved_password', _passController.text);
      
      // Auto Login setelah daftar
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('username', _userController.text);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage()));
      
    } else {
      // LOGIKA LOGIN
      final savedUser = prefs.getString('saved_username');
      final savedPass = prefs.getString('saved_password');

      if (_userController.text == savedUser && _passController.text == savedPass) {
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('username', savedUser!);
        
        // Masuk ke Dashboard
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username/Password Salah!"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isRegisterMode ? Icons.person_add : Icons.lock_person, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(_isRegisterMode ? "Buat Akun Baru" : "Silakan Login", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 30),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _prosesLoginAtauRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: Text(_isRegisterMode ? "DAFTAR" : "MASUK"),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(_isRegisterMode ? "Sudah punya akun? Login" : "Belum punya akun? Daftar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// === KERANGKA UTAMA DENGAN NAVIGASI BAWAH ===
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeFeaturePage(),      
    const NutritionFeaturePage(), 
    const JournalFeaturePage(),   
    const ProfileFeaturePage(),   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Diet',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(Icons.history_edu),
            label: 'Jurnal',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// === HALAMAN 1: HOME (CEK KESEHATAN & INFO) ===
class HomeFeaturePage extends StatefulWidget {
  const HomeFeaturePage({super.key});

  @override
  State<HomeFeaturePage> createState() => _HomeFeaturePageState();
}

class _HomeFeaturePageState extends State<HomeFeaturePage> {
  String _namaUser = "User"; // Default sementara loading

  @override
  void initState() {
    super.initState();
    _ambilNamaUser();
  }

  // Fungsi untuk mengambil nama dari memori HP
  void _ambilNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil 'username', kalau null pakai 'Teman'
      _namaUser = prefs.getString('username') ?? "Teman";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("UPH HealthAI"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu Sambutan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal, Colors.teal.shade200]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BAGIAN INI YANG BERUBAH DINAMIS
                Text("Halo, $_namaUser! 👋", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Apa yang kamu rasakan hari ini?", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          const Text("Fitur AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          
          Row(
            children: [
              // Tombol 1: Cek Gejala (Kirim mode 'diagnosa')
              _buildMenuCard(
                context, 
                Icons.medical_services, 
                "Cek Gejala", 
                Colors.orange, 
                const ChatDoctorPage(mode: 'diagnosa') // <--- Perhatikan ini
              ), 
              
              const SizedBox(width: 10),
              
              // Tombol 2: Info Penyakit (Kirim mode 'info')
              _buildMenuCard(
                context, 
                Icons.search, 
                "Info Penyakit", 
                Colors.blue, 
                const ChatDoctorPage(mode: 'info') // <--- Perhatikan ini
              ), 
            ],
          ),
          
          const SizedBox(height: 10),

          Row(
            children: [
              _buildMenuCard(context, Icons.camera_alt, "Scan Makanan", Colors.purple, const FoodLensPage()), 
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()), 
            ],
          ),
        ], 
      ),
    );
  }

  // Fungsi helper untuk membuat kartu menu
  Widget _buildMenuCard(BuildContext context, IconData icon, String title, Color color, Widget destinationPage) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// === HALAMAN 2: DIET ===
class NutritionFeaturePage extends StatefulWidget {
  const NutritionFeaturePage({super.key});

  @override
  State<NutritionFeaturePage> createState() => _NutritionFeaturePageState();
}

class _NutritionFeaturePageState extends State<NutritionFeaturePage> {
  // GANTI DENGAN API KEY KAMU
  final String _apiKey = 'AIzaSyBejc1i1aYo2Zly_CvJa40LKJnznxKEWsk';

  // Controller untuk Input Data
  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _tbController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();
  
  String _targetDiet = 'Turun Berat Badan (Defisit Kalori)';
  String _hasilRencana = "";
  bool _isLoading = false;

  // Daftar Pilihan Target
  final List<String> _listTarget = [
    'Turun Berat Badan (Defisit Kalori)',
    'Menambah Otot (Bulking)',
    'Jaga Berat Badan (Maintain)',
    'Diet Rendah Gula (Diabetes Friendly)',
  ];

  Future<void> _buatRencanaDiet() async {
    // Validasi Input Sederhana
    if (_bbController.text.isEmpty || _tbController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi data berat dan tinggi badan dulu ya!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasilRencana = "";
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      // PROMPT ENGINEERING SPESIAL UNTUK AHLI GIZI
      final prompt = """
      Bertindaklah sebagai Ahli Gizi Profesional.
      Data Pasien:
      - Berat: ${_bbController.text} kg
      - Tinggi: ${_tbController.text} cm
      - Umur: ${_umurController.text} tahun
      - Target: $_targetDiet

      Tugas:
      1. Hitung kebutuhan kalori harian (BMR & TDEE) secara singkat.
      2. Buatkan Rencana Makan (Meal Plan) untuk 3 HARI SAJA (Contoh sampel) yang bervariasi.
      3. Format output harus rapi menggunakan Markdown (Gunakan Bold untuk Hari, dan List untuk menu).
      4. Berikan estimasi total kalori per hari.
      5. Gunakan bahan makanan yang mudah didapat di Indonesia (Tempe, Tahu, Ayam, Sayur Asem, dll).
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (!mounted) return;
      
      setState(() {
        _hasilRencana = response.text ?? "Gagal membuat rencana.";
      });

    } catch (e) {
      setState(() {
        _hasilRencana = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rencana Makan Pintar 🥗"),
        backgroundColor: Colors.green.shade100,
        actions: [
          // Tombol Reset
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasilRencana = "";
                _bbController.clear();
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // BAGIAN INPUT DATA (Formulir)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const Text("Profil Tubuh Kamu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bbController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Berat (kg)", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _tbController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Tinggi (cm)", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _umurController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Umur", border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _targetDiet,
                      decoration: const InputDecoration(labelText: "Target Kesehatan", border: OutlineInputBorder()),
                      items: _listTarget.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _targetDiet = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _buatRencanaDiet,
                        icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.auto_awesome),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12)
                        ),
                        label: Text(_isLoading ? "Sedang Meracik Menu..." : "Buatkan Rencana Makan!"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            // BAGIAN HASIL (Output AI)
            Expanded(
              child: _hasilRencana.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          const Text("Isi data di atas untuk mendapatkan\nmenu diet personalmu!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: SingleChildScrollView(
                        child: MarkdownBody(data: _hasilRencana),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// === HALAMAN 3: JURNAL ===
class JournalFeaturePage extends StatefulWidget {
  const JournalFeaturePage({super.key});

  @override
  State<JournalFeaturePage> createState() => _JournalFeaturePageState();
}

class _JournalFeaturePageState extends State<JournalFeaturePage> {
  // List untuk menampung data jurnal
  List<Map<String, dynamic>> _journalList = [];

  @override
  void initState() {
    super.initState();
    _loadJurnal(); // Load data saat halaman dibuka
  }

  // 1. Fungsi Membaca Data dari HP
  Future<void> _loadJurnal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('health_journal');
    
    if (dataString != null) {
      // Ubah string JSON kembali menjadi List
      setState(() {
        _journalList = List<Map<String, dynamic>>.from(jsonDecode(dataString));
      });
    }
  }

  // 2. Fungsi Menambah Catatan Baru
  Future<void> _tambahJurnal(Map<String, dynamic> dataBaru) async {
    setState(() {
      // Masukkan ke urutan paling atas (index 0) biar yang terbaru muncul duluan
      _journalList.insert(0, dataBaru);
    });
    
    // Simpan ke HP
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('health_journal', jsonEncode(_journalList));
  }

  // 3. Fungsi Menghapus Catatan
  Future<void> _hapusJurnal(int index) async {
    setState(() {
      _journalList.removeAt(index);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('health_journal', jsonEncode(_journalList));
  }

  // 4. Form Dialog untuk Input Data
  void _showAddDialog() {
    final noteController = TextEditingController();
    final bbController = TextEditingController();
    String selectedMood = 'Sehat 💪'; // Default

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Catat Kondisi Hari Ini"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pilihan Mood/Kondisi
                DropdownButtonFormField<String>(
                  value: selectedMood,
                  items: ['Sehat 💪', 'Sakit 😷', 'Lelah 😴', 'Stress 🤯', 'Pusing 🤕']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => selectedMood = val!,
                  decoration: const InputDecoration(labelText: "Kondisi Tubuh"),
                ),
                const SizedBox(height: 10),
                // Input Berat Badan
                TextField(
                  controller: bbController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Berat Badan (kg)", hintText: "Contoh: 60"),
                ),
                const SizedBox(height: 10),
                // Input Catatan
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Keluhan / Catatan", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                // Buat Data Map
                final now = DateTime.now();
                // Format tanggal sederhana: 16 Jan 2026
                final dateString = "${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute}";
                
                final newData = {
                  'date': dateString,
                  'mood': selectedMood,
                  'bb': bbController.text.isEmpty ? '-' : '${bbController.text} kg',
                  'note': noteController.text.isEmpty ? 'Tidak ada catatan' : noteController.text,
                };

                _tambahJurnal(newData);
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekam Medis Harian 📔"),
        backgroundColor: Colors.blue.shade100,
      ),
      // Tampilkan List
      body: _journalList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Belum ada riwayat kesehatan.\nTekan + untuk mencatat.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _journalList.length,
              itemBuilder: (context, index) {
                final data = _journalList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(data['mood'].split(' ').last, style: const TextStyle(fontSize: 20)), // Ambil Emojinya saja
                    ),
                    title: Text(data['mood'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${data['date']}"),
                        Text("📝 ${data['note']}"),
                        if (data['bb'] != '-') Text("⚖️ Berat: ${data['bb']}", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _hapusJurnal(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// === HALAMAN 4: PROFIL ===
class ProfileFeaturePage extends StatefulWidget {
  const ProfileFeaturePage({super.key});

  @override
  State<ProfileFeaturePage> createState() => _ProfileFeaturePageState();
}

class _ProfileFeaturePageState extends State<ProfileFeaturePage> {
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadNama();
  }

  void _loadNama() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "User";
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false); // Hapus sesi login

    // Tendang balik ke Halaman Login Awal
    // pushReplacement menghapus tombol 'Back' biar user gak bisa balik tanpa login
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 60, backgroundColor: Colors.teal, child: Icon(Icons.person, size: 60, color: Colors.white)),
              const SizedBox(height: 20),
              Text("Halo, $_userName!", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Member MediLife Premium", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              
              // Kartu Info Status
              Card(
                color: Colors.teal.shade50,
                child: const ListTile(
                  leading: Icon(Icons.verified_user, color: Colors.teal),
                  title: Text("Akun Terverifikasi"),
                  subtitle: Text("Data kesehatan tersimpan aman di perangkat ini."),
                ),
              ),
              
              const Spacer(),
              
              // Tombol Logout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("KELUAR / LOGOUT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100, 
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// === HALAMAN KHUSUS CHAT DOKTER ===
class ChatDoctorPage extends StatefulWidget {
  // Tambahkan variabel ini untuk menerima 'Misi'
  final String mode; // Isinya nanti 'diagnosa' atau 'info'

  const ChatDoctorPage({super.key, required this.mode});

  @override
  State<ChatDoctorPage> createState() => _ChatDoctorPageState();
}

class _ChatDoctorPageState extends State<ChatDoctorPage> {
  final String _apiKey = 'AIzaSyBejc1i1aYo2Zly_CvJa40LKJnznxKEWsk'; // API KEY KAMU

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  String _userName = "Teman";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "Teman";
    });
  }

  Future<void> _kirimPesan() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _chatHistory.add({"role": "user", "text": _textController.text});
      _isLoading = true;
    });

    _scrollToBottom();
    final pertanyaanUser = _textController.text;
    _textController.clear();

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      
      // Rangkum chat history
      String historyContext = "";
      for (var chat in _chatHistory) {
        historyContext += "${chat['role'] == 'user' ? 'User' : 'AI'}: ${chat['text']}\n";
      }

      // === LOGIKA PEMBAGIAN KEPRIBADIAN (DISINI KUNCINYA) ===
      String systemInstruction = "";

      if (widget.mode == 'diagnosa') {
        // --- KEPRIBADIAN 1: DOKTER (Cek Gejala) ---
        systemInstruction = """
        Peran: Kamu adalah 'Dr. AI', dokter virtual profesional.
        Tugas: Mendiagnosa keluhan pasien bernama $_userName.
        
        Aturan:
        1. Analisis keluhan pasien (Penyebab, Perawatan, Tanda Bahaya).
        2. Gunakan bahasa yang empatik dan menenangkan.
        3. Ingat konteks percakapan sebelumnya:
        $historyContext
        """;
      } else {
        // --- KEPRIBADIAN 2: ENSIKLOPEDIA (Info Penyakit) ---
        systemInstruction = """
        Peran: Kamu adalah 'Ensiklopedia Medis Pintar'.
        Tugas: Menjelaskan informasi penyakit kepada $_userName secara lengkap.
        
        Aturan:
        1. JANGAN mendiagnosa user. Fokus pada definisi, gejala umum, penyebab, dan pencegahan penyakit yang ditanyakan.
        2. Gunakan gaya bahasa edukatif, jelas, dan terstruktur (seperti dosen/wiki).
        3. Jika user bertanya "Saya sakit apa?", jawab: "Silakan gunakan fitur Cek Gejala untuk diagnosa."
        4. Ingat konteks:
        $historyContext
        """;
      }

      final prompt = "$systemInstruction\n\nPertanyaan Baru: $pertanyaanUser";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (!mounted) return; // Anti Crash

      final jawabanAI = response.text ?? "Maaf, error.";

      setState(() {
        _chatHistory.add({"role": "model", "text": jawabanAI});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatHistory.add({"role": "model", "text": "Error: $e"});
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan Judul & Sapaan berdasarkan Mode
    final bool isDiagnosa = widget.mode == 'diagnosa';
    final String judul = isDiagnosa ? "Konsultasi Dokter 🩺" : "Ensiklopedia Penyakit 📚";
    final String sapaan = isDiagnosa 
        ? "Halo $_userName! Keluhan apa yang kamu rasakan?" 
        : "Halo $_userName! Mau cari info penyakit apa?";
    final String hint = isDiagnosa ? "Contoh: Kepala pusing..." : "Contoh: Diabetes, Tifus...";

    return Scaffold(
      appBar: AppBar(
        title: Text(judul),
        backgroundColor: isDiagnosa ? Colors.teal.shade100 : Colors.blue.shade100,
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Text(sapaan, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = _chatHistory[index];
                      final isUser = chat['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(15),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? (isDiagnosa ? Colors.teal : Colors.blue) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                          ),
                          child: isUser
                              ? Text(chat['text']!, style: const TextStyle(color: Colors.white))
                              : MarkdownBody(data: chat['text']!),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(), // Loading bar kecil
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _kirimPesan(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isLoading ? null : _kirimPesan,
                  backgroundColor: isDiagnosa ? Colors.teal : Colors.blue,
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodLensPage extends StatefulWidget {
  const FoodLensPage({super.key});

  @override
  State<FoodLensPage> createState() => _FoodLensPageState();
}

class _FoodLensPageState extends State<FoodLensPage> {
  // GANTI API KEY KAMU DI SINI
  final String _apiKey = 'AIzaSyBejc1i1aYo2Zly_CvJa40LKJnznxKEWsk';
  
  // Kita ganti File (dart:io) dengan Uint8List (Memory) agar jalan di Web
  Uint8List? _imageBytes; 
  String _result = "";
  bool _isLoading = false;

  // Fungsi Buka Galeri (Support Web & Mobile)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Pick image
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Baca gambar sebagai Bytes (Data Digital) langsung
      final bytes = await pickedFile.readAsBytes();
      
      setState(() {
        _imageBytes = bytes; // Simpan di memori
        _result = ""; // Reset hasil lama
      });
    }
  }

  // Fungsi Analisis AI
  Future<void> _analyzeFood() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      
      // Prompt khusus Vision
      final prompt = TextPart("""
      Kamu adalah Ahli Gizi AI. Analisis gambar makanan ini.
      Berikan output berupa tabel/list:
      1. Nama Makanan (Tebak dengan akurat)
      2. Estimasi Kalori (Total)
      3. Kandungan Gizi Utama (Karbo, Protein, Lemak)
      4. Apakah ini sehat? Berikan rating 1-10.
      
      Jika gambar bukan makanan, katakan: "Maaf, ini bukan gambar makanan."
      """);

      // Kirim Gambar (Bytes) + Teks ke Gemini
      final imagePart = DataPart('image/jpeg', _imageBytes!);
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (!mounted) return;

      setState(() {
        _result = response.text ?? "Gagal menganalisis.";
      });

    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Lens 📸"), backgroundColor: Colors.orange.shade100),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Area Preview Gambar
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey),
              ),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("Belum ada foto makanan"),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Pilih Foto (Galeri)"),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      // PENTING: Gunakan Image.memory bukan Image.file
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    ),
            ),
            
            const SizedBox(height: 20),

            // Tombol Analisis
            if (_imageBytes != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _analyzeFood,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? "Sedang Menganalisis..." : "Cek Kalori Sekarang!"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),

            // Hasil Analisis
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade200),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
                ),
                child: MarkdownBody(data: _result),
              ),
          ],
        ),
      ),
    );
  }
}