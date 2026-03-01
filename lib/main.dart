import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:url_launcher/url_launcher.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verificador Billetes BO',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              const Text(
                'Elige la denominación\no corte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // Fila superior: 10 y 20
              Row(
                children: [
                  _buildCard(
                    context,
                    '10',
                    'Diez Bolivianos',
                    Colors.lightBlue[100]!,
                    Colors.blue[900]!,
                  ),
                  const SizedBox(width: 16),
                  _buildCard(
                    context,
                    '20',
                    'Veinte Bolivianos',
                    Colors.orange[100]!,
                    Colors.orange[900]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Card 50
                  _buildCard(
                    context,
                    '50',
                    'Cincuenta Bolivianos',
                    Colors.purple[100]!,
                    Colors.purple[900]!,
                    fullWidth: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String denom,
    String text,
    Color bgColor,
    Color textColor, {
    bool fullWidth = false,
  }) {
    return Expanded(
      flex: fullWidth ? 2 : 1,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScannerPage(denomination: denom)),
        ),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                denom,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://github.com/alvinoDev')),
      child: const Text(
        'Desarrollado por @alvinoDev • 2026',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  final String denomination;
  const ScannerPage({super.key, required this.denomination});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  bool _isProcessing = false;
  String _status =
      'Apunta la cámara al número de serie\n(dígitos numéricos + letra B)';
  String _serial = '0000000000';
  bool? _isInvalid;
  String _editedSerial = '';

  // RANGOS OFICIALES extraídos de las imágenes que compartio BCB
  final Map<String, List<List<int>>> _invalidRanges = {
    '10': [
      [67250001, 67700000],
      [69050001, 69500000],
      [69500001, 69950000],
      [69950001, 70400000],
      [70400001, 70850000],
      [70850001, 71300000],
      [76310012, 85139995],
      [86400001, 86850000],
      [90900001, 91350000],
      [91800001, 92250000],
    ],
    '20': [
      [87280145, 91646549],
      [96650001, 97100000],
      [99800001, 100250000],
      [100250001, 100700000],
      [109250001, 109700000],
      [110600001, 111050000],
      [111050001, 111500000],
      [111950001, 112400000],
      [112400001, 112850000],
      [112850001, 113300000],
      [114200001, 114650000],
      [1146500001, 115100000],
      [115100001, 115550000],
      [118700001, 119150000],
      [119150001, 119600000],
      [120500001, 120950000],
    ],
    '50': [
      [77100001, 77550000],
      [78000001, 78450000],
      [78900001, 96350000],
      [96350001, 96800000],
      [96800001, 97250000],
      [98150001, 98600000],
      [104900001, 105350000],
      [105350001, 105800000],
      [106700001, 107150000],
      [107600001, 108050000],
      [108050001, 108500000],
      [109400001, 109850000],
    ],
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _status = 'Permiso de cámara denegado');
      return;
    }

    try {
      // Seleccionamos la cámara trasera principal
      final backCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final CameraDescription camera = backCameras.isNotEmpty
          ? backCameras[0]
          : cameras[0];

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(
        () => _status =
            'Error al abrir cámara:\n$e\nIntenta cerrar y abrir la app',
      );
    }
  }

  Future<void> _scan() async {
    if (_controller == null ||
        _isProcessing ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final XFile photo = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      String fullText = recognizedText.text.replaceAll(RegExp(r'[^0-9B]'), '');
      final RegExp regex = RegExp(r'(\d{7,10})');
      final match = regex.firstMatch(fullText);

      if (match == null) {
        setState(() {
          _status = 'No se detectó número de serie.\nMejor luz o más cerca.';
          _serial = '0000000000';
          _isInvalid = null;
        });
        return;
      }

      String serialStr = match.group(1)!;
      int serialNum = int.parse(serialStr);

      final ranges = _invalidRanges[widget.denomination] ?? [];
      bool invalid = ranges.any((r) => serialNum >= r[0] && serialNum <= r[1]);

      setState(() {
        _serial = serialStr;
        _isInvalid = invalid;
        _status = invalid
            ? '¡BILLETE INHABILITADO!\nNo lo aceptes ni uses'
            : 'BILLETE VÁLIDO \nPuedes usarlo con tranquilidad';
      });
    } catch (e) {
      setState(() => _status = 'Error al leer. Intenta de nuevo.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInvalid = _isInvalid ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Escaneando Bs ${widget.denomination} (Serie B)'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Cuadro punteado con cámara
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: DottedBorder(
              color: Colors.blue,
              strokeWidth: 3,
              dashPattern: const [8, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _controller != null && _controller!.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CameraPreview(_controller!),
                      )
                    : const Center(
                        child: Text(
                          'Cargando cámara...\nAsegúrate de dar permiso',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Número grande
          Text(
            _serial,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _isInvalid == null
                  ? Colors.grey
                  : (isInvalid ? Colors.red : Colors.green),
            ),
          ),

          const SizedBox(height: 8),

          if (_serial != '0000000000' && _serial != 'No detectado')
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Corregir número manualmente'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[800]),
              onPressed: _showEditDialog,
            ),

          const SizedBox(height: 10),

          // Instrucción
          Text(
            'Enfoca los dígitos numéricos + la letra B\n'
            'La lectura automática puede fallar con mala luz o billetes gastados.\n'
            '¡Siempre confirma los números a mano!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // Estado del billete
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isInvalid ? Colors.red : Colors.green,
            ),
          ),

          const Spacer(),

          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_isProcessing ? 'Procesando...' : 'ESCANEAR'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isProcessing ? null : _scan,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://github.com/alvinoDev')),
      child: const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Text(
          'Desarrollado por @alvinoDev • 2026',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    _editedSerial = _serial; // prellenar con lo detectado

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corregir número de serie'),
        content: TextField(
          controller: TextEditingController(text: _editedSerial),
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 10, // máximo típico de serie
          decoration: const InputDecoration(
            hintText: 'Ej: 1234567890 o B000000000',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (value) => _editedSerial = value.trim().toUpperCase(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_editedSerial.isNotEmpty &&
                  RegExp(r'^[0-9B]{7,10}$').hasMatch(_editedSerial)) {
                setState(() {
                  _serial = _editedSerial;
                  // Volver a validar con el número corregido
                  final serialNum =
                      int.tryParse(_serial.replaceAll('B', '0')) ??
                      0; // tratamos B como 0 para rango
                  final ranges = _invalidRanges[widget.denomination] ?? [];
                  _isInvalid = ranges.any(
                    (r) => serialNum >= r[0] && serialNum <= r[1],
                  );

                  _status = _isInvalid!
                      ? '¡BILLETE INHABILITADO!\n(No lo aceptes ni uses)'
                      : 'BILLETE VÁLIDO \nPuedes usarlo con tranquilidad';
                });
                Navigator.pop(context);
              } else {
                // Opcional: mostrar error si no es válido
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ingresa solo números (7-10 dígitos). La B se acepta al inicio.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Verificar',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
