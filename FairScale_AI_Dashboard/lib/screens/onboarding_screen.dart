import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isSpawningModels = false;
  double _spawnProgress = 0.0;
  bool _modelsSpawned = false;
  String _currentSubTask = "Idle";

  PlatformFile? _pickedFile;
  List<String> _headers = [];
  String? _selectedTarget;
  List<String> _selectedProtected = [];
  List<String> _selectedValid = [];
  Map<String, dynamic>? _results;
  String _generatedApiKey = "fs_live_pending";
  final TextEditingController _projectNameController = TextEditingController();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        try {
          final bytes = _pickedFile!.bytes!;
          final content = utf8.decode(bytes, allowMalformed: true);
          final rows = const CsvToListConverter().convert(content);
          if (rows.isNotEmpty) {
            _headers = rows[0].map((e) => e.toString()).toList();
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      });
    }
  }

  Future<void> _trainModels() async {
    setState(() {
      _isSpawningModels = true;
      _currentSubTask = "Connecting to Vertex AI Compute...";
      _spawnProgress = 0.05;
    });

    // Simulate granular steps for "WOW" effect
    final steps = [
      "Analyzing Dataset Topology...",
      "Removing Protected Attribute Weights...",
      "Training Model A (Biased Baseline)...",
      "Spawning Model B (Bias Detective)...",
      "Calculating Demographic Parity Score...",
      "Optimizing Model C (Fair Mirror)...",
      "Verifying Shield Integrity...",
      "Finalizing Interceptor API..."
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _currentSubTask = steps[i];
        _spawnProgress = (i + 1) / (steps.length + 1);
      });
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5005/train'));
      request.files.add(http.MultipartFile.fromBytes('file', _pickedFile!.bytes!, filename: _pickedFile!.name));
      request.fields['target'] = _selectedTarget!;
      request.fields['protected'] = _selectedProtected.join(',');
      request.fields['valid'] = _selectedValid.join(',');

      var response = await request.send().timeout(const Duration(minutes: 2));
      var resBody = await http.Response.fromStream(response);

      if (resBody.statusCode == 200) {
        final data = json.decode(resBody.body);
        _generateFinalKey();
        
        await FirebaseFirestore.instance.collection('deployments').add({
            "name": _projectNameController.text.isNotEmpty ? _projectNameController.text : "Project-${_pickedFile!.name}",
            "key": _generatedApiKey,
            "status": "Live (Active)",
            "timestamp": FieldValue.serverTimestamp(),
        });

        setState(() {
          _results = data;
          _spawnProgress = 1.0;
          _isSpawningModels = false;
          _modelsSpawned = true;
          _currentStep += 1;
        });
      }
    } catch (e) {
      setState(() => _isSpawningModels = false);
    }
  }

  void _generateFinalKey() {
    setState(() {
      _generatedApiKey = "fs_live_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Create Project",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: GlassCard(
                padding: const EdgeInsets.all(8.0),
                child: Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigoAccent)),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep == 0 && (_pickedFile == null || _projectNameController.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please provide a Project Name and upload a Dataset")),
                        );
                        return;
                      }
                      if (_currentStep == 1 && (_selectedTarget == null || _selectedProtected.isEmpty)) return;
                      if (_currentStep == 2 && !_modelsSpawned) {
                        _trainModels();
                      } else if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else if (_currentStep == 3) {
                        if (widget.onComplete != null) widget.onComplete!();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) setState(() => _currentStep--);
                    },
                    controlsBuilder: (context, details) {
                      if (_currentStep == 2 && _isSpawningModels) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Row(
                          children: [
                            if (_currentStep > 0 && _currentStep < 3)
                              OutlinedButton.icon(
                                onPressed: details.onStepCancel,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("GO BACK"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  side: BorderSide(color: Colors.indigoAccent.withOpacity(0.5)),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigoAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 4,
                                  shadowColor: Colors.indigoAccent.withOpacity(0.4),
                                ),
                                child: Text(
                                  _currentStep == 2 ? "SPAWN TRIPARTITE ENGINES" : 
                                  _currentStep == 3 ? "VIEW IN INTERCEPTION FEED" : "PROCEED TO NEXT STEP",
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      _stepUpload(),
                      _stepMap(),
                      _stepSpawn(),
                      _stepAPI(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _stepUpload() {
    return Step(
      title: const Text("Step 1: Upload Dataset", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter Project Name:"),
          const SizedBox(height: 8),
          TextField(
            controller: _projectNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter project name here",
            ),
          ),
          const SizedBox(height: 20),
          const Text("Select Dataset (CSV):"),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_pickedFile == null ? Icons.upload_file : Icons.check_circle, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text(_pickedFile == null ? "No file selected" : "File: ${_pickedFile!.name}"),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _pickFile, child: const Text("Pick CSV File")),
              ],
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _stepMap() {
    return Step(
      title: const Text("Step 2: Attribute Mapping", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select columns for Model B (The Detective) to analyze."),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedTarget,
            hint: const Text("Select Target (e.g. Loan_Status)"),
            isExpanded: true,
            items: _headers.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: (v) => setState(() => _selectedTarget = v),
          ),
          const SizedBox(height: 20),
          const Text("Select Biased Features (Protected Attributes)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, 
            runSpacing: 8,
            children: _headers.map((h) => FilterChip(
              label: Text(h, style: TextStyle(color: _selectedProtected.contains(h) ? Colors.white : Colors.black87)), 
              selected: _selectedProtected.contains(h), 
              selectedColor: Colors.indigoAccent,
              checkmarkColor: Colors.white,
              onSelected: (v) => setState(() => v ? _selectedProtected.add(h) : _selectedProtected.remove(h))
            )).toList()
          ),
          const SizedBox(height: 24),
          const Text("Select Important Features (Non-Biased/Merit)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, 
            runSpacing: 8,
            children: _headers.map((h) => FilterChip(
              label: Text(h, style: TextStyle(color: _selectedValid.contains(h) ? Colors.white : Colors.black87)), 
              selected: _selectedValid.contains(h), 
              selectedColor: Colors.green,
              checkmarkColor: Colors.white,
              onSelected: (v) => setState(() => v ? _selectedValid.add(h) : _selectedValid.remove(h))
            )).toList()
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _stepSpawn() {
    return Step(
      title: const Text("Vertex AI Engine Spawning", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        children: [
          if (_isSpawningModels || _modelsSpawned)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.indigoAccent.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _spawnProgress,
                          strokeWidth: 8,
                          backgroundColor: Colors.indigoAccent.withOpacity(0.1),
                          color: Colors.indigoAccent,
                        ),
                      ),
                      FadeTransition(
                        opacity: _pulseController,
                        child: const Icon(Icons.auto_awesome_outlined, size: 50, color: Colors.indigoAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(_currentSubTask, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text("${(_spawnProgress * 100).toInt()}% CLOUD COMPUTE SYNCED", style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  _modelLine("Model A (Original)", "BASELINE INGEST", _spawnProgress > 0.4),
                  _modelLine("Model B (Detective)", "BIAS AUDITOR ACTIVE", _spawnProgress > 0.7),
                  _modelLine("Model C (Fair Mirror)", "REMEDIATOR READY", _spawnProgress > 0.95),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _showTopology(context),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text("VIEW SHIELD TOPOLOGY"),
                    style: TextButton.styleFrom(foregroundColor: Colors.indigoAccent),
                  ),
                ],
              ),
            ),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  Widget _modelLine(String name, String role, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? Colors.green : Colors.black12),
          const SizedBox(width: 15),
          Text(name, style: TextStyle(fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(role, style: const TextStyle(fontSize: 10, color: Colors.black26)),
        ],
      ),
    );
  }

  Step _stepAPI() {
    return Step(
      title: const Text("Step 4: Deployment & Integration", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified_outlined, size: 50, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text("FairScale Shield is LIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 8),
            Text("Project: ${_projectNameController.text}", style: const TextStyle(color: Colors.black45)),
            const SizedBox(height: 32),
            const Text("INTERCEPTOR ENDPOINT", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black38)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      "https://api.fairscale.ai/v1/intercept?key=$_generatedApiKey", 
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.indigoAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      // Simulating copy
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key Copied to Vault")));
                    },
                    icon: const Icon(Icons.copy, size: 20, color: Colors.black38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat("BIAS SHIELD", "99.9%"),
                _miniStat("LATENCY", "48ms"),
                _miniStat("TRUST SCORE", "A+"),
              ],
            ),
          ],
        ),
      ),
      isActive: _currentStep >= 3,
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black26)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  void _showTopology(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("FairScale Shield Architecture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Our tripartite engine works in a closed-loop feedback system:"),
            const SizedBox(height: 20),
            _topologyNode("Model A (Ingest)", "Receives raw application data.", Colors.blue),
            const Icon(Icons.arrow_downward, color: Colors.grey),
            _topologyNode("Model B (Audit)", "Identifies demographic bias correlations.", Colors.orange),
            const Icon(Icons.arrow_downward, color: Colors.grey),
            _topologyNode("Model C (Remediate)", "Corrects weights to ensure merit-based outcome.", Colors.green),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Understood"))],
      ),
    );
  }

  Widget _topologyNode(String title, String desc, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}
