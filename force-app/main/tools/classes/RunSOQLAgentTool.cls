//Written by GPT-4
public class RunSOQLAgentTool implements IAgentTool {
  public String getDescription() {
    return 'Executes a SOQL query and returns JSON results';
  }

  public Map<String, String> getParameters() {
    return new Map<String, String>{
      'sql' => 'SQL to execute. May not contain any :variables'
    };
  }

  public String execute(Map<String, String> args) {
    // Check if sql argument is present
    if (!args.containsKey('sql')) {
      throw new Agent.ActionRuntimeException('Missing required parameter: sql');
    }

    // Get the SOQL query from parameters
    String soql = args.get('sql');

    // Perform the SOQL query
    List<SObject> records = Database.query(soql);

    // Serialize records to JSON format
    String jsonResponse = JSON.serialize(records);

    return jsonResponse;
  }
}
