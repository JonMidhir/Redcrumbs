ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :computer_players, :force => true do |t|
      t.string :name
      t.timestamps
    end

    create_table :players, :force => true do |t|
      t.string :name
      t.timestamps
    end

    create_table :games, :force => true do |t|
      t.references :high_scorer, :polymorphic => true
      t.string :name
      t.string :platform
      t.integer :highscore
      t.timestamps
    end
  end
end