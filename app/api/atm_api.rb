class AtmAPI < Grape::API
  prefix :api
  version :v1
  format :json

  helpers do
    def load_atm!
      @atm = Atm.find_by_id(params[:id])

      error!({ message: I18n.t(:atm_is_missing) }, :not_found) if @atm.nil?
    end

    def validate_banknotes!(banknotes_hash)
      denominations = banknotes_hash.keys.map(&:to_i)

      invalid_denominations = denominations - AtmLogic::VALID_DENOMINATIONS
      if invalid_denominations.present?
        error!({ message: I18n.t(:invalid_denominations, values: invalid_denominations) }, :bad_request)
      end
    end

    def validate_total!(amount)
      if amount > @atm.total
        error!({ result: {}, message: I18n.t(:insufficient_funds) }, :bad_request)
      end
    end
  end

  resource :atms do
    params do
      requires :id, type: Integer, desc: 'ATM ID.'
    end

    route_param :id do
      before do
        load_atm!
      end

      desc 'Add banknotes to ATM.'
      params do
        requires :banknotes, type: Hash, desc: 'Banknotes data hash.', allow_blank: false
      end
      put :add_banknotes do
        validate_banknotes!(params[:banknotes])

        AtmLogic.new(@atm).add_banknotes(params[:banknotes])

        status :ok
        {
          message: I18n.t(:banknotes_added),
        }
      end

      desc 'Withdraw banknotes from ATM.'
      params do
        requires :amount, type: Integer, desc: 'Amount of money to withdraw.', values: AtmLogic::MIN_WITHDRAW..AtmLogic::MAX_WITHDRAW
      end
      get :withdraw_banknotes do
        validate_total!(params[:amount])

        atm_logic = AtmLogic.new(@atm)

        result = atm_logic.withdraw_banknotes(params[:amount])
        message = I18n.t(:banknotes_withdrawed)
        if result.empty?
          message = I18n.t(:denomination_error, available_denominations: atm_logic.available_denominations)
        end

        status :ok
        {
          result: result,
          message: message,
        }
      end
    end
  end
end
