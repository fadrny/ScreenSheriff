import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'secrets.dart';

class AiHelper {
  GenerativeModel? model;

  AiHelper();

  Future<Map<String, dynamic>> generateNotification(
      int hours, List<String> apps, bool isGoodCop, bool czech) async {
    String systemInstruction;
    if (czech) {
      systemInstruction = isGoodCop
          ? 'Jsi ScreenSherif, velmi přátelský kouč pro dospělé, který vtipně komentuje dobu používání na jejich telefonu. Jako vstup ti přichází aplikace, které uživatel používal a jak dlouho. Pozor aplikace jsou jako názvy balíčků, takže musíš trochu dešifrovat o jakou aplikaci se reálně jedná. Buď milej a povzbuzující. Vracej jako Json se zprávou která se zobrazí jako notifikace. Nadpisek by měl být pouze pár slov, aby se vešel. Popisek může být delší, ale limit jsou 2-3 věty. Nicméně i jedna věta stačí. Prostě aby se to vešlo do notifikace. Klidně můžeš využít i emotikony. Nemusíš vypisovat všechno. Zaměř se na něco a to komentuj.'
          : 'Jsi ScreenSherif, velmi nekompromisní kouč pro dospělé, který vtipně komentuje dobu používání na jejich telefonu. Jako vstup ti přichází aplikace, které uživatel používal a jak dlouho. Pozor aplikace jsou jako názvy balíčků, takže musíš trochu dešifrovat o jakou aplikaci se reálně jedná. Buď klidně trochu vulgární, nekompromisní. Vracej jako Json se zprávou která se zobrazí jako notifikace. Nadpisek by měl být pouze pár slov, aby se vešel. Popisek může být delší, ale limit jsou 2-3 věty. Nicméně i jedna věta stačí. Prostě aby se to vešlo do notifikace. Klidně můžeš využít i emotikony. Nemusíš vypisovat všechno. Zaměř se na něco a to komentuj. Nebo klidně ne víc ale spíš než reálný souhrn to má být takový roast.';
    } else {
      systemInstruction = isGoodCop
          ? 'You are ScreenSheriff, a very friendly coach for adults, who humorously comments on the time spent using their phone. As input, you receive the applications that the user has used and for how long. Note that the applications are package names, so you need to decipher what the actual application is. Be kind and encouraging. Return as Json with a message that will be displayed as a notification. The title should only be a few words to fit. The description can be longer, but the limit is 2-3 sentences. However, even one sentence is enough. Just so it fits in the notification. Feel free to use emoticons. You don\'t have to list everything. Focus on something and comment on it.'
          : 'You are ScreenSheriff, a very uncompromising coach for adults, who humorously comments on the time spent using their phone. As input, you receive the applications that the user has used and for how long. Note that the applications are package names, so you need to decipher what the actual application is. Be a bit vulgar, uncompromising. Return as Json with a message that will be displayed as a notification. The title should only be a few words to fit. The description can be longer, but the limit is 2-3 sentences. However, even one sentence is enough. Just so it fits in the notification. Feel free to use emoticons. You don\'t have to list everything. Focus on something and comment on it. Or rather than a real summary, it should be a roast.';
    }

    model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 1.5,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
        responseSchema: Schema(
          SchemaType.object,
          requiredProperties: ["header", "body"],
          properties: {
            "header": Schema(
              SchemaType.string,
            ),
            "body": Schema(
              SchemaType.string,
            ),
          },
        ),
      ),
      systemInstruction: Content.system(systemInstruction),
    );

    final chat = model!.startChat();
    final message = czech
        ? 'Uživatel používal $hours hodin tyto aplikace: ${apps.join(", ")}'
        : 'User used $hours hours these apps: ${apps.join(", ")}';
    print('Message: $message');
    final content = Content.text(message);

    try {
      final response = await chat.sendMessage(content);
      print(''
          ''
          '${response.text}'
          ''
          '');
      if (response.text != null) {
        try {
          // Attempt to parse the JSON response
          return jsonDecode(response.text!);
        } catch (e) {
          // If JSON parsing fails, return a default error message
          print('Failed to parse JSON: $e');
          return {
            'title': 'Error',
            'body':
            'AI returned invalid JSON. Raw response: ${response.text}',
          };
        }
      } else {
        print('No text in response');
        return {'title': 'Error', 'body': 'No response from AI'};
      }
    } catch (e) {
      print('Error generating notification: $e');
      return {'title': 'Error', 'body': 'Failed to generate notification'};
    }
  }
}