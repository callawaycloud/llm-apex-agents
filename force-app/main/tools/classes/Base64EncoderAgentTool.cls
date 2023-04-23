public class Base64EncoderAgentTool implements IAgentTool {
  
    public String getDescription() {
      return 'Base64 encodes the input data';
    }
  
    public Map<String, String> getParameters() {
      return new Map<String, String>({
        'data' => 'The data to be base64 encoded'
      });
    }
  
    public String execute(Map<String, String> args) {
      if (String.isEmpty(args.get('data'))) {
        throw new Agent.ActionRuntimeException('missing required parameter: data');
      }
      return base64Encode(args.get('data'));
    }
  
    private String base64Encode(String data) {
      Blob inputBlob = Blob.valueOf(data);
      String base64EncodedData = EncodingUtil.base64Encode(inputBlob);
      return base64EncodedData;
    }
  }