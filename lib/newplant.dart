import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rootine/plant.dart';
import 'package:rootine/style.dart';

double formSpacing = 10;

class NewPlantRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NewPlantState();
}

class _NewPlantState extends State<NewPlantRoute> {
  //String plantname;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Make a new plant"),
      ),
      body: DefaultTextStyle.merge(
        style: RootineStyle.textStyle,
        child: Center(child: NewPlantForm()),
      ),
    );
  }
}

class NewPlantForm extends StatefulWidget {
  const NewPlantForm({super.key});

  @override
  NewPlantFormState createState() {
    return NewPlantFormState();
  }
}

class NewPlantFormState extends State<NewPlantForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text('What habit do you want to stick to?'),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Enter a habit!";
              }
            },
          ),
          Row(
            children: [
              Text('Give your plant a name:'),
              SizedBox.square(dimension: formSpacing),
              Flexible(
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name your plant!';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Your plant will harvest on"),
              SizedBox.square(dimension: 20),
              HarvestDatePicker(),
            ],
          ),

          PlantPicker(),

          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("thank you!!!")));
              }
            },

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Next"),
                SizedBox.square(dimension: 4),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final List<String> prettyPlantNames = getPrettyPlantNames();
final String defaultText = "Select a plant...";
List<String> getPrettyPlantNames() {
  List<String> toReturn = <String>[];
  toReturn.add(defaultText);
  for (var value in PlantKind.values) {
    toReturn.add(value.prettyName);
  }
  return toReturn;
}

class PlantPicker extends StatefulWidget {
  const PlantPicker({super.key});

  @override
  PlantPickerState createState() {
    return PlantPickerState();
  }
}

typedef MenuEntry = DropdownMenuEntry<String>;
class PlantPickerState extends State<PlantPicker> {
  String selected = defaultText;

  static List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    getPrettyPlantNames().map<MenuEntry>((String name) => MenuEntry(value: name, label: name)),
  );

  @override
  Widget build(BuildContext context) {
    // TODO: once pictures are added, refactor this
    // to display them here
    return DropdownMenu<String>(
      initialSelection: defaultText,
      dropdownMenuEntries: menuEntries,
      onSelected: (String? value) {
        setState(() {
          if (defaultText != value && menuEntries.any((item) => item.value == defaultText)) {
            menuEntries.removeAt(0);
          }
          selected = value!;
        });
      },
    );
  }
}

class HarvestDatePicker extends StatefulWidget {
  const HarvestDatePicker({super.key});

  @override
  HarvestDatePickerState createState() {
    return HarvestDatePickerState();
  }
}

class HarvestDatePickerState extends State {
  DateTime selected = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 100 * 365)),
    );

    setState(() {
      if (pickedDate == null) {
        selected = DateTime.now();
      } else {
        selected = pickedDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MM-dd-yy').format(selected);
    return ElevatedButton(onPressed: _selectDate, child: Text(formattedDate));
  }
}
