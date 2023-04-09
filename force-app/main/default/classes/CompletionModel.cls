public class CompletionModel {
  public interface I {
    string complete(String prompt, String[] stopSequence);
  }
}
