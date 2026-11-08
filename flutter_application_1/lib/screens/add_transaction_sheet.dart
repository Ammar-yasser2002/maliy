import 'package:flutter/material.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  _AddTransactionSheetState createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  String _type = 'له';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('قيد جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: 'البيان', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل البيان' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: RadioListTile<String>(value: 'له', groupValue: _type, onChanged: (v) => setState(() => _type = v!), title: Text('له'))),
                    Expanded(child: RadioListTile<String>(value: 'عليه', groupValue: _type, onChanged: (v) => setState(() => _type = v!), title: Text('عليه'))),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('إلغاء'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop({'name': _name.text.trim(), 'amount': double.parse(_amount.text), 'type': _type});
                          }
                        },
                        child: Text('حفظ'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
            ),
          )
        ],
      ),
    );
  }
}
