public with sharing class OpenAICompletionModel implements CompletionModel.I {
  private static final String ENDPOINT = 'https://api.openai.com/v1/';
  public static Integer retryCount = 0;
  public static final Integer maxRetries = 3;

  private string apiKey;
  public OpenAICompletionModel(String apiKey) {
    this.apiKey = apiKey;
  }

  public String complete(String prompt, String[] stop) {
    while(retryCount < maxRetries) {
      retryCount++;
    
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
      statusCode = response.getStatusCode();
      statusMessage = response.getStatus();

      switch on statusCode {
        when 200 { // success
          Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(
            response.getBody()
          );
  
          // System.debug(jsonResponse);
          List<Object> completions = (List<Object>) jsonResponse.get('choices');
          Map<String, Object> completion = (Map<String, Object>) completions[0];
          String text = (String) completion.get('text');
          return text.trim();
        }
        when else {
          // ======================================
          // = OpenAI API Error Codes:
          // ======================================
          // 401 - Invalid Authentication
          // 401 - Incorrect API key provided
          // 401 - You must be a member of an organization to use the API
          // 429 - Rate limit reached for requests
          // 429 - You exceeded your current quota, please check your plan and billing details
          // 429 - The engine is currently overloaded, please try again later
          // 500 - The server had an error while processing your request
          // ======================================
          // Retry only for the case 
          // 429 - The engine is currently overloaded, please try again later
          if(statusCode == 429 && statusMessage.contains('overloaded') {
            continue; // retry up to maxRetries times
          }
          // else throw exception
          system.debug(response.getBody());
          throw new OpenAIException(
            'OpenAI API returned status code: ' + statusCode + '-' + statusMessage
          );
        }
      }
    }
  }

  public class OpenAIException extends Exception {
  }
}
