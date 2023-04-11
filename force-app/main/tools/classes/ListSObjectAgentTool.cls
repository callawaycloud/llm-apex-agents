//Written by Charlie Jonas
public class ListSObjectAgentTool implements IAgentTool {
  public String execute(Map<String, String> args) {
    List<String> customObjectNames = new List<String>();
    EntityDefinition[] def = [
      SELECT Label, QualifiedApiName, NamespacePrefix
      FROM EntityDefinition
    ]; // NamespacePrefix = null doesn't work for some reason :(
    for (EntityDefinition d : def) {
      if (d.NamespacePrefix == null && d.QualifiedApiName.endsWith('__c')) {
        customObjectNames.add(d.QualifiedApiName);
      }
    }

    return JSON.serialize(customObjectNames);
  }

  public String getDescription() {
    return 'Lists Custom SObjects in the salesforce org';
  }

  public Map<String, String> getParameters() {
    return new Map<String, String>();
  }
}
