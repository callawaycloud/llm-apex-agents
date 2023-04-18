//Written by Charlie Jonas
public class InternetSearchAgentTool implements IAgentTool {
  private string api_key;
  public InternetSearchAgentTool(String api_key) {
    this.api_key = api_key;
  }

  public string getDescription() {
    return 'Search the internet';
  }

  // Define the input parameter(s) for this action
  public Map<string, string> getParameters() {
    Map<string, string> params = new Map<string, string>();
    params.put('query', 'The search query to perform');
    return params;
  }

  public String execute(Map<string, string> args) {
    String query = args.get('query');
    if (query == null || query == '') {
      throw new SearchActionException('Query is empty');
    }

    HttpRequest request = new HttpRequest();
    request.setMethod('GET');
    request.setEndpoint(
      'https://serpapi.com/search.json?q=' +
        EncodingUtil.urlEncode(query, 'UTF-8') +
        '&hl=en&gl=us&api_key=' +
        EncodingUtil.urlEncode(api_key, 'UTF-8')
    );

    HttpResponse response = new Http().send(request);

    if (response.getStatusCode() == 200) {
      TypedResult data = (TypedResult) JSON.deserialize(
        response.getBody().replace('"list":', '"items":'),
        TypedResult.class
      );

      SearchReturn results = new SearchReturn();

      results.answer = data.answer_box;
      if (data.organic_results != null && data.organic_results.size() > 0) {
        results.organicResults = data.organic_results;
      }

      return JSON.serialize(results);
    } else {
      throw new SearchActionException(
        'API returned status code ' + response.getStatusCode()
      );
    }
  }

  private class SearchActionException extends Exception {
  }

  private class SearchReturn {
    public AnswerBox answer;
    public Result[] organicResults;
  }

  private class TypedResult {
    public AnswerBox answer_box;
    public Result[] organic_results;
    public GraphResult knowledge_graph;
  }

  private class AnswerBox {
    public String answer;
    public String[] items;
    public String snippet;
  }

  private class Result {
    public String snippet;
    public String[] snippet_highlighted_words;
    public string url;
  }

  private class GraphResult {
    public String description;
  }
}
