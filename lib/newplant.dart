import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      body: DefaultTextStyle.merge(style: RootineStyle.textStyle,
        child: Center(child: NewPlantForm(),),)
    );
  }
}

class NewPlantForm extends StatefulWidget {
  const NewPlantForm({
    super.key,
  });

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
              )
              
            ]
          ),

          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text("Your plant will harvest on"),
            SizedBox.square(dimension: 20,),
            HarvestDatePicker() 

          ],),
          ElevatedButton(onPressed: () {
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content:Text("thank you!!!"))
              );
            }
          }, 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
            [
              Text("Next"),
              SizedBox.square(dimension: 4),
              Icon(Icons.arrow_forward),
            ],
          ),
          ),
        ] 
        ),
    );
  }
}

class HarvestDatePicker extends StatefulWidget {
  const HarvestDatePicker({
    super.key,
  });

  @override
  HarvestDatePickerState createState() {
    return HarvestDatePickerState();
  }

}

class HarvestDatePickerState extends State {
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) {

    String formattedDate = DateFormat('MM-dd-yy').format(selected);
    return ElevatedButton(onPressed: () {}, child: Text(formattedDate));
  }

}