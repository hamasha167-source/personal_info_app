import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
// ignore: unused_import
import 'dart:typed_data';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PersonalInfoProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'زانیاری کەسی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PersonalListScreen(),
    );
  }
}

class Person {
  String id;
  String name;
  String age;
  String email;
  String address;
  String phone;
  String job;

  String company;
  String startDate;

  String? imagePath;

  Person({
    required this.id,
    required this.name,
    required this.age,
    required this.email,
    required this.address,
    required this.phone,
    required this.job,
    required this.company,
    required this.startDate,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'email': email,
      'address': address,
      'phone': phone,
      'job': job,
      'company': company,
      'startDate': startDate,
      'imagePath': imagePath,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      job: json['job'] ?? '',
      company: json['company'] ?? '',
      startDate: json['startDate'] ?? '',
      imagePath: json['imagePath'],
    );
  }
}

class PersonalInfoProvider extends ChangeNotifier {
  List<Person> _persons = [];

  List<Person> get persons => _persons;

  Future<void> loadPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final personsJson = prefs.getStringList('persons') ?? [];
    _persons = personsJson.map((json) {
      final Map<String, dynamic> data = jsonDecode(json);
      return Person.fromJson(data);
    }).toList();
    notifyListeners();
  }

  Future<void> savePersons() async {
    final prefs = await SharedPreferences.getInstance();
    final personsJson = _persons.map((person) {
      return jsonEncode(person.toJson());
    }).toList();
    await prefs.setStringList('persons', personsJson);
    notifyListeners();
  }

  void addPerson(Person person) {
    _persons.add(person);
    savePersons();
  }

  void updatePerson(String id, Person updatedPerson) {
    final index = _persons.indexWhere((person) => person.id == id);
    if (index != -1) {
      _persons[index] = updatedPerson;
      savePersons();
    }
  }

  void deletePerson(String id) {
    _persons.removeWhere((person) => person.id == id);
    savePersons();
  }

  void clearAll() {
    _persons.clear();
    savePersons();
  }
}

class PersonalListScreen extends StatefulWidget {
  const PersonalListScreen({super.key});

  @override
  State<PersonalListScreen> createState() => _PersonalListScreenState();
}

