class RemoteSm < ActiveRecord::Base
  attr_accessible :from, :message, :secret
  belongs_to :user
  
  #creates a to string method that is called for string interpolation (so its not an abstract number and we can log it)
  def to_s
    return "#{from}, #{message}, #{secret}"
  end
end
