module RemoteSmsHelper
  
  require 'twilio-ruby' #Get this to use the Twilio Gem
  
  def sendSMS (to, message)
    if false
      account_sid = 'AC2894091dd9e7a5b3aab955007ba8ad7a'
      auth_token = '83f1ad3c2360f21d1e02d68b7c0009b9'
      logger.info("#{account_sid}, #{auth_token}")
      client = Twilio::REST::Client.new(account_sid, auth_token)
      client.account.sms.messages.create(:from => '+12133443930', :to => to, :body => message)
    else
      logger.info("\n \n!!!!!!!!!!!!!!!!!!!!!\n I sent: #{to}, #{message}\n!!!!!!!!!!!!!!!!!")
    end
  end
end
