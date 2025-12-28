import 'package:flutter/material.dart';

/// Extra keys bar for terminal (like Termux)
class ExtraKeysBar extends StatefulWidget {
  final Function(String key) onKeyPressed;
  final Function(String char) onCtrlKeyPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  const ExtraKeysBar({
    super.key,
    required this.onKeyPressed,
    required this.onCtrlKeyPressed,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
  });

  @override
  State<ExtraKeysBar> createState() => _ExtraKeysBarState();
}

class _ExtraKeysBarState extends State<ExtraKeysBar> {
  bool _ctrlPressed = false;
  bool _altPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor.withOpacity(0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider
          Divider(color: widget.foregroundColor.withOpacity(0.3), height: 1),

          // Row 1: Modifier keys and common keys
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _buildModifierKey('ESC', false, () => widget.onKeyPressed('ESC')),
                  _buildModifierKey(
                    'CTRL',
                    _ctrlPressed,
                    () => setState(() => _ctrlPressed = !_ctrlPressed),
                  ),
                  _buildModifierKey(
                    'ALT',
                    _altPressed,
                    () => setState(() => _altPressed = !_altPressed),
                  ),
                  _buildKey('TAB'),
                  _buildKey('-'),
                  _buildKey('/'),
                  _buildKey('|'),
                  _buildKey('~'),
                  _buildKey('\\'),
                ],
              ),
            ),
          ),

          // Row 2: Arrow keys and more
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _buildArrowKey(Icons.keyboard_arrow_up, 'UP'),
                  _buildArrowKey(Icons.keyboard_arrow_down, 'DOWN'),
                  _buildArrowKey(Icons.keyboard_arrow_left, 'LEFT'),
                  _buildArrowKey(Icons.keyboard_arrow_right, 'RIGHT'),
                  _buildKey('HOME'),
                  _buildKey('END'),
                  _buildKey('PGUP'),
                  _buildKey('PGDN'),
                ],
              ),
            ),
          ),

          // Row 3: CTRL shortcuts (shown when CTRL is pressed)
          if (_ctrlPressed)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    _buildCtrlKey('A'), // Select all / Beginning of line
                    _buildCtrlKey('C'), // Interrupt / Copy
                    _buildCtrlKey('D'), // EOF / Logout
                    _buildCtrlKey('E'), // End of line
                    _buildCtrlKey('K'), // Kill to end of line
                    _buildCtrlKey('L'), // Clear screen
                    _buildCtrlKey('U'), // Kill to beginning of line
                    _buildCtrlKey('W'), // Delete word
                    _buildCtrlKey('Z'), // Suspend
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () {
            if (_ctrlPressed && label.length == 1) {
              widget.onCtrlKeyPressed(label);
              setState(() => _ctrlPressed = false);
            } else {
              widget.onKeyPressed(label);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModifierKey(String label, bool isPressed, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isPressed ? Colors.blue[700] : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(minWidth: 45),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowKey(IconData icon, String keyName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => widget.onKeyPressed(keyName),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: widget.foregroundColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCtrlKey(String char) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () {
            widget.onCtrlKeyPressed(char);
            setState(() => _ctrlPressed = false);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Center(
              child: Text(
                '^$char',
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
