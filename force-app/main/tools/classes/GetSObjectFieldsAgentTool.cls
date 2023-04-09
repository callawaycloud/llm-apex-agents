public class GetSObjectFieldsAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Get all fields on an SObject';
  }

  public Map<string, string> getParameters() {
    Map<string, string> params = new Map<string, string>();
    params.put('sobject', 'API Name of the SObject');
    return params;
  }

  public string execute(Map<string, string> args) {
    String sobType = args.get('sobject');
    SObjectType accountType = Schema.getGlobalDescribe().get('Account');
    Map<String, Schema.SObjectField> mfields = accountType.getDescribe()
      .fields.getMap();
    String[] fields = new List<String>{};
    for (String key : mfields.keySet()) {
      Schema.DescribeFieldResult field = mfields.get(key).getDescribe();
      fields.add(
        String.format(
          '{0}: {1}',
          new List<String>{ field.getName(), field.getType().name() }
        )
      );
    }
    return JSON.serialize(fields);
  }
}
