class User < ActiveRecord::Base
  attr_accessible :dream, :dream_cost, :user_name, :user_phone
end
