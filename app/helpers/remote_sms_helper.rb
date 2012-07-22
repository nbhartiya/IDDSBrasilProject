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
    if true
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
    #THIS IS THE SPOT TO TURN THE TRANSLATE TOGGLE ON AND OFF!
    translate = true
    users = User.where('user_phone == ?', sms.from)
    if not users.any?
      if translate == true
        sendSMS(sms.from, "Agora, voce nao e um usuario do sistema, se quiser, voce pode se cadastrar no nosso sistema atraves do numero +555181775601.") 
      else
        sendSMS(sms.from, "You are not currently in Pipa's system. To register, call +555181775601.")
      end
    else
      users.each do |user|
        logger.info(user)
        if translate==true
          parsed=parseTextPort(sms.message)
        else
          parsed=parseText(sms.message)
        end
        case parsed[:type]
        when :saved
          handleSaved(user, parsed, translate)
        when :purchase
          handlePurchase(user, parsed, translate)
        when :yes
          handlePurchaseMade(user, parsed, translate)
        when :no
          handlePurchaseNotMade(user, parsed, translate)
        when :status
          handleStatus(user, parsed, translate)
        when :updatesavings
          handleUpdateSavings(user, parsed, translate)
        when :dreamcost
          handleUpdateDreamCost(user, parsed, translate)
        when :calculate
          parsed2 = parseText2(sms.message)
          handleCalculation(user, parsed2, translate)
        when :monthlysavings
          handleUpdateMonthlySavings(user, parsed, translate)
        when :reminder
          handleReminder(user, parsed, translate)
        when :tip
          handleTip(user, parsed, translate)
        else
          handleError(user, parsed, translate)
        end
      end
    end
  end
  
  def handleError(user, parsed, translate)
    if translate==true
      sendSMS(user.user_phone,
            "O formato da mensagem enviada nao foi reconhecido. Por favor, consulte o guia de uso e tente novamente.")
    else
      sendSMS(user.user_phone,
            "This message is not in the right format, look at the user guide and try again.")
    end
  end
  
  def handlePurchase(u, parsed, translate)
    if u.monthly_savings <= parsed[:value]
      if translate=true
        sendSMS(u.user_phone, "Voce tera que reduzir outras compras para conseguir fazer esta compra.")
      else
        sendSMS(u.user_phone, "You will need to reduce your other purchases in order to make this purchase")
      end  
    else
      time = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
      newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings - parsed[:value], translate)
      difference = newtime - time
      if translate == true
        sendSMS(u.user_phone, "Beleza! Mas lembre que se voce comprar essa blusa vai economizar menos e por isso sua meta vou demorar mais #{newtime} meses. Sao #{difference} meses a mais!")
        sendSMS(u.user_phone, "Voce fez a compra? Se sim, quanta voce gastou? Responda 'Sim' e digite quanto gastou ou 'Nao gastei', se voce nao comprou.")
      else
        sendSMS(u.user_phone, "If you make this purchase, your dream will be #{newtime} months away. That is #{difference} more than before.")
        sendSMS(u.user_phone, "Did you buy it? If so, how much did you spend? If you bought, respond Yes and the amount you paid. Send No if you did not purchase.")
      end
    end
  end
  
  def handlePurchaseMade(u, parsed, translate)
    u.monthly_savings -= parsed[:value]
    newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
    if translate == true
      sendSMS(u.user_phone, "OK. Sua meta agora levara #{newtime} meses.")
    else
      sendSMS(u.user_phone, "Okay, your goal is now #{newtime} months away.")
    end
  end
  
  def handlePurchaseNotMade(u, parsed, translate)
    if translate == true
      sendSMS(u.user_phone, "Legal! Continue economizando e voce chegara la logo, logo!")
    else
      sendSMS(u.user_phone, "Good job! Keep saving and you will achieve your dream in no time!")
    end
  end
  
  def handleSaved(u, parsed, translate)
    logger.info(u)
    oldTime = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
    u.dream_cost -= parsed[:value]
    u.save()
    newTime = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
    timeDiff = oldTime - newTime
    if translate == true
      if u.monthly_savings < parsed[:value]
        sendSMS(u.user_phone,"Isso ai! Voce esta economizando mais! Isso quer dizer que sua meta sera alcancada em menos tempo! Agora so faltam #{newTime} meses! Menos #{timeDiff} mes da sua meta!")
      elsif u.monthly_savings > parsed[:value]
        sendSMS(u.user_phone, "Bom! Voce economizou R$ #{parsed[:value]}. Sua economia mensal e de R$ #{u.monthly_savings}. Continue assim mas tente economizar mais para alcancar sua meta mais rapido. Faltam #{newTime} meses para alcancar sua meta!")
      else
        sendSMS(u.user_phone,"Bom trabalho! Voce economizou o que queria! Continue assim e voce chegara la em #{newTime} meses!")
      end
    else
      if u.monthly_savings < parsed[:value]
        sendSMS(u.user_phone,"Great job! You are now saving more! This means your goal will be achieved in less time! Your goal is now about #{newTime} months away. That's #{timeDiff} months less than before.")
      elsif u.monthly_savings > parsed[:value]
        sendSMS(u.user_phone, "Okay. Good job, you saved R$ #{parsed[:value]}. Your monthly savings target is R$ #{u.monthly_savings}. Keep going and try to save monthly target and achieve your goal even faster. Your goal is now about #{newTime} months away.")
      else
        sendSMS(u.user_phone,"Good job. You saved what you said you could! Keep it up and achieve your goal in #{newTime} months.")
      end
    end
  end
  
  def handleStatus (u, parsed, translate)
    time= calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
    if translate == true
      sendSMS(u.user_phone, "E ai, #{u.user_name}! Bem vindo a Pipa! Sua meta e comprar #{u.dream} e voce precisa de R$ #{u.dream_cost} para alcancar sua meta. Agora, voce acha que pode economizar R$ #{u.monthly_savings} todos os meses. Baseado nos dados, sua meta pode ser alcancada em #{time} meses.")
    else
      sendSMS(u.user_phone, "What's up, #{u.user_name}! Welcome to Pipa! Your goal is to buy a #{u.dream} and you need R$ #{u.dream_cost} more to achieve your dream. Right now, you think you can save R$ #{u.monthly_savings} each month. Based on your current savings level, your dream will be achieved in #{time} months.")
    end
    
  end
  
  def handleUpdateSavings (u, parsed, translate)
    if u.monthly_savings <= parsed[:value]
      if translate == true
        sendSMS(u.user_phone, "Voce tem certeza que poderia ter feito esta compra?")
      else
        sendSMS(u.user_phone, "Are you sure you could have made that purchase?")
      end
    else
      u.monthly_savings -= parsed[:value]
      u.save()
      sendTimeRemaining(u, translate)
    end
  end
  
  def handleUpdateDreamCost (u, parsed, translate)
    u.dream_cost = parsed[:value]
    u.save()
    updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    if translate == true
      sendSMS(u.user_phone,"Custo da meta modificada. Agora sua meta vai ser atingida em #{updatedTime} meses.")
    else
      sendSMS(u.user_phone,"Okay! Your dream cost is updated. Right now, your goal will be achieved in #{updatedTime} months.")
    end
  end
  
  def handleUpdateMonthlySavings (u, parsed, translate)
    u.monthly_savings = parsed[:value]
    u.save()
    updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
    if translate == true
      sendSMS(u.user_phone,"Ok. Suo economia mensal foi modificado. Baseado nisso, sua meta vai ser atingida em #{updatedTime} meses.")
    else
      sendSMS(u.user_phone,"Okay! Your monthly savings estimate is upated. Right now, your dream will be achieved in #{updatedTime} months.")
    end
  end
  
  def handleCalculation (u, parsed2, translate)
    requiredSavings = parsed2.max/parsed2.min
    if translate == true
      sendSMS(u.user_phone, "Ok. Para fazer isso, voce precisara economizar R$ #{requiredSavings} todo mes.")
    else
      sendSMS(u.user_phone, "Okay! To do this, you'll need to save about R$ #{requiredSavings} each month")
    end
  end
  
  def handleReminder (u, parsed, translate)
    if translate == true
      sendSMS(u.user_phone, "Ja tem um mes desde sua ultima economia!Sua economia mensal e de R$ #{u.monthly_savings}. Gostaria de economizar mais dinheiro? Se voce ja fez, envie uma mensagem de texto com 'Economizado' e quando vc economizou.")
    else
      sendSMS(u.user_phone, "It has been a month since you last saved. Your monthly savings target is R$ #{u.monthly_savings}. Would you like to save more money? If you do, send a text message with 'Saved' and the amount you saved.")
    end
  end
  
  def handleTip (u, parsed, translate)
    if translate == true
      #CONVERT TO PORTUGUESE
      sendSMS(u.user_phone, "Voce sabia que voce pode saber mais sobre Conta Bancaria, Economia ou Cartao de Credito discando +555181775601.")
    else
      sendSMS(u.user_phone, "Did you know that you can find out more about Bank Accounts, Savings, or Credit Cards by calling NUMBER?")
    end
  end
  
  def calcTimeToFinish(total, monthly, translate)
    return (total / monthly).ceil
  end
  
  def sendTimeRemaining(u, translate)
    if translate == true
      #CONVERT TO PORTUGUESE
      if u.dream_cost <= 0
        sendSMS(u.user_phone,"Voce economizou o suficiente para atingir sua meta.")
      elsif u.monthly_savings <= 0
        sendSMS(u.user_phone, "Sem economizar voce nao chegara perto de atingir a sua meta.")
      else
        time = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
        sendSMS(u.user_phone, "Sua meta vai ser atingida em #{time} meses.")
      end
    else
      if u.dream_cost <= 0
        sendSMS(u.user_phone,"You have saved enough to achieve your dream")
      elsif u.monthly_savings <= 0
        sendSMS(u.user_phone, "Without saving, you will not become closer to your dream")
      else
        time = calcTimeToFinish(u.dream_cost, u.monthly_savings, translate)
        sendSMS(u.user_phone, "Your dream is now #{time} months away")
      end
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
        :yes
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
  
  def parseTextPort(message)
    res = {}
    m = /(\d+\.?\d*)/.match(message)
    if m
      res[:value] = m[1].to_f
    end
    
    res[:type] = case message
      when /economizei/i
        :saved
      when /comprar/i
        :purchase
      when /status/i
        :status
      when /sim/i
        :updatesavings
      when /ModificaMeta/i
        :dreamcost
      when /minhaeconomia/i
        :monthlysavings
      when /calcular/i
        :calculate
      when /nao/i
        :no
      when /aviso/i
        :reminder
      when /dica/i
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
