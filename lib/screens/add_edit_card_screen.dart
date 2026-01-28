import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (text.length > 5) {
      return oldValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (text[i].contains(RegExp(r'\d'))) {
        buffer.write(text[i]);
        if (buffer.length == 2 && i != 5) {
          buffer.write('/');
        }
      }
    }

    var string = buffer.toString();
    if (string.length > 5) {
      string = string.substring(0, 5);
    }
    
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class AddEditCardScreen extends StatefulWidget {
  final CreditCard? card;

  const AddEditCardScreen({super.key, this.card});

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _cvvController;
  late TextEditingController _holderNameController;
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.card?.bankName ?? '');
    _cardNumberController = TextEditingController(text: widget.card?.cardNumber ?? '');
    _expiryDateController = TextEditingController(text: widget.card?.expiryDate ?? '');
    _cvvController = TextEditingController(text: widget.card?.cvv ?? '');
    _holderNameController = TextEditingController(text: widget.card?.cardHolderName ?? '');
    _selectedColorIndex = widget.card?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final card = CreditCard(
        id: widget.card?.id ?? const Uuid().v4(),
        bankName: _bankNameController.text,
        cardNumber: _cardNumberController.text,
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        cardHolderName: _holderNameController.text,
        colorIndex: _selectedColorIndex,
      );

      final provider = Provider.of<CardProvider>(context, listen: false);
      if (widget.card != null) {
        provider.updateCard(card);
      } else {
        provider.addCard(card);
      }

      Navigator.of(context).pop();
    }
  }

  void _deleteCard() {
    if (widget.card != null) {
      Provider.of<CardProvider>(context, listen: false).deleteCard(widget.card!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card != null ? 'Edit Card' : 'Add Card'),
        actions: [
          if (widget.card != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCard,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 13 || value.length > 19) return 'Invalid Number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ExpiryDateFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Required';
                         }
                         if (value.length != 5) {
                           return 'Invalid';
                         }
                         return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      obscureText: true,
                      validator: (value) => (value != null && value.length == 3) ? null : '3 digits',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holderNameController,
                decoration: const InputDecoration(labelText: 'Card Holder Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text('Card Color'),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final gradients = [
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.red,
                      Colors.grey,
                    ];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: gradients[index],
                          shape: BoxShape.circle,
                          border: _selectedColorIndex == index
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: _selectedColorIndex == index
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCard,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(widget.card != null ? 'Update Card' : 'Add Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
