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
      logger.info("\n \n!!!!!!!!!!!!!!!!!!!!!\n I sent: #{message} to phone #{to}\n!!!!!!!!!!!!!!!!!")
    end
  end
  
  def receivedSMS(sms)
    users = User.where('user_phone == ?', sms.from)
    if not users.any?
      sendSMS(sms.from, "You are an unkown users, fuck off")
    else
      users.each do |user|
        parsed = parseText(sms.message)
        case parsed[:type]
        when :saved
          handleSaved(user, parsed)
        else
          handleError(user, parsed)
        end
      end
    end
  end
  
  def handleError(user, parsed)
    sendSMS(user.user_phone,
            "Try sending 'purchase <price>' or 'saved <price>'")
  end
  
  def handleSaved(u, parsed)
    logger.info(u)
    u.dream_cost -= parsed[:value]
    u.save()
    sendTimeRemaining(u)
  end
  
  def sendTimeRemaining(u)
    if u.dream_cost <= 0
      sendSMS(u.user_phone,"You have saved enough to achieve your dream")
    elsif u.monthly_savings <= 0
      sendSMS(u.user_phone, "Without saving, you will not become closer to your dream")
    else
      time = (u.dream_cost / u.monthly_savings).ceil
      sendSMS(u.user_phone, "Your dream is #{time} months away")
    end
  end
  
  
  def parseText(message)
    res = {}
    m = /(\d+\.?\d*)/.match(message)
    if m
      res[:value] = m[1].to_f
    end
    
    res[:type] = case message
      when /saved/i
        :saved
      when /purchase/i
        :purchase
      when /status/i
        :status
      else
        :error
    end
    logger.info("I zsfgdh this #{res}")
    return res
  end
end
