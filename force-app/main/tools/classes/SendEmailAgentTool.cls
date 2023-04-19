//written by GPT-4
public class SendEmailAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Send an email notification to a list of email addresses';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{
      'subject' => 'email subject',
      'body' => 'html email body',
      'to' => 'comma seperated list of email addresses',
      'cc' => '(optional) comma seperated list of email addresses',
      'replyTo' => '(optional) email address'
    };
  }

  public string execute(Map<string, string> args) {
    if (
      !args.containsKey('subject') ||
      !args.containsKey('body') ||
      !args.containsKey('to')
    ) {
      throw new Agent.ActionRuntimeException('Missing required parameters.');
    }

    List<String> toAddresses = args.get('to').split(',');
    List<String> ccAddresses = new List<String>();
    if (args.containsKey('cc') && args.get('cc') != '') {
      ccAddresses = args.get('cc').split(',');
    }

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(toAddresses);
    mail.setCcAddresses(ccAddresses);
    mail.setSubject(args.get('subject'));
    mail.setHtmlBody(args.get('body'));

    if (args.containsKey('replyTo') && args.get('replyTo') != '') {
      mail.setReplyTo(args.get('replyTo'));
    }

    try {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ mail }
      );
      if (results[0].isSuccess()) {
        return 'Email sent successfully to ' +
          String.join(toAddresses, ', ') +
          '.';
      } else {
        throw new Agent.ActionRuntimeException(
          results[0].getErrors()[0].getMessage()
        );
      }
    } catch (Exception e) {
      throw new Agent.ActionRuntimeException(e.getMessage());
    }
  }
}
