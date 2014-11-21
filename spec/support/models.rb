class User < ActiveRecord::Base
end

class Game < ActiveRecord::Base
  redcrumbed only: [:name, :highscore], store: {only: [:id, :name]}

  belongs_to :creator, class_name: 'User'

  # For now just alias creator as target
  alias :target :creator
end