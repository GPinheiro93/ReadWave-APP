// main.dart

import 'dart:math';
import 'dart:ui';
import 'dart:io'; // Para manejar archivos del sistema
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
// NUEVO: Importamos el nuevo paquete para leer EPUBs.
import 'package:epubx/epubx.dart';


// El molde del libro
class Book {
  final String title;
  final String author;
  final String synopsis;
  final String audioPath;
  final Color coverColor;

  Book({
    required this.title,
    required this.author,
    required this.synopsis,
    required this.audioPath,
    required this.coverColor,
  });
}


void main() {
  runApp(const AudioBookApp());
}

class AudioBookApp extends StatelessWidget {
  const AudioBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reproductor de Audiolibro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      home: const LibraryScreen(),
    );
  }
}

// ---- PANTALLA DE LA BIBLIOTECA ----
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // La lista de libros ahora es una variable de estado para poder modificarla.
  final List<Book> _library = [
    Book(
      title: 'Bienvenido',
      author: 'Tu Biblioteca Personal',
      synopsis: 'Añade tu primer libro en formato EPUB usando el botón "+".',
      audioPath: 'audio/test_sound.mp3',
      coverColor: Colors.pink.shade300,
    ),
  ];
  final Random _random = Random();


  Future<void> _pickAndAddBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      
      try {
        final fileBytes = await File(filePath).readAsBytes();
        // Usamos el lector del nuevo paquete epubx
        EpubBook epubBook = await EpubReader.readBook(fileBytes);

        // CORRECCIÓN FINAL: Usamos la forma correcta de acceder a los metadatos.
        String title = epubBook.Title ?? 'Título Desconocido';
        String author = epubBook.Author ?? 'Autor Desconocido';
        
        // El nuevo paquete no lee la sinopsis directamente, la dejamos como pendiente.
        String synopsis = 'La sinopsis aparecerá aquí...';
        
        final newBook = Book(
          title: title,
          author: author,
          synopsis: synopsis,
          audioPath: 'audio/test_sound.mp3', // Temporalmente usa el audio de prueba
          coverColor: Colors.primaries[_random.nextInt(Colors.primaries.length)].shade300,
        );

        setState(() {
          _library.add(newBook);
        });

      } catch (e) {
        debugPrint('Error al leer el archivo EPUB: $e');
      }
      
    } else {
      debugPrint("No se seleccionó ningún archivo.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Biblioteca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndAddBook,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _library.length,
        itemBuilder: (context, index) {
          final book = _library[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(book: book),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: book.coverColor.withAlpha(77),
                            blurRadius: 20,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withAlpha(153),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.white.withAlpha(26)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [book.coverColor.withAlpha(179), book.coverColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: FaIcon(FontAwesomeIcons.book, color: Colors.white70, size: 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    book.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    book.author,
                                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    book.synopsis,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



// ---- PANTALLA DEL REPRODUCTOR (Sin cambios) ----
class PlayerScreen extends StatefulWidget {
  final Book book;
  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    audioPlayer.onPlayerStateChanged.listen((state) { if (mounted) setState(() => isPlaying = state == PlayerState.playing); });
    audioPlayer.onDurationChanged.listen((newDuration) { if (mounted) setState(() => duration = newDuration); });
    audioPlayer.onPositionChanged.listen((newPosition) { if (mounted) setState(() => position = newPosition); });

    try {
      await audioPlayer.setSource(AssetSource(widget.book.audioPath));
    } catch (e) {
      debugPrint("Error al cargar el audio: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final secs = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(child: Center(child: _buildBookCover())),
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    _buildProgressBar(),
                    const SizedBox(height: 10),
                    _buildMainControls(),
                    const SizedBox(height: 20),
                    _buildBottomBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.expand_more, color: Colors.white, size: 30),
        ),
        Text(
          widget.book.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildBookCover() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 350,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.book.coverColor.withAlpha(179), widget.book.coverColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.book.coverColor.withAlpha(128),
            blurRadius: 30,
            offset: const Offset(0,10),
          )
        ]
      ),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.bookOpen, size: 120, color: Colors.white70),
      )
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.book.author,
                style: TextStyle(color: Colors.grey, fontSize: 16)
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade800,
            thumbColor: Colors.white,
          ),
          child: Slider(
            min: 0,
            max: duration.inSeconds.toDouble(),
            value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
            onChanged: (value) async {
              final newPosition = Duration(seconds: value.toInt());
              await audioPlayer.seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position), style: const TextStyle(color: Colors.grey)),
              Text(formatDuration(duration), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(onPressed: () {}, icon: const FaIcon(FontAwesomeIcons.shuffle, color: Colors.grey, size: 22)),
        IconButton(onPressed: () {}, icon: const FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white, size: 30)),
        GestureDetector(
          onTap: () async {
            if (isPlaying) {
              await audioPlayer.pause();
            } else {
              if (position >= duration && duration.inSeconds > 0) {
                await audioPlayer.seek(Duration.zero);
              }
              await audioPlayer.resume();
            }
          },
          child: Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: FaIcon(
                isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
        ),
        IconButton(onPressed: () {}, icon: const FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 30)),
        IconButton(onPressed: () {}, icon: const FaIcon(FontAwesomeIcons.repeat, color: Colors.grey, size: 22)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.speaker_group_outlined, color: Colors.grey)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.playlist_play, color: Colors.grey, size: 30)),
      ],
    );
  }
}
