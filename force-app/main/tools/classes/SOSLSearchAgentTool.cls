public class SOSLSearchAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Search for Salesforce Records';
  }

  public Map<string, string> getParameters() {
    Map<string, string> params = new Map<string, string>();
    params.put('term', 'The search term');
    params.put('objectType', 'The SObject to search for');
    return params;
  }

  public string execute(Map<string, string> args) {
    String searchTerm = args.get('term');
    String objectType = args.get('objectType');
    List<List<sObject>> results = search.query(
      'find :searchTerm in all fields returning ' + objectType + ' limit 10'
    );
    return JSON.serialize(results);
  }
}
