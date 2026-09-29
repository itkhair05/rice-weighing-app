import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

import '../core/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _result = '0';

  void _onPressed(String text) {
    setState(() {
      if (text == 'C') {
        _input = '';
        _result = '0';
      } else if (text == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (text == '=') {
        _calculate();
      } else {
        _input += text;
      }
    });
  }

  void _calculate() {
    if (_input.isEmpty) return;
    try {
      String expStr = _input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('%', '/100');
      final parser = GrammarParser();
      final exp = parser.parse(expStr);
      final eval = exp.evaluate(EvaluationType.REAL, ContextModel());
      setState(() {
        if (eval is double) {
          if (eval == eval.toInt()) {
            _result = eval.toInt().toString();
          } else {
            _result = eval.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
          }
        } else {
          _result = eval.toString();
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi';
      });
    }
  }

  Widget _buildButton(String text, {Color? color, Color? textColor, int flex = 1}) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = color ?? Colors.white;
    final fgColor = textColor ?? Colors.black87;
    
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 1,
            splashFactory: NoSplash.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => _onPressed(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final operatorColor = const Color(0xFFE8F5E9);
    final operatorTextColor = const Color(0xFF2E7D32);
    final actionColor = const Color(0xFFFFEBEE);
    final actionTextColor = const Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(title: const Text('Máy tính')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(Spacing.xl),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _input,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.s),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: const Color(0xFFF5F5F5),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton('C', color: actionColor, textColor: actionTextColor),
                        _buildButton('⌫', color: actionColor, textColor: actionTextColor),
                        _buildButton('%', color: operatorColor, textColor: operatorTextColor),
                        _buildButton('÷', color: operatorColor, textColor: operatorTextColor),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton('7'),
                        _buildButton('8'),
                        _buildButton('9'),
                        _buildButton('×', color: operatorColor, textColor: operatorTextColor),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton('4'),
                        _buildButton('5'),
                        _buildButton('6'),
                        _buildButton('-', color: operatorColor, textColor: operatorTextColor),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton('1'),
                        _buildButton('2'),
                        _buildButton('3'),
                        _buildButton('+', color: operatorColor, textColor: operatorTextColor),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton('0', flex: 2),
                        _buildButton('.'),
                        _buildButton('=', color: cs.primary, textColor: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
