public class InternetSearchAgentAction implements IAgentTool {
  private string api_key;
  public InternetSearchAgentAction(String api_key) {
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
    request.setEndpoint(
      'https://serpapi.com/search.json?q=' +
        EncodingUtil.urlEncode(query, 'UTF-8') +
        '&hl=en&gl=us&api_key=' +
        EncodingUtil.urlEncode(api_key, 'UTF-8')
    );
    request.setMethod('GET');

    HttpResponse response = new Http().send(request);

    if (response.getStatusCode() == 200) {
      TypedResult data = (TypedResult) JSON.deserialize(
        response.getBody(),
        TypedResult.class
      );
      if (data.answer_box?.answer != null) {
        return data.answer_box.answer;
      }

      if (data.answer_box?.snippet != null) {
        return data.answer_box.snippet;
      }

      // if (data.answer_box?.snippet_highlighted_words) {
      //   return data.answer_box.snippet_highlighted_words[0];
      // }

      if (data.knowledge_graph?.description != null) {
        return data.knowledge_graph.description;
      }

      if (data.organic_results != null && data.organic_results.size() > 0) {
        return data.organic_results[0].snippet;
      }

      throw new SearchActionException('No results found');
    } else {
      throw new SearchActionException(
        'API returned status code ' + response.getStatusCode()
      );
    }
  }

  private class SearchActionException extends Exception {
  }

  private class TypedResult {
    public AnswerBox answer_box;
    public Result[] organic_results;
    public GraphResult knowledge_graph;
  }
  private class AnswerBox {
    public String answer;
    public String snippet;
    public String[] snippet_highlighted_words;
  }
  private class Result {
    public String snippet;
    public String[] snippet_highlighted_words;
  }
  private class GraphResult {
    public String description;
  }
}
