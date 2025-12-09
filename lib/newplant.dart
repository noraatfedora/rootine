import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rootine/main.dart';
import 'package:rootine/plant.dart';
import 'package:rootine/safedatetime.dart';
import 'package:rootine/style.dart';
import "package:change_case/change_case.dart";
import 'package:provider/provider.dart';

double formSpacing = 10;

Plant currentPlant = Plant();
DateTime selectedDate = SafeDateTime.now();
String selectedPlantKind = getPrettyPlantNames().first;
int _numberPickerTimes = 1;
DurationType _selectedDuration = DurationType.day;

class NewPlantRoute extends StatefulWidget {
  const NewPlantRoute({super.key});

  @override
  State<StatefulWidget> createState() => _NewPlantState();
}

class _NewPlantState extends State<NewPlantRoute> {
  //String plantname;

  @override
  Widget build(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
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

  final nameController = TextEditingController();
  final descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            Text('What habit do you want to stick to?'),
            TextFormField(
              controller: descController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Enter a habit!";
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  Text('Give your plant a name:'),
                  SizedBox.square(dimension: formSpacing),
                  Flexible(
                    child: TextFormField(
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name your plant!';
                        }
                        if (value.length > 20) {
                          return 'Plant name must be < 20 characters!';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Your plant will harvest on"),
                  SizedBox.square(dimension: 20),
                  HarvestDatePicker(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PlantPicker(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    currentPlant.name = nameController.text.toCapitalCase();
                    currentPlant.desc = descController.text;
                    currentPlant.expiration = selectedDate;
                    currentPlant.kind = PlantKind.plantFromPrettyName(
                      selectedPlantKind,
                    );
                    print(currentPlant.name);
                    print(currentPlant.desc);
                    print(currentPlant.expiration);
                    print(currentPlant.kind);

                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => TimeSelectionRoute(),
                      ),
                    );
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
            ),
          ],
        ),
      ),
    );
  }
}

