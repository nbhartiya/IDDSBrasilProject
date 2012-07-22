module RemoteSmsHelper
  
  require 'twilio-ruby' #Get this to use the Twilio Gem
  
  #Sends SMS
  def sendSMS (to, message)
    # Checks if the phone number is in the right format.
    # If not, it makes it into the right format for Twilio.
    if to[1]=='5'
      logger.info(to[1])
      logger.info("true")
      to_corrected=to
    else
      to_corrected='+55'+to.slice(1..-1)
    end
    # Prints the phone number it is texting
    logger.info("To #{to}")
    
    # Only sends text through Twilio if the below line is changed to "true"
    if false
      #MATTS ACCOUNT
      account_sid = 'AC2894091dd9e7a5b3aab955007ba8ad7a'
      auth_token = '83f1ad3c2360f21d1e02d68b7c0009b9'
      logger.info("#{account_sid}, #{auth_token}")
      logger.info("To#{to}")
      client = Twilio::REST::Client.new(account_sid, auth_token)
      client.account.sms.messages.create(:from => '+12133443930', :to => to_corrected, :body => message)
    else
      # Prints the text that WOULD be sent to console
      logger.info("To #{to_corrected}")
      logger.info("\n \n!!!!!!!!!!!!!!!!!!!!!\n I sent: #{message} to phone #{to_corrected}\n!!!!!!!!!!!!!!!!!")
    end
  end
  
  def receivedSMS(sms)
    users = User.where('user_phone == ?', sms.from)
    if not users.any?
      #sendSMS(sms.from, "Agora, voce nao e um usuario do sistema, se quiser, voce pode se cadastrar no nosso sistema atraves do numero________.") 
      sendSMS(sms.from, "You are not currently in Pipa's system. To register, call NUMBER.")
    else
      users.each do |user|
        logger.info(user)
        parsed = parseText(sms.message)
        case parsed[:type]
        when :saved
          handleSaved(user, parsed)
        when :purchase
          handlePurchase(user, parsed)
        when :yes
          handlePurchaseMade(user, parsed)
        when :no
          handlePurchaseNotMade(user, parsed)
        when :status
          handleStatus(user, parsed)
        when :updatesavings
          handleUpdateSavings(user, parsed)
        when :dreamcost
          handleUpdateDreamCost(user, parsed)
        when :calculate
          parsed2 = parseText2(sms.message)
          handleCalculation(user, parsed2)
        when :monthlysavings
          handleUpdateMonthlySavings(user, parsed)
        when :reminder
          handleReminder(user, parsed)
        when :tip
          handleTip(user, parsed)
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
  
  def handlePurchase(u, parsed)
    if u.monthly_savings <= parsed[:value]
      sendSMS(u.user_phone, "You will need to reduce your other purchases in order to make this purchase")
    else
      time = calcTimeToFinish(u.dream_cost, u.monthly_savings)
      newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings - parsed[:value])
      difference = newtime - time
      sendSMS(u.user_phone, "If you make this purchase, your dream will be #{newtime} months away. That is #{difference} more than before.")
      sendSMS(u.user_phone, "Did you buy it? If so, how much did you spend? If you bought, respond Yes and the amount you paid. Send No if you did not purchase.")
    end
  end
  
  def handlePurchaseMade(u, parsed)
    u.monthly_savings -= parsed[:value]
    newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    sendSMS(u.user_phone, "Okay, your goal is now #{newtime} months away.")
  end
  
  def handlePurchaseNotMade(u, parsed)
    sendSMS(u.user_phone, "Good job! Keep saving and you will achieve your dream in no time!")
  end
  
  def handleSaved(u, parsed)
    logger.info(u)
    oldTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    u.dream_cost -= parsed[:value]
    u.save()
    newTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    timeDiff = oldTime - newTime
    if u.monthly_savings < parsed[:value]
      sendSMS(u.user_phone,"Great job! You are now saving more! This means your goal will be achieved in less time! Your goal is now about #{newTime} months away. That's #{timeDiff} months less than before.")
    elsif u.monthly_savings > parsed[:value]
      sendSMS(u.user_phone, "Okay. Good job, you saved R$ #{parsed[:value]}. Your monthly savings target is R$ #{u.monthly_savings}. Keep going and try to save monthly target and achieve your goal even faster. Your goal is now about #{newTime} months away.")
    else
      sendSMS(u.user_phone,"Good job. You saved what you said you could! Keep it up and achieve your goal in #{newTime} months.")
    end
  end
  
  def handleStatus (u, parsed)
    time= calcTimeToFinish(u.dream_cost, u.monthly_savings)
    sendSMS(u.user_phone, "What's up, #{u.user_name}! Welcome to Pipa! Your goal is to buy a #{u.dream}. You need R$ #{u.dream_cost} more to achieve your dream. Right now, you think you can save R$ #{u.monthly_savings} each month. Based on your current savings level, your dream will be achieved in #{time} months.")
    #sendSMS(u.user_phone, "E ai, #{u.user_name}! Bem vindo a Pipa! Sua meta e comprar #{u.dream}. Agora, voce precisa de R$ #{u.dream_cost} para alcancar sua meta. Baseado nos dados, sua meta pode ser alcancada em #{time} meses.")
  end
  
  def handleUpdateSavings (u, parsed)
    if u.monthly_savings <= parsed[:value]
      sendSMS(u.user_phone, "are you sure you could have made that purchase?")
    else
      u.monthly_savings -= parsed[:value]
      u.save()
      sendTimeRemaining(u)
    end
  end
  
  def handleUpdateDreamCost (u, parsed)
    u.dream_cost = parsed[:value]
    u.save()
    updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    sendSMS(u.user_phone,"Okay! Your dream cost is updated. Right now, your dream will be achieved in #{updatedTime} months.")
  end
  
  def handleUpdateMonthlySavings (u, parsed)
    u.monthly_savings = parsed[:value]
    u.save()
    updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    sendSMS(u.user_phone,"Okay! Your monthly savings estimate is upated. Right now, your dream will be achieved in #{updatedTime} months.")
  end
  
  def handleCalculation (u, parsed2)
    requiredSavings = parsed2.max/parsed2.min
    sendSMS(u.user_phone, "Okay! To do this, you'll need to save about R$ #{requiredSavings} each month")
  end
  
  def handleReminder (u, parsed)
    sendSMS(u.user_phone, "It has been a month since you last saved. Your monthly savings target is R$ #{u.monthly_savings}. Would you like to save more money? If you do, send a text message with 'Saved' and the amount you saved.")
  end
  
  def handleTip (u, parsed)
    sendSMS(u.user_phone, "Did you know that you can find out more about Bank Accounts, Savings, or Credit Cards by calling NUMBER?")
  end
  
  def calcTimeToFinish(total, monthly)
    return (total / monthly).ceil
  end
  
  def sendTimeRemaining(u)
    if u.dream_cost <= 0
      sendSMS(u.user_phone,"You have saved enough to achieve your dream")
    elsif u.monthly_savings <= 0
      sendSMS(u.user_phone, "Without saving, you will not become closer to your dream")
    else
      time = calcTimeToFinish(u.dream_cost, u.monthly_savings)
      sendSMS(u.user_phone, "Your dream is now #{time} months away")
    end
    #!!!return [u.time, ]
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
      when /yes/i
        :updatesavings
      when /DreamCost/i
        :dreamcost
      when /monthlysavings/i
        :monthlysavings
      when /calculate/i
        :calculate
      when /no/i
        :no
      when /reminder/i
        :reminder
      when /tip/i
        :tip
      else
        :error
    end
    logger.info("I received this #{res}")
    return res
  end
  
  def parseText2(message)
    res = []
    m = message.scan(/\d+/)
    logger.info("First part is #{m[0]}")
    logger.info("Second part is #{m[1]}")
    logger.info(m)

    if m
      res[0] = m[0].to_f
      res[1] = m[1].to_f
    end
    
    logger.info("I see this #{res}")
    return res
  end
end