module RemoteSmsHelper
  
  #Things to think about:
  #1. How to deal with people not sending texts after the demo...
  #2. Could the translate thing be better?
  #3. Wish i could test it without having people send me messages over and over..
  #4. How to look at a list of texts associated with each user...
  
  require 'twilio-ruby' #Get this to use the Twilio Gem
  load 'my_constants.rb'
  
  #Sends SMS
  def sendSMS (to, message)
    # Checks if the phone number is in the right format.
    # If not, it makes it into the right format for Twilio.
    if to[1]=='5'
      logger.info(to[1])
      logger.info("true")
      to_corrected=to
    elsif to[1]=='1'
      to_corrected='+55'+to.slice(1..-1)
    else
      to_corrected='+5511'+to.slice
    end
    # Prints the phone number it is texting
    logger.info("To #{to} at this time")
    
    # Only sends text through Twilio if the below line is changed to "true"
    if false
      #MATTS ACCOUNT
      account_sid = 'AC2894091dd9e7a5b3aab955007ba8ad7a'
      auth_token = '83f1ad3c2360f21d1e02d68b7c0009b9'
      logger.info("#{account_sid}, #{auth_token}")
      logger.info("To#{to}")
      logger.info("\n \n?????????????????\n I sent: #{message} to phone #{to_corrected}\n????????????????")
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
      if $translate == 'true'
        sendSMS(sms.from, "Voce nao esta cadastrado no Projeto Pipa. Se quiser se cadastrar, envie uma mensagem com o texto 'cadastro' para #{$Pipa_number}.") 
      else
        sendSMS(sms.from, "You are not currently in Pipa's system. To register, call +555181775601.")
      end
      #WORKING :-)
      u = User.new(:dream => "COMING", :dream_cost => "0", :monthly_savings => "1", :user_name => "NOME", :user_phone => sms.from)
      u.save()
    else
      users.each do |user|
        logger.info(user)
        if $translate=='true'
          parsed=parseTextPort(sms.message)
        else
          parsed=parseText(sms.message)
        end
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
        when :dream
          parsedname = parseName(sms.message)
          handleDream(user, parsedname, parsed)
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
        when :nome
          parsedName = parseName(sms.message)
          handlename(user, parsedName, parsed)
        when :billreminder
          handleBillReminder(user, parsed)
        when :bill2
          parsedName = parseName(sms.message)
          handleBill2(user, parsedName, parsed)
        #when :signup
        #  handleSignup(user, parsed)
        #when :name
        #  handleName(user, parsed)
        #when :dream
        #  handleDream(user,parsed)
        else
          handleError(user, parsed)
        end
      end
    end
  end
  
  def handlesignup(u, parsedname, parsed)
    sendSMS(u.user_phone, "Obrigado! Agora envie uma mensagem com o texto 'nome' seguido de seu nome para #{$Pipa_number}.")
  end
  
  def handlename(u, parsedname, parsed)
    thing=parsed[:type].to_sym
    hash_upper = Hash[parsedname.map.with_index{|*ki| ki}]    # => {"a"=>0, "b"=>1, "c"=>2}
    hash_lower = {}
    hash_upper.each_pair do |k,v|
      hash_lower.merge!({k.downcase => v})
    end
    name = hash_lower['nome'] # => 1
    u.user_name = parsedname [name + 1]
    u.save()
    sendSMS(u.user_phone, "Obrigado mais uma vez! Agora envie uma mensagem com o texto eu 'quero' e em seguida escreva sua meta e envie para #{$Pipa_number}.")
  end
  
  # **OLDER WAY OF DOING IT**
  #def handlename(u, parsedname, parsed)
  #  thing=parsed[:type].to_sym
  #  hash = Hash[parsedname.map.with_index{|*ki| ki}]    # => {"a"=>0, "b"=>1, "c"=>2}
  #  #logger.info("UGH #{hash}")
  #  name=hash['Nome'] # => 1
  #  logger.info("WHAT IS WRONG WITH THIS #{name}")
  #  u.user_name=parsedname[name + 1]
  #  dream=hash['quero']
  #  u.dream = parsedname[dream+1]
  #  dreamcost=hash['preco']
  #  u.dream_cost = parsedname[dreamcost+1]
  #  monthlysav=hash['minhaeconomia']
  #  u.monthly_savings=parsedname[monthlysav+1]
  #  u.save()
  #  time= calcTimeToFinish(u.dream_cost, u.monthly_savings)
  #  logger.info("THIS IS WHERE THE PROBLEM IS #{u.user_phone}")
  #  logger.info("Bem vindo ao Pipa, #{u.user_name}! Faltam R$ #{u.dream_cost.round} para voce comprar seu #{u.dream}. Economize #{u.monthly_savings.round} por mes e conseguira comprar seu #{u.dream} em #{time} meses.")
  #  sendSMS(u.user_phone, "Bem vindo ao Pipa, #{u.user_name}! Faltam R$ #{u.dream_cost.round} para voce comprar seu #{u.dream}. Economize #{u.monthly_savings.round} por mes e conseguira comprar seu #{u.dream} em #{time} meses.")
  #  #else
  #  #  sendSMS(u.user_phone, "Welcome to Pipa, #{u.user_name}! You are R$ #{u.dream_cost.round} away from buying your #{u.dream}. Save #{u.monthly_savings.round} each month and you'll be able to buy your #{u.dream} in #{time} months.")
  #  #end
  #end

  def handleDream (u, parsedname, parsed)
    thing=parsed[:type].to_sym
    hash_upper = Hash[parsedname.map.with_index{|*ki| ki}]    # => {"a"=>0, "b"=>1, "c"=>2}
    hash_lower = {}
    hash_upper.each_pair do |k,v|
      hash_lower.merge!({k.downcase => v})
    end
    want = hash_lower['quero'] # => 1
    u.dream = parsedname [want + 1]
    u.save()
    sendSMS(u.user_phone, "Ae!! Estamos quase terminando. Por favor, envie uma mensagem com o texto 'custo' seguido do preco da sua meta para #{$Pipa_number}.")
  end
  
  def handleUpdateDreamCost (u, parsed)
    u.dream_cost = parsed[:value]
    u.save()
    #updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    if $translate == 'true'
      sendSMS(u.user_phone,"Ufa!! Para terminar, envie uma mensagem com o texto 'minhaeconomia' seguido do valor que deseja economizar por mes para #{$Pipa_number} e prepare-se para economizar!")
    else
      #NEED TO FIX THIS TO MATCH PORTUGUESE VERSION
      #sendSMS(u.user_phone,"Okay! Your dream cost is updated. Right now, your goal will be achieved in #{updatedTime} months.")
    end
  end
  
  def handleUpdateMonthlySavings (u, parsed)
    u.monthly_savings = parsed[:value]
    u.save()
    updatedTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    if $translate == 'true'
      sendSMS(u.user_phone,"Sim. Sua economia mensal mudou. Portanto, voce vai conseguir o que queria em #{updatedTime} meses.")
    else
      sendSMS(u.user_phone,"Okay! Your monthly savings estimate is upated. Right now, your dream will be achieved in #{updatedTime} months.")
    end
  end
  
  def handleBill2(u, parsedname, parsed)
    thing = parsed[:type].to_sym
    hash = Hash[parsedname.map.with_index{|*ki| ki}]    # => {"a"=>0, "b"=>1, "c"=>2}
    pagar = hash['Pagar'] # => 1
    billFor = parsedname[pagar + 1]
    monthlycost = parsedname[pagar + 2]
    dia = hash['dia']
    day = parsedname[dia + 1]
    meses = hash ['meses']
    length = parsedname[meses-1]
    #logger.info("Nao se esqueca que a parcela das #{billFor} vence em dois dias! Nos vamos continuar te lembrando por mais #{length} meses ate as parcelas acabem.")
    sendSMS(u.user_phone, "Nao se esqueca que a parcela de #{billFor} vence em dois dias! Nos vamos continuar avisando por mais #{length} meses ate que as parcelas acabem.")
  end
  
  def handleError(user, parsed)
    if $translate=='true'
      sendSMS(user.user_phone,
            "A mensagem nao foi enviada corretamente. Por favor, leia o guia de uso e tente novamente.")
    else
      sendSMS(user.user_phone,
            "This message is not in the right format, look at the user guide and try again.")
    end
  end
  
  def handlePurchase(u, parsed)
    if u.monthly_savings <= parsed[:value]
      if $translate='true'
        sendSMS(u.user_phone, "Desculpe, mas voce tera que reduzir outras compras para conseguir fazer esta compra.")
      else
        sendSMS(u.user_phone, "You will need to reduce your other purchases in order to make this purchase")
      end  
    else
      time = calcTimeToFinish(u.dream_cost, u.monthly_savings)
      newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings - parsed[:value])
      difference = newtime - time
      if $translate == 'true'
        sendSMS(u.user_phone, "Beleza! Mas lembre que se voce comprar isso vai economizar menos e por isso sua meta vai demorar mais #{newtime} meses. Sao #{difference} meses a mais!")
        sendSMS(u.user_phone, "Voce fez a compra? Se sim, quanto voce gastou? Responda 'Sim' e digite quanto gastou ou 'Nao' gastei, se voce nao comprou.")
      else
        sendSMS(u.user_phone, "If you make this purchase, your dream will be #{newtime} months away. That is #{difference} more than before.")
        sendSMS(u.user_phone, "Did you buy it? If so, how much did you spend? If you bought, respond Yes and the amount you paid. Send No if you did not purchase.")
      end
    end
  end
  
  def handlePurchaseMade(u, parsed)
    u.monthly_savings -= parsed[:value]
    newtime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    if $translate == 'true'
      sendSMS(u.user_phone, "OK. Mas voce demorara #{newtime} meses para conseguir comprar o que voce quer comprar.")
    else
      sendSMS(u.user_phone, "Okay, but it will take you #{newtime} to buy what you want to buy.")
    end
  end
  
  def handlePurchaseNotMade(u, parsed)
    if $translate == 'true'
      sendSMS(u.user_phone, "Legal! Continue economizando e voce chegara la logo, logo!")
    else
      sendSMS(u.user_phone, "Good job! Keep saving and you will achieve your dream in no time!")
    end
  end
  
  def handleBillReminder(u, parsed)
    if $translate == 'true'
      sendSMS(u.user_phone, "Nao se esqueca que a parcela das Casas Bahia vence em dois dias!")
    else
      sendSMS(u.user_phone, "Don't forget your Casas Bahia bill is due in two days.")
    end
  end
  
  def handleSaved(u, parsed)
    logger.info(u)
    oldTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    u.dream_cost -= parsed[:value]
    u.save()
    newTime = calcTimeToFinish(u.dream_cost, u.monthly_savings)
    timeDiff = (oldTime - newTime)
    if $translate == 'true'
      if u.monthly_savings < parsed[:value]
        sendSMS(u.user_phone,"Isso ae! Voce esta economizando mais! Isso quer dizer que voce vai comprar o que quer em menos tempo! Agora so faltam #{newTime} meses!")
      elsif u.monthly_savings > parsed[:value]
        sendSMS(u.user_phone, "Bom! Economizou R$#{parsed[:value].round}! Sua economia mensal e de R$#{u.monthly_savings.round}. Continue assim, mas tente economizar mais pois ainda faltam #{newTime} meses para conseguir o que quer.")
      else
        sendSMS(u.user_phone,"Bom trabalho! Voce economizou o que queria! Continue assim e voce chegara la em #{newTime} meses!")
      end
    else
      if u.monthly_savings < parsed[:value]
        sendSMS(u.user_phone,"Great job! You are now saving more! This means your goal will be achieved in less time! Your goal is now about #{newTime} months away. That's #{timeDiff} months less than before.")
      elsif u.monthly_savings > parsed[:value]
        sendSMS(u.user_phone, "Okay. Good job, you saved R$ #{parsed[:value].round}. Your monthly savings target is R$ #{u.monthly_savings.round}. Your goal is now about #{newTime} months away.")
      else
        sendSMS(u.user_phone,"Good job. You saved what you said you could! Keep it up and achieve your goal in #{newTime} months.")
      end
    end
  end
  
  def handleStatus (u, parsed)
    time= calcTimeToFinish(u.dream_cost, u.monthly_savings)
    if $translate == 'true'
      sendSMS(u.user_phone, "Bem vindo ao Pipa, #{u.user_name}! Faltam R$ #{u.dream_cost.round} para voce comprar #{u.dream}. Economize #{u.monthly_savings.round} por mes e conseguira comprar #{u.dream} em #{time} meses.")
    else
      sendSMS(u.user_phone, "Welcome to Pipa, #{u.user_name}! You are R$ #{u.dream_cost.round} away from buying your #{u.dream}. Save #{u.monthly_savings.round} each month and you'll be able to buy your #{u.dream} in #{time} months.")
    end
    
  end
  
  # BELOW CODE NOT USED
  #def handleUpdateSavings (u, parsed)
  #  if u.monthly_savings <= parsed[:value]
  #    if $translate == 'true'
  #      sendSMS(u.user_phone, "Voce tem certeza que poderia ter feito esta compra?")
  #    else
  #      sendSMS(u.user_phone, "Are you sure you could have made that purchase?")
  #    end
  #  else
  #    u.monthly_savings -= parsed[:value]
  #    u.save()
  #    sendTimeRemaining(u)
  #  end
  #end
  
  
  
  def handleCalculation (u, parsed2)
    requiredSavings = parsed2.max/parsed2.min
    if $translate == 'true'
      sendSMS(u.user_phone, "Ok. Para fazer isso, voce precisara economizar R$ #{requiredSavings.round} todo mes.")
    else
      sendSMS(u.user_phone, "Okay! To do this, you'll need to save about R$ #{requiredSavings.round} each month")
    end
  end
  
  def handleReminder (u, parsed)
    if $translate == 'true'
      sendSMS(u.user_phone, "Ei! Faz um mes desde sua ultima economia e disse que salvaria #{u.monthly_savings.round} por mes.Pode economizar agora?Envie uma mensagem com 'Economia' e quanto economizou.")
    else
      sendSMS(u.user_phone, "It has been a month since you last saved. Your monthly savings target is R$ #{u.monthly_savings}. Would you like to save more money? If you do, send a text message with 'Saved' and the amount you saved.")
    end
  end
  
  def handleTip (u, parsed)
    if $translate == 'true'
      sendSMS(u.user_phone, "Voce sabia que voce pode saber mais sobre Conta Bancaria, Economia ou Cartao de Credito discando #{$Pipa_number}.")
    else
      sendSMS(u.user_phone, "Did you know that you can find out more about Bank Accounts, Savings, or Credit Cards by calling NUMBER?")
    end
  end
  
  def calcTimeToFinish(total, monthly)
    return (total / monthly).ceil
  end
  
  def sendTimeRemaining(u)
    if $translate == 'true'
      if u.dream_cost <= 0
        sendSMS(u.user_phone,"Voce economizou o suficiente para conseguir o que voce quer.")
      elsif u.monthly_savings <= 0
        sendSMS(u.user_phone, "Sem economizar voce nao chegara perto de conseguir o que voce quer.")
      else
        time = calcTimeToFinish(u.dream_cost, u.monthly_savings)
        sendSMS(u.user_phone, "Voce vai conseguir o que voce quer em #{time} meses.")
      end
    else
      if u.dream_cost <= 0
        sendSMS(u.user_phone,"You have saved enough to achieve your dream")
      elsif u.monthly_savings <= 0
        sendSMS(u.user_phone, "Without saving, you will not become closer to your dream")
      else
        time = calcTimeToFinish(u.dream_cost, u.monthly_savings)
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
        :yes
      when /MudouPreco/i
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
      when /cadastro/i
        :signup
      when /nome/i
        :nome
      when /quero/i
        :dream
      when /custo/i
        :dreamcost
      when /conta/i
        :billreminder
      when /pagar/i
        :bill2
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
  
  def parseName(message)
    res = message.split(' ')
    logger.info("First part is #{res[0]}")
    logger.info("Second part is #{res[1]}")
    logger.info(res)
    
    logger.info("I see this #{res}")
    
    return res
  end
end
