class CreateRemoteSms < ActiveRecord::Migration
  def change
    create_table :remote_sms do |t|
      t.string :from
      t.string :message
      t.string :secret

      t.timestamps
    end
  end
end
