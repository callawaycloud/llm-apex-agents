public class zFileCreationAgentTool implements IAgentTool {
    public String getDescription() {
        return 'Create Salesforce files and optionally link them to Salesforce records';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>{
            'fileName' => 'The name of the file to be created',
            'fileTextContent' => 'File content as a string',
            'recordId' => 'The Salesforce record Id to which the file should be linked (optional)'
        };
    }

    private Blob base64Encode(String data) {
        Blob inputBlob = Blob.valueOf(data);
        return Blob.valueOf(EncodingUtil.base64Encode(inputBlob));
    }

    public String execute(Map<String, String> args) {
        if (!args.containsKey('fileName')) {
            throw new Agent.ActionRuntimeException('Missing required parameter: fileName');
        }

        if (!args.containsKey('fileTextContent')) {
            throw new Agent.ActionRuntimeException('Missing required parameter: fileTextContent');
        }

        String fileName = args.get('fileName');
        String fileContent = args.get('fileTextContent');

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = base64Encode(fileContent);
        cv.IsMajorVersion = true;
        insert cv;

        if (args.containsKey('recordId')) {
            ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = args.get('recordId');
            cdl.ContentDocumentId = cv2.ContentDocumentId;
            cdl.shareType = 'V';
            insert cdl;
        }

        return 'File created with Id: ' + cv.id;
    }
}