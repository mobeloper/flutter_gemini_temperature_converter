// dependencies
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// root widget
void main() {
  runApp(const ProviderScope(child: GeminiTempApp()));
}

class GeminiTempApp extends StatelessWidget {
  const GeminiTempApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GeminiTempMain(),
    );
  }
}

class GeminiTempMain extends ConsumerWidget {
  const GeminiTempMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: Stack(children: [
      const GeminiTempBg(),
      Center(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(Icons.ac_unit,
                size: 100, color: Colors.white.withOpacity(0.75)),
            const GeminiTempDisplay(),
            const SizedBox(height: 24),
            const GeminiTempInput(),
          ]))
    ]));
  }
}

class GeminiTempInput extends ConsumerWidget {
  const GeminiTempInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
        width: 350,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                width: 20,
                color: Colors.white.withOpacity(0.25),
                strokeAlign: BorderSide.strokeAlignOutside)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GeminiTempSelector(),

            // receive user's input
            Expanded(
              child: TextFormField(
                controller: ref.read(tempFieldController),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 80,
                    color: Colors.black),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  hintText: '- -',
                  hintStyle: TextStyle(color: Colors.grey),
                  hintMaxLines: null,
                ),
                maxLength: 3,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  ref.read(tempInputValueProvider.notifier).state = value;
                },
              ),
            ),

            // custom styled button to trigger the workflow
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: ref.watch(tempInputValueProvider).isNotEmpty
                    ? () {
                        ref
                            .read(geminiRetrievalLocalVMProvider.notifier)
                            .convertTemp();
                      }
                    : null,
                child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                        color: ref.watch(tempInputValueProvider).isNotEmpty
                            ? Colors.purple
                            : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 30)),
              ),
            ),
          ],
        ));
  }
}

class GeminiTempSelector extends ConsumerWidget {
  const GeminiTempSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversion = ref.watch(tempConversionOptionProvider);

    // color configuration
    final selectedColor = Colors.purple.withOpacity(0.5);
    final unselectedColor = Colors.purple.withOpacity(0.125);

    const selectedLabel = Colors.white;
    final unselectedLabel = Colors.purple.withOpacity(0.5);

    return Column(
      children: List.generate(GeminiTempOptions.values.length, (index) {
        var tempOption = GeminiTempOptions.values[index];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              ref
                  .read(geminiRetrievalLocalVMProvider.notifier)
                  .onSelectConversion(tempOption);
            },
            child: Container(
              margin: EdgeInsets.only(
                  bottom: index < GeminiTempOptions.values.length - 1 ? 20 : 0),
              decoration: BoxDecoration(
                  color: conversion == tempOption
                      ? selectedColor
                      : unselectedColor,
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child: Text(tempOption.label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: conversion == tempOption
                          ? selectedLabel
                          : unselectedLabel,
                      fontSize: 30)),
            ),
          ),
        );
      }),
    );
  }
}

class GeminiTempDisplay extends StatelessWidget {
  const GeminiTempDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // icon
        Icon(Icons.thermostat,
            size: 100, color: Colors.white.withOpacity(0.75)),

        // spacing
        const SizedBox(width: 16),

        // consume the temp value
        Consumer(builder: (context, ref, child) {
          // watch on the result of the viewmodel's operation
          final dataRetrieved = ref.watch(geminiRetrievalLocalVMProvider);

          // watch on the temp value to be displayed
          final tempValue = ref.watch(tempDisplayValueProvider);

          // show a progress indicator if data is being retrieved...
          if (dataRetrieved) {
            return Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(
                minHeight: 150,
                minWidth: 150,
              ),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            );
          }

          // otherwise show whatever value is available, formatted appropriately
          return Text(tempValue.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 100,
                fontWeight: FontWeight.bold,
              ));
        }),

        // more spacing
        const SizedBox(width: 20),

        // consume the selected conversion value
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          child: Consumer(
            builder: (context, ref, child) {
              return Text(ref.watch(tempInverseConversionProvider).label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 30));
            },
          ),
        )
      ],
    );
  }
}

class GeminiTempBg extends StatelessWidget {
  const GeminiTempBg({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Colors.purple,
        Colors.deepPurple,
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }
}

enum GeminiTempOptions {
  fahrenheit2celsius('°F'),
  celsius2fahrenheit('°C');

  final String label;
  const GeminiTempOptions(this.label);
}

class GeminiTempRequest {
  final GeminiTempOptions conversion;
  final double temp;
  final String fromValue;
  final String toValue;

  GeminiTempRequest(
      {required this.fromValue,
      required this.toValue,
      required this.conversion,
      required this.temp});

