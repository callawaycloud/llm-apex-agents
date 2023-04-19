// written by GPT-4
public class SOSLSearchAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Search of salesforce data';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{
      'term' => 'The search term',
      'objectType' => 'The SObject to search for'
    };
  }

  public string execute(Map<string, string> args) {
    String searchTerm = args.get('term');
    String objectType = args.get('objectType');

    if (searchTerm == null) {
      throw new Agent.ActionRuntimeException(
        'Missing required parameter: searchTerm'
      );
    }

    if (objectType == null) {
      throw new Agent.ActionRuntimeException(
        'Missing required parameter: objectType'
      );
    }

    List<List<sObject>> results = search.query(
      'find :searchTerm in all fields returning ' + objectType + ' limit 10'
    );
    return JSON.serialize(results);
  }
}
