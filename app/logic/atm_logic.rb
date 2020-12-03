class AtmLogic
  VALID_DENOMINATIONS = [50, 25, 10, 5, 2, 1]
  MIN_WITHDRAW = 1
  MAX_WITHDRAW = 1000

  def initialize(atm)
    @atm = atm
  end

  def add_banknotes(new_banknotes)
    current_banknotes = @atm.banknotes
    new_banknotes.each do |k, v|
      current_banknotes[k] ||= 0
      current_banknotes[k] = current_banknotes[k].to_i + v.to_i
    end

    @atm.update(banknotes: current_banknotes, total: get_total)
  end

  def withdraw_banknotes(value)
    withdrawal = calculate_withdrawal(value)

    current_banknotes = @atm.banknotes
    withdrawal.each do |k, v|
      current_banknotes[k] = current_banknotes[k].to_i - v
    end

    if @atm.update(banknotes: current_banknotes, total: get_total)
      return withdrawal
    end

    # Return empty hash if we can not process withdrawal or withdrawal operation failed during save.
    {}
  end

  # Return a hash of denominations and counts of cash for the value withdraw.
  def calculate_withdrawal(value)
    result = {}
    current_banknotes = @atm.banknotes
    current_value = value

    # Iterate over DESC sorted array of available denominations.
    available_denominations.each do |denomination|
      # Skip step if the value is smaller then current denomination.
      next if denomination.to_i > current_value

      current_banknotes_cnt = current_banknotes[denomination.to_s] || 0
      wanted_banknotes_cnt = current_value / denomination

      # If we need more banknotes than we have - take all we have and reduce current_value
      # for the amount of money we took.
      if wanted_banknotes_cnt > current_banknotes_cnt
        result[denomination.to_s] = current_banknotes_cnt
        current_value -= current_banknotes_cnt * denomination
      # If we have enough banknotes took them and start to process the reminder part of current_value.
      else
        result[denomination.to_s] = wanted_banknotes_cnt
        current_value %= denomination
      end

      # Stop loop if we already have needed sum.
      break if current_value.zero?
    end

    # This means that we do not have available banknotes to make withdraw. For example, user wants to
    # withdraw { 10: 1 }, but we have { 50: 2 }.
    return {} if current_value > 0

    result
  end

  # Returns available banknotes denominations in the ATM as integer values array in DESC order.
  def available_denominations
    denominations = []
    @atm.banknotes.each do |k, v|
      if v.to_i > 0
        denominations << k.to_i
      end
    end

    denominations.sort_by { |v| -v }
  end

  # Returns the total amount of money in the ATM.
  def get_total
    @atm.banknotes.map { |k, v| k.to_i * v.to_i }.sum
  end
end
