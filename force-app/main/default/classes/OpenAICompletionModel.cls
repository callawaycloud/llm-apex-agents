public with sharing class OpenAICompletionModel implements CompletionModel.I {
  private static final String ENDPOINT = 'https://api.openai.com/v1/';

  private string apiKey;
  public OpenAICompletionModel(String apiKey) {
    this.apiKey = apiKey;
  }

  public String complete(String prompt, String[] stop) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();

    request.setEndpoint(ENDPOINT + 'completions');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Authorization', 'Bearer ' + apiKey);
    request.setMethod('POST');

    Map<String, Object> requestBody = new Map<String, Object>{
      'model' => 'text-davinci-003',
      'prompt' => prompt,
      'temperature' => 0.7,
      'max_tokens' => Integer.valueOf((prompt.length() / 4) + 500),
      'n' => 1,
      'stop' => stop
    };

    request.setBody(JSON.serialize(requestBody)); // serialize the Map as JSON

    HttpResponse response = http.send(request);

    if (response.getStatusCode() == 200) {
      Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );

      // System.debug(jsonResponse);
      List<Object> completions = (List<Object>) jsonResponse.get('choices');
      Map<String, Object> completion = (Map<String, Object>) completions[0];
      String text = (String) completion.get('text');
      return text.trim();
    } else {
      throw new OpenAIException(
        'OpenAI API returned status code ' + response.getStatusCode()
      );
    }
  }

  public class OpenAIException extends Exception {
  }
}
