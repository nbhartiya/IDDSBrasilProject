class CreateRemoteSms < ActiveRecord::Migration
  def change
    create_table :remote_sms do |t|
      t.integer :user_id
      t.string :from
      t.string :message
      t.string :secret

      t.timestamps
    end
    add_index :remote_sms, :user_id
  end
end
