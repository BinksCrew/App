import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Read only usually
  final _cedulaController = TextEditingController(); // Read only usually

  File? _imageFile;
  String? _currentImageUrl;
  String? _userId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  // Game stats
  Map<String, dynamic>? _gameStats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get fresh data from server
      final userData = await _apiService.getUserProfile();
      final gameStats = await _apiService.getGameStats();
      
      if (userData != null) {
        // Save updated data locally
        await _apiService.saveUserData(userData);
        
        setState(() {
          _userId = userData['id'];
          _fullNameController.text = userData['fullName'] ?? '';
          _usernameController.text = userData['username'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _cedulaController.text = userData['cedula'] ?? '';
          _currentImageUrl = userData['photo_url']; // Assuming API returns photo_url
          _gameStats = gameStats;
          _isLoading = false;
        });
      } else {
        // Handle case where no user data is found (should redirect to login)
        _logout();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, String> fields = {};
      if (_fullNameController.text.isNotEmpty) fields['fullName'] = _fullNameController.text;
      if (_usernameController.text.isNotEmpty) fields['username'] = _usernameController.text;
      if (_phoneController.text.isNotEmpty) fields['phone'] = _phoneController.text;
      
      if (_userId != null) {
        await _apiService.updateUser(_userId!, fields, _imageFile);
        
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          _loadUserData(); // Reload to get fresh data (e.g. new image URL)
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _imageFile = null;
                  _loadUserData(); // Reset changes
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.pinkAccent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? NetworkImage(_currentImageUrl!) as ImageProvider
                                : null),
                        child: (_imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 60, color: Colors.white70)
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Email oculto (solo visible para admins en back). Se mantiene en estado pero no se edita aquí.
              _buildTextField(
                controller: _cedulaController,
                label: 'Cédula',
                icon: Icons.badge_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Editable fields
              _buildTextField(
                controller: _fullNameController,
                label: 'Nombre Completo',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.account_circle_outlined,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              // Game Statistics Section
              if (_gameStats != null && !_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2F), Color(0xFF121223)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estadísticas de Juego',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Juegos', _gameStats!['totalGames'].toString(), Icons.games),
                          _buildStatItem('Puntos', _gameStats!['totalPoints'].toString(), Icons.stars),
                          _buildStatItem('Promedio', '${(_gameStats!['averageScore'] * 100).toStringAsFixed(1)}%', Icons.analytics),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Guardar Cambios', style: TextStyle(fontSize: 18)),
                  ),
                ),

              const SizedBox(height: 24),
              if (!_isEditing)
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: enabled ? Colors.pinkAccent : Colors.white38),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF2E63), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
