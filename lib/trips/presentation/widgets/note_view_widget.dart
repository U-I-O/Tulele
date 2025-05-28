import 'package:flutter/material.dart';

class NoteViewWidget extends StatefulWidget {
  final String initialNotes;
  final bool isEditable;
  final ValueChanged<String> onNotesChanged;

  const NoteViewWidget({
    super.key,
    required this.initialNotes,
    required this.isEditable,
    required this.onNotesChanged,
  });

  @override
  State<NoteViewWidget> createState() => _NoteViewWidgetState();
}

class _NoteViewWidgetState extends State<NoteViewWidget> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void didUpdateWidget(covariant NoteViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNotes != oldWidget.initialNotes && _notesController.text != widget.initialNotes) {
      _notesController.text = widget.initialNotes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _notesController,
        readOnly: !widget.isEditable,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: '记录这一天的旅行笔记、心得或备忘...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12.0), // 统一内边距
        ),
        onChanged: widget.onNotesChanged,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}