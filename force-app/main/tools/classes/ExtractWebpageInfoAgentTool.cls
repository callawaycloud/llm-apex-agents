// written by GPT-4
public class ExtractWebpageInfoAgentTool implements IAgentTool {
  private string api_key;
  private ChatModel.I summerizationModel;
  public ExtractWebpageInfoAgentTool(
    String api_key,
    ChatModel.I summerizationModel
  ) {
    this.api_key = api_key;
    this.summerizationModel = summerizationModel;
  }

  public string getDescription() {
    return 'find information in webpage';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{
      'url' => 'The url/link of the webpage to search in',
      'targetInfo' => '(optional) A general description of the information you are looking for'
    };
  }

  // make a call to https://extractorapi.com/api/v1/extractor/?apikey=14ad2ea5995045b351e90595786fb6106a52aa0b&url=example.com&fields=text
  // get the "text" from the resulting json
  // if targetInfo is provided, use the summerization model to get a summary of the text
  public String execute(Map<string, string> args) {
    // Check if the required 'url' parameter is provided
    if (!args.containsKey('url')) {
      throw new Agent.ActionRuntimeException(
        'Error: Missing required parameter "url".'
      );
    }

    // Prepare the request
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'https://extractorapi.com/api/v1/extractor/?apikey=' +
        EncodingUtil.urlEncode(api_key, 'UTF-8') +
        '&url=' +
        EncodingUtil.urlEncode(args.get('url'), 'UTF-8') +
        '&fields=' +
        EncodingUtil.urlEncode('text,raw_text,clean_html', 'UTF-8')
    );
    req.setMethod('GET');
    req.setTimeout(120000);

    // Send the request
    Http http = new Http();
    HttpResponse res;
    try {
      res = http.send(req);
    } catch (Exception e) {
      throw new Agent.ActionRuntimeException(
        'Failed to fetch data from the provided URL. ' + e.getMessage()
      );
    }

    // Parse the response
    ExtractResult result = (ExtractResult) JSON.deserialize(
      res.getBody(),
      ExtractResult.class
    );

    // Check the status_code and status of the response
    if (result.status_code != 200) {
      throw new Agent.ActionRuntimeException(
        'Failed to extract text from the URL. Status code: ' +
          result.status_code +
          ', Status: ' +
          result.status
      );
    }

    // Keep it at roughly 1000 tokens
    // TODO: consider using chunk summary instead
    String webText = result.clean_html.length() < 4000
      ? result.clean_html
      : result.raw_text.length() < 4000
          ? result.raw_text
          : result.text.length() < 4000
              ? result.text
              : result.text.substring(0, 4000);

    // If targetInfo is provided, use the summarization model to get a summary of the text
    if (
      args.containsKey('targetInfo') && !String.isEmpty(args.get('targetInfo'))
    ) {
      try {
        ChatModel.Message[] messages = new List<ChatModel.Message>{
          new ChatModel.Message(
            'system',
            'Your job is to find and return the requested information from webpage text. Be concise, yet complete'
          ),
          new ChatModel.Message(
            'user',
            'Requested Info:\n"""' +
              args.get('targetInfo') +
              '"""' +
              '\n\nWebpage:\n"""' +
              webText +
              '"""'
          )
        };
        return summerizationModel.chat(messages);
      } catch (Exception e) {
        throw new Agent.ActionRuntimeException(
          'Failed to summarize text. ' + e.getMessage()
        );
      }
    } else {
      return result.text;
    }
  }

  private class ExtractResult {
    public Integer status_code;
    public String status;
    public String text;
    public String url;
    public String raw_text;
    public String clean_html;
  }
}
