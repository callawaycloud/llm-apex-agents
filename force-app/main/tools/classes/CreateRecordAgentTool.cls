//Written by GPT-4
public class CreateRecordAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Inserts/Updates records into the database';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{
      'operation' => 'insert|update|upsert',
      'sObjectType' => 'The SObject API name',
      'records' => 'String of escaped JSON array with record data (fields and values)'
    };
  }

  public string execute(Map<string, string> args) {
    String sObjectType = args.get('sObjectType');
    String fieldsJson = args.get('records');

    if (String.isBlank(sObjectType) || String.isBlank(fieldsJson)) {
      return 'Error: Missing parameter(s). Please provide both sObjectType and fields.';
    }

    try {
      SObjectType objectType = Schema.getGlobalDescribe().get(sObjectType);
      if (objectType == null) {
        return 'Error: Invalid sObjectType provided.';
      }

      SObject[] records = new List<SObject>();

      List<Object> inputList = (List<Object>) JSON.deserializeUntyped(
        fieldsJson
      );

      for (Object data : inputList) {
        SObject record = objectType.newSObject();
        Map<String, Object> fieldsData = (Map<String, Object>) data;
        for (String fieldName : fieldsData.keySet()) {
          record.put(fieldName, fieldsData.get(fieldName));
        }
        records.add(record);
      }

      string operation = args.get('operation');

      if (operation == 'update') {
        update records;
      } else if (operation == 'upsert') {
        upsert records;
      } else if (operation == 'insert') {
        insert records;
      }

      String[] ids = new List<String>{};
      for (SObject record : records) {
        ids.add(record.Id);
      }

      return 'New Record Ids: ' + String.join(ids, ', ');
    } catch (Exception e) {
      return 'Error: ' + e.getMessage();
    }
  }
}