class _PersonalListScreenState extends State<PersonalListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PersonalInfoProvider>(context, listen: false);
    await provider.loadPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'لیستی کارمەندەکان',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddPersonScreen()),
              );
            },
            tooltip: 'کارمەندێکی نوێ',
          ),
        ],
      ),
      body: Consumer<PersonalInfoProvider>(
        builder: (context, provider, child) {
          if (provider.persons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text(
                    'هیچ کارمەندێک تۆمارنەکراوە',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'کلیک بکە سەر + بۆ زیادکردنی کارمەندێکی نوێ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.persons.length,
            itemBuilder: (context, index) {
              final person = provider.persons[index];
              return _buildPersonCard(context, person, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPersonScreen()),
          );
        },
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPersonCard(
      BuildContext context, Person person, PersonalInfoProvider provider) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildPersonAvatar(person),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('تەمەن: ${person.age} ساڵ'),
            Text('کار: ${person.job}'),
            Text('شەرکە: ${person.company}'),
            Text('ئیمەیڵ: ${person.email}'),
            Text('مۆبایل: ${person.phone}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPersonScreen(person: person),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(context, person, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('دەستکاری')),
            const PopupMenuItem(value: 'delete', child: Text('سڕینەوە')),
          ],
        ),
        onTap: () {
          _showPersonDetails(context, person);
        },
      ),
    );
  }

  Widget _buildPersonAvatar(Person person) {
    if (person.imagePath != null && person.imagePath!.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: FileImage(File(person.imagePath!)),
      );
    } else {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blue.shade100,
        child: Text(
          person.name.isNotEmpty ? person.name[0] : '?',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      );
    }
  }

  void _showDeleteDialog(
      BuildContext context, Person person, PersonalInfoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سڕینەوەی کارمەند'),
        content: Text('دڵنیای لە سڕینەوەی ${person.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نەخێر'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePerson(person.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${person.name} سڕدرایەوە'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('بەڵێ'),
          ),
        ],
      ),
    );
  }

  void _showPersonDetails(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زانیاری تەواو'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: _buildPersonAvatar(person),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('👤 ناو:', person.name),
              _buildDetailRow('🎂 تەمەن:', '${person.age} ساڵ'),
              _buildDetailRow('📧 ئیمەیڵ:', person.email),
              _buildDetailRow('📞 مۆبایل:', person.phone),
              _buildDetailRow('📍 ناونیشان:', person.address),
              _buildDetailRow('💼 کار:', person.job),
              _buildDetailRow('🏢 شەرکە:', person.company),
              _buildDetailRow('📅 رۆژی دەستپێکردن:', person.startDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشە'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AddPersonScreen extends StatefulWidget {
  final Person? person;

  const AddPersonScreen({this.person, super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, String> _info = {
    'name': '',
    'age': '',
    'email': '',
    'address': '',
    'phone': '',
    'job': '',
    'company': '',
    'startDate': '',
  };
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.person != null) {
      _info['name'] = widget.person!.name;
      _info['age'] = widget.person!.age;
      _info['email'] = widget.person!.email;
      _info['address'] = widget.person!.address;
      _info['phone'] = widget.person!.phone;
      _info['job'] = widget.person!.job;
      _info['company'] = widget.person!.company;
      _info['startDate'] = widget.person!.startDate;

      _imagePath = widget.person!.imagePath;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _info['startDate'] = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هەڵە لە هەڵبژاردنی وێنە: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _savePerson() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider =
          Provider.of<PersonalInfoProvider>(context, listen: false);
      final person = Person(
        id: widget.person?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _info['name']!,
        age: _info['age']!,
        email: _info['email']!,
        address: _info['address']!,
        phone: _info['phone']!,
        job: _info['job']!,
        company: _info['company']!,
        startDate: _info['startDate']!,
        imagePath: _imagePath,
      );

      if (widget.person != null) {
        provider.updatePerson(widget.person!.id, person);
      } else {
        provider.addPerson(person);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.person != null
              ? 'زانیاریەکان نوێکرانەوە!'
              : 'کارمەندێکی نوێ زیادکرا!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        const Text(
          'وێنەی کارمەند',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.blue.shade400, width: 2),
              color: Colors.grey.shade100,
            ),
            child: _imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      File(_imagePath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickImage,
          child: const Text('وێنەیەک هەڵبژێرە'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.person != null
            ? 'دەستکاری کردنی کارمەند'
            : 'کارمەندێکی نوێ'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // وێنە
                _buildImageSection(),
                const SizedBox(height: 20),

                // زانیاریەکان
                _buildTextField(
                  label: 'ناوی تەواو',
                  hint: '  ',
                  icon: Icons.person,
                  field: 'name',
                  initialValue: _info['name'],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'تەمەن',
                  hint: '',
                  icon: Icons.cake,
                  field: 'age',
                  initialValue: _info['age'],
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'کار',
                  hint: '',
                  icon: Icons.work,
                  field: 'job',
                  initialValue: _info['job'],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'ناوی شەرکە',
                  hint: '',
                  icon: Icons.business,
                  field: 'company',
                  initialValue: _info['company'],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'ئیمەیڵ',
                  hint: 'example@gmail.com',
                  icon: Icons.email,
                  field: 'email',
                  initialValue: _info['email'],
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'ناونیشان',
                  hint: ' ',
                  icon: Icons.location_on,
                  field: 'address',
                  initialValue: _info['address'],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'ژمارەی مۆبایل',
                  hint: '  ',
                  icon: Icons.phone,
                  field: 'phone',
                  initialValue: _info['phone'],
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildDateField(),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _savePerson,
                  icon: Icon(widget.person != null ? Icons.edit : Icons.save),
                  label: Text(
                      widget.person != null ? 'نوێکردنەوە' : 'پاشەکەوتکردن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required String field,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      onSaved: (value) => _info[field] = value ?? '',
      validator: (value) => value!.isEmpty ? 'تکایە ئەم خانەە پڕبکەرەوە' : null,
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('رۆژی دەستپێکردن',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(_info['startDate']!.isEmpty
                    ? 'کلیک بکە بۆ هەڵبژاردن'
                    : _info['startDate']!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
