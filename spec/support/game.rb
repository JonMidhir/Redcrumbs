class Game < ActiveRecord::Base
  redcrumbed only: [:name, :highscore], store: {only: [:id, :name]}

  belongs_to :creator, class_name: 'User'
end