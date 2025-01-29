class CreateUnuRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :unu_requests do |t|
      t.string :method
      t.string :path
      t.string :remote_ip
      t.text :headers
      t.text :body

      t.timestamps
    end
  end
end
