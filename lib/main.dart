import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

final formProvider = ChangeNotifierProvider((ref) => FormState());

class FormState extends ChangeNotifier {
  late List<FormFieldModel> formFields = [];
  late Map<String, dynamic> formData = {}; // Map to store form data

  // Method to update form field value
  void updateFormFieldValue(String fieldName, dynamic value) {
    formData[fieldName] = value;
    print('equre ****${formData[fieldName] = value}*****');
    notifyListeners(); // Notify listeners to trigger UI updates
  }

  // Method to get field value
  dynamic getFieldValue(String fieldName) {
    return formData[fieldName];
  }

  void loadFormFromJson(String jsonStr) {
    final List<dynamic> jsonList = json.decode(jsonStr);
    formFields = jsonList.map((json) => FormFieldModel.fromJson(json)).toList();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Form',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dynamic Form'),
        ),
        body: FormFieldList(),
      ),
    );
  }
}

class FormFieldList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(formProvider);
    final selectedDropdownValue = formState.getFieldValue('f1'); // Assuming 'f1' is the dropdown field
    print('selectedDropdownValue ===$selectedDropdownValue');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () async {
            String jsonString = await rootBundle.loadString('assets/form_data.json');
            formState.loadFormFromJson(jsonString);
          },
          child: const Text('Load Form'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: formState.formFields.length,
            itemBuilder: (context, index) {
              final field = formState.formFields[index];

            //    print('eeee Condition ${field.visibleCondition == '${field.fieldName}==$selectedDropdownValue'}');
            //    print('bbbb Condition ===${ '${field.fieldName}==$selectedDropdownValue'}');

            // final bool visib =  field.visibleCondition == '${field.fieldName}==$selectedDropdownValue';
            //   return Visibility(
            //     visible: visib,
            //     child:FormFieldWidget(field: field)
            //     );

              field.visibleCondition;
              if (field.widgetType == WidgetType.textfield) {
                // Check visibility condition only for textfields
                final isVisible = field.isVisible(formState, selectedDropdownValue);
                //print('isVisible ====$isVisible');
                if (!isVisible) {
                  return SizedBox(); // Skip rendering if not visible
                }
              }
              return FormFieldWidget(field: field);
            },
          ),
        ),
      ],
    );
  }
}


class FormFieldWidget extends ConsumerWidget {
  final FormFieldModel field;

  const FormFieldWidget({Key? key, required this.field}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(formProvider);
    final selectedDropdownValue = formState.getFieldValue('f1');
    final isVisible = field.isVisible(formState, selectedDropdownValue);

   // print("isVisible ====${field.isVisible(formState)}");

    if (!isVisible) {
      return const SizedBox(); // Return an empty container if not visible
    }

    Widget formField;

    switch (field.widgetType) {
      case WidgetType.dropdown:
        formField = DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: field.fieldName),
        items: field.validValues!.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
  }).toList(),
  onChanged: (value) {
    // Update form data
    //print('field nme ${field.fieldName}');
    // print('field value ${value}');

    formState.updateFormFieldValue(field.fieldName, value);
  },


        );
        break;
      case WidgetType.textfield:
 // Check visibility condition for textfields
 final selectedDropdownValue = formState.getFieldValue('f1');
 print('selectedDropdownValue in textField $selectedDropdownValue');
  final isVisible = field.isVisible(formState, selectedDropdownValue);

  print('isVisible in textField $isVisible');
  formField = Visibility(
    visible: isVisible,
    child: TextFormField(
      decoration: InputDecoration(labelText: field.fieldName),
    ),
  );
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: formField,
    );
  }
}

class FormFieldModel {
  final String fieldName;
  final WidgetType widgetType;
  final List<String>? validValues;
  final String? visibleCondition;

  FormFieldModel({
    required this.fieldName,
    required this.widgetType,
    this.validValues,
    this.visibleCondition,
  });

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    return FormFieldModel(
      fieldName: json['field_name'],
      widgetType: widgetTypeFromString(json['widget']),
      validValues: json['valid_values'] != null
          ? List<String>.from(json['valid_values'])
          : null,
      visibleCondition: json['visible'],
    );
  }

  bool isVisible(FormState formState, String? selectedDropdownValue) {
    if (widgetType != WidgetType.textfield) {
      return true; // Skip visibility check for non-textfield widgets
    }

    if (visibleCondition == null || visibleCondition!.isEmpty) {
      return true; // If no condition is specified, the field is always visible
    }

    // Split the condition into field name and comparison
    final List<String> parts = visibleCondition!.split("=='");
    if (parts.length != 2) {
      // Invalid condition, treat as visible
      return true;
    }

    final String fieldName = parts[0].trim();
    final String comparison = parts[1].trim();

    // Retrieve the current value of the referenced field from the form state
    final fieldValue = formState.getFieldValue(fieldName);

    final List<String> prts = (parts[1]).split("'");
    final String compare = prts[0].trim();

    // Compare the field value with the comparison value
    // print(fieldValue);
    // print(comparison);
    // print('compare == $compare');

    // print('compre ${fieldValue == compare}');
    return fieldValue == compare;
  }

}

enum WidgetType { dropdown, textfield }

WidgetType widgetTypeFromString(String widgetType) {
  return widgetType == 'dropdown' ? WidgetType.dropdown : WidgetType.textfield;
}
