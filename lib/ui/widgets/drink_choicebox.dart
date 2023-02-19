import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provauth/constants.dart';

class DrinkChoiceBox extends StatefulWidget {
  @override
  State<DrinkChoiceBox> createState() => _DrinkChoiceBoxState();
}

class _DrinkChoiceBoxState extends State<DrinkChoiceBox> {
  final controllerCocktails = TextEditingController();
  String? selectedCocktail;

  @override
  void initState() {
    cocktailsList.clear();
    drinkNameToImage.forEach((key, value) {
      Cocktail cocktail = Cocktail(key, value);
      cocktailsList.add(cocktail);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadFormField<Cocktail?>(
      textFieldConfiguration: TextFieldConfiguration(
        style: TextStyle(
            color: Color(COLOR_PRIMARY)
        ),
        cursorColor: Color(COLOR_PRIMARY),
        controller: controllerCocktails,
        decoration: const InputDecoration(
          hintText: 'Select your favourite drink',
          hintStyle: TextStyle(
              color: Color(0xFFFFECB3),
          ),
          labelText: 'Favourite Cocktail',
          labelStyle: TextStyle(
            color: Color(COLOR_PRIMARY)
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFECB3)),
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Color(COLOR_PRIMARY)
              )
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(COLOR_PRIMARY))
          ),
        ),
      ),
      suggestionsCallback: getSuggestions,
      itemBuilder: (context, Cocktail? suggestion) => ListTile(
        tileColor: Colors.black87,
        title: Text(suggestion!.name,style: TextStyle(color: Color(COLOR_PRIMARY)),),
        leading: Image(
          image: AssetImage(suggestion.url),
          height: 40,
          width: 40,
        ),
      ),
      onSuggestionSelected: (Cocktail? suggestion) => controllerCocktails.text = suggestion!.name,
      validator: (value) => value != null && value.isEmpty ? 'Please select a cocktail' : null,
      onSaved: (value) => selectedCocktail = value,
    );
  }

  static List<Cocktail> getSuggestions(String query) =>
      List.of(cocktailsList).where((cocktail) {
        final cocktailLower = cocktail.name.toLowerCase();
        final queryLower = query.toLowerCase();

        return cocktailLower.contains(queryLower);
      }).toList();
}

class Cocktail{
  final String name;
  final String url;
  Cocktail(this.name, this.url);
}
