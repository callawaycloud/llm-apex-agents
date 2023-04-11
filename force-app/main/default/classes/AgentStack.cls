//Written by GPT-4
public class AgentStack {
  public Agent.I[] agents = new List<Agent.I>{};

  // Push operation to add agent into the stack
  public void push(Agent.I agent) {
    agents.add(agent);
  }

  // Peek operation to get the top agent from the stack without removing it
  public Agent.I peek() {
    if (!agents.isEmpty()) {
      return agents[agents.size() - 1];
    } else {
      return null;
    }
  }

  // Pop operation to remove and return the top agent from the stack
  public Agent.I pop() {
    if (!agents.isEmpty()) {
      Agent.I topAgent = agents[agents.size() - 1];
      agents.remove(agents.size() - 1);
      return topAgent;
    } else {
      return null;
    }
  }
}
