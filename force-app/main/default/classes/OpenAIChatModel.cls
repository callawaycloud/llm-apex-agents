public class OpenAIChatModel implements ChatModel.I {
  private static final String ENDPOINT = 'https://api.openai.com/v1/';

  private string apiKey;
  public string model = 'gpt-4'; // 'gpt-4' | 'gpt-3.5-turbo'
  public Decimal tempature = 0.0;
  public Integer maxTokens = 2000;
  public string namedCrediential = 'OpenAI';
  public static Integer retryCount = 0;
  public static final Integer maxRetries = 3;

  public String chat(ChatModel.Message[] messages) {

    while(retryCount < maxRetries) {
      retryCount++;

      Http http = new Http();
      HttpRequest request = new HttpRequest();

      request.setEndpoint('callout:' + namedCrediential + '/chat/completions');
      request.setHeader('Content-Type', 'application/json');
      request.setHeader('Authorization', 'Bearer {!$Credential.OpenAI.API_KEY}');
      request.setMethod('POST');
      request.setTimeout(120000);

      ChatAPIRequest requestBody = new ChatAPIRequest();
      requestBody.messages = messages;
      requestBody.model = model;
      requestBody.temperature = tempature;
      requestBody.max_tokens = maxTokens; // TODO dynamicly set this by calculating tokens
      requestBody.stream = false;

      request.setBody(JSON.serialize(requestBody, true));

      HttpResponse response = http.send(request);
      statusCode = response.getStatusCode();
      statusMessage = response.getStatus();

      switch on statusCode {
        when 200 { // success
          ChatAPICompletion results = (ChatAPICompletion) JSON.deserialize(
            response.getBody(),
            ChatAPICompletion.class
          );
  
          OpenAIChatModel.Choice completion = results.choices[0];
          return completion.message?.content?.trim();
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
          if(statusCode == 429 && statusMessage.contains('overloaded')) {
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

  public class ChatAPIRequest {
    public List<ChatModel.Message> messages;
    public Decimal temperature;
    public Integer max_tokens;
    public Decimal top_p;
    public Decimal frequency_penalty;
    public Decimal presence_penalty;
    public String model;
    public Boolean stream;
    public String parentId;
  }

  public class ChatAPICompletion {
    public String id;
    // public String object;
    public Long created;
    public String model;
    public Usage usage;
    public List<Choice> choices;
  }

  public class Usage {
    public Integer prompt_tokens;
    public Integer completion_tokens;
    public Integer total_tokens;
  }

  public class Choice {
    public ChatModel.Message message;
    public String finish_reason;
    public Integer index;
  }
}