final List<String> prettyPlantNames = getPrettyPlantNames();
List<String> getPrettyPlantNames() {
  List<String> toReturn = <String>[];
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
  static List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    getPrettyPlantNames().map<MenuEntry>(
      (String name) => MenuEntry(value: name, label: name),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // TODO: once pictures are added, refactor this
    // to display them here
    return DropdownMenu<String>(
      initialSelection: selectedPlantKind,
      label: const Text("Select a plant..."),
      dropdownMenuEntries: menuEntries,
      onSelected: (String? value) {
        setState(() {
          selectedPlantKind = value!;
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
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: SafeDateTime.now(),
      lastDate: SafeDateTime.now().add(Duration(days: 100 * 365)),
    );

    setState(() {
      if (pickedDate == null) {
        selectedDate = SafeDateTime.now();
      } else {
        selectedDate = pickedDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MM-dd-yy').format(selectedDate);
    return ElevatedButton(onPressed: _selectDate, child: Text(formattedDate));
  }
}

final Map<Weekday, bool> _selectedDays = {
  Weekday.sunday: false,
  Weekday.monday: false,
  Weekday.tuesday: false,
  Weekday.wednesday: false,
  Weekday.thursday: false,
  Weekday.friday: false,
  Weekday.saturday: false,
};

class TimeSelectionRoute extends StatefulWidget {
  const TimeSelectionRoute({super.key});

  @override
  State<StatefulWidget> createState() => _TimeSelectionState();
}

class _TimeSelectionState extends State<TimeSelectionRoute> {
  TimingOption _timingOption = TimingOption.daysOfTheWeek;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(currentPlant.name ?? "plant name not found"),
      ),
      body: DefaultTextStyle.merge(
        style: RootineStyle.textStyle,
        child: Center(
          child: Column(
            children: [
              Text(
                'How often does ${currentPlant.name ?? "your plant"} need water?',
              ),
              RadioGroup<TimingOption>(
                groupValue: _timingOption,
                onChanged: (TimingOption? value) {
                  setState(() {
                    if (value != null) {
                      _timingOption = value;
                    }
                  });
                },
                child: Column(
                  children: [
                    ListTile(
                      title: TimingOptionWidget(
                        greyed: !(_timingOption == TimingOption.daysOfTheWeek),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: WeekdayToggleButtons(
                                callback: () {
                                  setTimingOption(
                                    TimingOption.daysOfTheWeek,
                                  );
                                },
                              ),
                            ),
                            Text("Every week"),
                          ],
                        ),
                      ),
                      leading: Radio<TimingOption>(
                        value: TimingOption.daysOfTheWeek,
                      ),
                    ),
                    ListTile(
                      title: TimingOptionWidget(
                        greyed:
                            !(_timingOption ==
                                TimingOption.numTimesPerDuration),
                        child: TimesPerDurationSelector(
                          callback: () {
                            this.setTimingOption(
                              TimingOption.numTimesPerDuration,
                            );
                          },
                        ),
                      ),
                      leading: Radio<TimingOption>(
                        value: TimingOption.numTimesPerDuration,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        switch (_timingOption) {
                          case TimingOption.daysOfTheWeek:
                            currentPlant.weekdaySelection = _selectedDays;
                            currentPlant.timingOption =
                                TimingOption.daysOfTheWeek;
                            break;
                          case TimingOption.numTimesPerDuration:
                            currentPlant.numTimes = _numberPickerTimes;
                            currentPlant.duration = _selectedDuration;
                            currentPlant.timingOption = TimingOption.numTimesPerDuration;
                            break;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => SetPrizeRoute(),
                          ),
                        );
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void setTimingOption(TimingOption selectedOption) {
    setState(() {
      print("askldfjsdlkjf");
      _timingOption = selectedOption;
    });
  }
}

class TimesPerDurationSelector extends StatefulWidget {
  const TimesPerDurationSelector({required this.callback, super.key});

  final Function callback;

  @override
  _TimesPerDurationSelectorState createState() =>
      _TimesPerDurationSelectorState();
}

class _TimesPerDurationSelectorState extends State<TimesPerDurationSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberPicker(
          value: _numberPickerTimes,
          minValue: 1,
          maxValue: 100,
          onChanged: (value) {
            setState(() {
              _numberPickerTimes = value;
              widget.callback();
            });
          },
        ),
        Text("times per"),
        SizedBox(width: 10),
        DropdownButton<DurationType>(
          value: _selectedDuration,
          items: DurationType.values.map((DurationType duration) {
            return DropdownMenuItem<DurationType>(
              value: duration,
              child: Text(duration.prettyName),
            );
          }).toList(),
          onChanged: (DurationType? newValue) {
            setState(() {
              if (newValue != null) {
                _selectedDuration = newValue;
                widget.callback();
              }
            });
          },
        ),
      ],
    );
  }
}

class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
        ),
        Text(value.toString()),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class WeekdayToggleButtons extends StatefulWidget {
  const WeekdayToggleButtons({required this.callback, super.key});

  final Function callback;

  @override
  _WeekdayToggleButtonsState createState() => _WeekdayToggleButtonsState();
}

class _WeekdayToggleButtonsState extends State<WeekdayToggleButtons> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: Weekday.values.map((day) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              print("dlksf");
              _selectedDays[day] = !_selectedDays[day]!;
              widget.callback();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDays[day]!
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Text(
            _getDayLabel(day),
            style: TextStyle(
              color: _selectedDays[day]!
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayLabel(Weekday day) {
    switch (day) {
      case Weekday.sunday:
        return "S";
      case Weekday.monday:
        return "M";
      case Weekday.tuesday:
        return "T";
      case Weekday.wednesday:
        return "W";
      case Weekday.thursday:
        return "Th";
      case Weekday.friday:
        return "F";
      case Weekday.saturday:
        return "S";
    }
  }
}

class TimingOptionWidget extends StatelessWidget {
  final Widget child;
  final bool greyed;

  const TimingOptionWidget({
    super.key,
    required this.child,
    required this.greyed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: greyed ? 0.4 : 1.0, child: child);
  }
}

class SetPrizeRoute extends StatefulWidget {
  const SetPrizeRoute({super.key});

  @override
  State<StatefulWidget> createState() => _SetPrizeRouteState();
}

class _SetPrizeRouteState extends State<SetPrizeRoute> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final prizeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Prize"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Describe your prize:"),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: prizeController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter a detailed description of your prize...",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please provide a description!";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Validate and save the form
                      if (_formKey.currentState!.validate()) {
                        currentPlant.prizeDescription = prizeController.text;
                        currentPlant.startDate = SafeDateTime.now();
                        // populate default unwatered values
                        switch(currentPlant.timingOption!) {
                          case TimingOption.daysOfTheWeek:
                            currentPlant.wateredToday = false;
                            break;
                          case TimingOption.numTimesPerDuration:
                            currentPlant.numCompletedPerDuration=  0;
                          break;
                        }
                        PlantProvider provider = Provider.of<PlantProvider>(context, listen:false);
                        provider.addPlant(currentPlant.name!, currentPlant);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } 
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Submit"),
                        SizedBox.square(dimension: 4),
                        Icon(Icons.check),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
