class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :user_name
      t.string :user_phone
      t.string :dream
      t.decimal :dream_cost
      t.decimal :monthly_savings

      t.timestamps
    end
  end
end
