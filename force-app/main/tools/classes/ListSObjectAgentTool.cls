//Written by Charlie Jonas

public class ListSObjectAgentTool implements IAgentTool {
  // There are FAR too many standard objects in salesforce.  Let's just hardcode the popular ones...
  private static Set<String> standardObjects = new Set<String>{
    'Account',
    'Contact',
    'Lead',
    'Opportunity',
    'Case',
    'Task',
    'Event',
    'User',
    'Profile',
    'PermissionSet',
    'Group',
    'Campaign',
    'CampaignMember',
    'Report',
    'Dashboard',
    'Attachment',
    'ContentDocument',
    'ContentVersion',
    'ContentDocumentLink',
    'Contract',
    'Quote',
    'QuoteLineItem',
    'Product2',
    'Pricebook2',
    'PricebookEntry',
    'Asset',
    'PartnerNetworkConnection',
    'Solution',
    'Idea',
    'FeedItem',
    'FeedComment',
    'HashtagDefinition',
    'ChatterActivity',
    'CollaborationGroup',
    'Calendar',
    'UserRole',
    'Territory',
    'Territory2',
    'ForecastingType',
    'OpportunityLineItem',
    'RevenueSchedule',
    'RevenueScheduleLine',
    'Invoice',
    'InvoiceLine',
    'Entitlement',
    'Milestone',
    'Project',
    'WorkOrder',
    'ServiceAppointment',
    'KnowledgeArticleVersion'
  };

  public String getDescription() {
    return 'Lists API names of SObjects in the salesforce org';
  }

  public Map<String, String> getParameters() {
    return new Map<String, String>();
  }

  public String execute(Map<String, String> args) {
    List<SObjectData> objects = new List<SObjectData>();
    EntityDefinition[] def = [
      SELECT Label, QualifiedApiName, NamespacePrefix
      FROM EntityDefinition
    ]; // NamespacePrefix = null doesn't work for some reason :(
    for (EntityDefinition d : def) {
      if (
        d.NamespacePrefix == null && d.QualifiedApiName.endsWith('__c') ||
        standardObjects.contains(d.QualifiedApiName)
      ) {
        objects.add(new SObjectData(d.QualifiedApiName, d.Label));
      }
    }

    return JSON.serialize(objects);
  }

  public class SObjectData {
    public SObjectData(String apiName, String label) {
      this.apiName = apiName;
      this.label = label;
    }
    public String apiName;
    public String label;
  }
}
