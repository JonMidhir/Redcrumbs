class User < ActiveRecord::Base
  has_many :games, foreign_key: :creator_id, inverse_of: :creator
end

class Game < ActiveRecord::Base
  redcrumbed only: [:name, :highscore], store: {only: [:id, :name]}

  belongs_to :creator, class_name: 'User'

  # For now just alias creator as target
  alias :target :creator
end