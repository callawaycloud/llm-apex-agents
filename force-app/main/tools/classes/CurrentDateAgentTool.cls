//Written by Charlie Jonas
// This tool isn't typically needed as you can just embed the current date in the prompt instructions
public class CurrentDateAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Returns the current date and time';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{};
  }

  public string execute(Map<string, string> args) {
    return JSON.serialize(Date.today());
  }
}
