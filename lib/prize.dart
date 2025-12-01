import 'dart:convert';
import 'package:flutter/material.dart';
import 'plant.dart'; // Import your Plant class

Route buildPrizeRoute(BuildContext context, Plant plant) {
  return MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: Text('You won a prize!'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, // Match app theme
      ),
      body: SingleChildScrollView( // Make content scrollable
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Center content vertically
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                  child: Image.asset(
                    plant.getPlantImagePath(),
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
                Text(
                  'Congratulations!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Card( // Wrap prize content in a Card
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (plant.rewardType == RewardType.drawing)
                          plant.prizeDescription != null
                              ? Image.memory(
                                  base64Decode(plant.prizeDescription!),
                                )
                              : Text('No prize image available'),
                        if (plant.rewardType != RewardType.drawing)
                          Text(
                            plant.prizeDescription ?? 'No prize description available',
                            style: TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'You earned this prize by sticking to the habit: "${plant.desc}" '
                  'for ${plant.startDate!.difference(plant.expiration!).inDays.abs()} days!',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
