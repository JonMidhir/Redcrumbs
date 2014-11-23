class Player < ActiveRecord::Base
  has_many :victories, as: :high_scorer
end

class ComputerPlayer < ActiveRecord::Base
  has_many :victories, as: :high_scorer
end

class Game < ActiveRecord::Base
  redcrumbed only: [:name, :highscore], store: {only: [:id, :name]}

  belongs_to :high_scorer, polymorphic: true

  alias :creator :high_scorer

  # Target is whoever is being dispossessed of the top spot
  #
  def target
    high_scorer_was if high_scorer_changed?
  end

  private

  def high_scorer_changed?
    high_scorer_id_was != high_scorer_id or 
    high_scorer_type_was != high_scorer_type
  end

  def high_scorer_was
    if high_scorer_id_was.present? and high_scorer_type_was.present?
      high_scorer_type_was.constantize.find(high_scorer_id_was)
    end
  end
end