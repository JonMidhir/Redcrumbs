class Player < ActiveRecord::Base
  has_many :victories, as: :high_scorer
end

class ComputerPlayer < ActiveRecord::Base
  has_many :victories, as: :high_scorer
end

class Game < ActiveRecord::Base
  redcrumbed only: [:name, :highscore], store: {only: [:id, :name]}

  belongs_to :high_scorer, polymorphic: true
  # belongs_to :creator, class_name: 'User'

  # For now just alias creator as target
  alias :creator :high_scorer
  alias :target :high_scorer
end