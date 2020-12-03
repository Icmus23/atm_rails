class Atm < ApplicationRecord
  before_save :update_total

  private

  def update_total
    self.total = AtmLogic.new(self).get_total
  end
end