  String toJson() {
    return json.encoder.convert({
      'conversion': conversion.name,
      'temp': temp,
      'fromValue': fromValue,
      'toValue': toValue,
    });
  }
}

class GeminiTempResponse {
  final GeminiTempOptions conversion;
  final double inputValue;
  final double outputValue;

  const GeminiTempResponse({
    required this.inputValue,
    required this.outputValue,
    required this.conversion,
  });

  factory GeminiTempResponse.fromJSON(Map<String, dynamic> json) {
    return GeminiTempResponse(
      inputValue: json['inputValue'],
      outputValue: json['outputValue'],
      conversion: GeminiTempOptions.values
          .firstWhere((c) => c.name == json['conversion']),
    );
  }

  static GeminiTempResponse empty() {
    return const GeminiTempResponse(
        conversion: GeminiTempOptions.celsius2fahrenheit,
        inputValue: 0,
        outputValue: 0);
  }
}

// providers

final tempFieldController = Provider((ref) {
  return TextEditingController();
});

final tempDisplayValueProvider = StateProvider<double>((ref) {
  return 0;
});

final tempInputValueProvider = StateProvider<String>((ref) {
  return '';
});

final tempRetrievalFlagProvider = StateProvider<bool>((ref) {
  return false;
});

final tempConversionOptionProvider = StateProvider<GeminiTempOptions>(
    (ref) => GeminiTempOptions.celsius2fahrenheit);

final tempInverseConversionProvider = Provider((ref) {
  final selectedConversion = ref.watch(tempConversionOptionProvider);
  return selectedConversion == GeminiTempOptions.celsius2fahrenheit
      ? GeminiTempOptions.fahrenheit2celsius
      : GeminiTempOptions.celsius2fahrenheit;
});

final tempServiceProvider = Provider((ref) {
  return GeminiTempService();
});

final geminiRetrievalLocalVMProvider =
    StateNotifierProvider<GeminiTempLocalRetrievalViewModel, bool>((ref) {
  return GeminiTempLocalRetrievalViewModel(ref, false);
});

// service class

class GeminiTempService {
  Future<GeminiTempResponse> getTemperature(GeminiTempRequest req) async {
    var prompt = '''generate a JSON payload that returns the conversion
    of weather from farenheit to celsius and viceversa; 
    return a JSON payload containing the following structure -
    {
      "conversion": the value of the conversion, in this case it should read "${req.conversion.name}" depending on the conversion;
      "inputValue": the value of ${req.temp} to convert from ${req.fromValue}; 
      "outputValue": the result from the conversion to ${req.toValue}.
    }
    ''';

    const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
    // const geminiApiKey = Env.geminiApiKey;

    if (geminiApiKey.isEmpty) {
      throw AssertionError('GEMINI_API_KEY is not set');
    }

    try {
      final content = [Content.text(prompt)];
      final model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: geminiApiKey,
          generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              responseSchema: Schema.object(properties: {
                "conversion": Schema.enumString(
                    enumValues:
                        GeminiTempOptions.values.map((t) => t.name).toList()),
                "inputValue": Schema.number(format: 'double'),
                "outputValue": Schema.number(format: 'double'),
              })));

      final response = await model.generateContent(content);
      var jsonResponse = json.decode(response.text!);

      //Convert the response to our expected format
      var geminiResponse = GeminiTempResponse.fromJSON(jsonResponse);
      return geminiResponse;
    } on Exception {
      rethrow;
    }
  }
}

class GeminiTempLocalRetrievalViewModel extends StateNotifier<bool> {
  final Ref ref;
  GeminiTempLocalRetrievalViewModel(this.ref, super._state);

  Future<void> convertTemp() async {
    state = true;

    var tempValue = ref.read(tempInputValueProvider);
    var selectedConversion = ref.read(tempConversionOptionProvider);

    var fromToConversion = selectedConversion.name.split('2');
    final req = GeminiTempRequest(
        conversion: selectedConversion,
        temp: double.parse(tempValue),
        fromValue: fromToConversion[0],
        toValue: fromToConversion[1]);

    try {
      GeminiTempResponse response =
          await ref.read(tempServiceProvider).getTemperature(req);
      ref.read(tempDisplayValueProvider.notifier).state = response.outputValue;
    } on Exception {
      ref.read(tempDisplayValueProvider.notifier).state = 0;
    }

    state = false;
  }

  void resetValues() {
    ref.read(tempFieldController).clear();
    ref.read(tempInputValueProvider.notifier).state = '';
    ref.read(tempDisplayValueProvider.notifier).state = 0;
  }

  void onSelectConversion(GeminiTempOptions tempOption) {
    resetValues();
    ref.read(tempConversionOptionProvider.notifier).state = tempOption;
  }
}
