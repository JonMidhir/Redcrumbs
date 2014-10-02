ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => File.expand_path('../../test.db', __FILE__)
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :name
      t.timestamps
    end

    create_table :venues, :force => true do |t|
      t.string :name
      t.string :city
      t.timestamps
    end
  end
end