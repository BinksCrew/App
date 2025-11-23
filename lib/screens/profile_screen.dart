import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController(text: "AshKetchum123");
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('username') ?? "AshKetchum123";
      _passwordController.text = prefs.getString('password') ?? "";
      _phoneController.text = prefs.getString('phone') ?? "";
      _idController.text = prefs.getString('id') ?? "";
      _imagePath = prefs.getString('imagePath');
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('phone', _phoneController.text);
    await prefs.setString('id', _idController.text);
    if (_imagePath != null) {
      await prefs.setString('imagePath', _imagePath!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado exitosamente!'),
          backgroundColor: Color(0xFFE4000F),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _shareProfile() {
    final String text = 'Mira mi perfil de Entrenador Pokémon!\n\n'
        'Usuario: ${_usernameController.text}\n'
        'Teléfono: ${_phoneController.text}\n'
        'Descarga la app aquí: https://github.com/BinksCrew/App';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/anime.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _imagePath != null
                                    ? FileImage(File(_imagePath!)) as ImageProvider
                                    : const AssetImage('assets/defaultpfp.webp'),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4000F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _usernameController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Entrenador Pokémon',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Form Fields
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE4000F),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person,
                          readOnly: true,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _idController,
                          label: 'Cédula / ID',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE4000F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: const BorderSide(color: Colors.black, width: 3),
                              elevation: 0,
                            ),
                            child: const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _shareProfile,
                            icon: const Icon(Icons.share),
                            label: const Text(
                              'COMPARTIR PERFIL',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: const BorderSide(color: Colors.black, width: 3),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE4000F), width: 3),
        ),
      ),
    );
  }
}