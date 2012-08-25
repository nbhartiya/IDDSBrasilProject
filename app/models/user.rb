class User < ActiveRecord::Base
  attr_accessible :dream, :dream_cost, :monthly_savings, :user_name, :user_phone
  has_many :remote_sms
  
  validates_uniqueness_of :user_phone
  def to_s
    return "Name: #{user_name}\nPhone: #{user_phone}\n#{dream}: #{dream_cost}\nSaving Rate: #{monthly_savings}"
  end
end
