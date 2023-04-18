//Written by Charlie Jonas
// This tool isn't typically needed as you can just embed the current date in the prompt instructions
public class GetCurrentUserAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Gets id, name & email for the user you are interacting with';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{};
  }

  public string execute(Map<string, string> args) {
    UserInfoData info = new UserInfoData();
    info.id = UserInfo.getUserId();
    info.userName = UserInfo.getUserName();
    info.email = UserInfo.getUserEmail();
    info.firstName = userInfo.getFirstName();
    info.lastName = userInfo.getLastName();
    return JSON.serialize(info);
  }

  public class UserInfoData {
    public string id;
    public string userName;
    public string firstName;
    public string lastName;
    public string email;
  }
}
