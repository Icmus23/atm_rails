require 'rails_helper'

RSpec.describe AtmAPI, type: :request do
  let(:atm) { create(:atm, banknotes: { '5': 3, '10': 4, '25': 5, '50': 6 }) }

  context 'add_banknotes endpoint' do
    def request(params)
      put "/api/v1/atms/#{atm.id}/add_banknotes", params: params
    end

    it 'should return 404 status because of missing atm' do
      put "/api/v1/atms/0/add_banknotes", params: {
        banknotes: { '1': 1, '2': 5, '50': 10, }
      }

      expect(response).to be_not_found
      expect(JSON.parse(response.body)).to eql({ "message" => "Invalid ATM id", })
    end

    it 'should return 200 status and success message' do
      request({ banknotes: { '1': 1, '2': 2, '5': 3, '10': 4, '25': 5, '50': 6 } })

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eql({ "message" => "Banknotes added successfully", })

      atm.reload
      expect(atm.banknotes).to eql({"1"=>1, "2"=>2, "5"=>6, "10"=>8, "25"=>10, "50"=>12})
      expect(atm.total).to eql(965)
    end

    it 'should return 400 status and error message about invalid denomination 123' do
      request( {banknotes: { '123': 1, '50': 2 } })

      expect(response).to be_bad_request
      expect(JSON.parse(response.body)).to eql({ "message" => "Invalid denominations [123]", })

      atm.reload
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
      expect(atm.total).to eql(480)
    end
  end

  context 'withdraw_banknotes endpoint' do
    def request(params)
      put "/api/v1/atms/#{atm.id}/withdraw_banknotes", params: params
    end

    it 'should return 404 status because of missing atm' do
      put "/api/v1/atms/0/withdraw_banknotes", params: { banknotes: { '1': 1, '2': 5, '50': 10 } }

      expect(response).to be_not_found
      expect(JSON.parse(response.body)).to eql({ "message" => "Invalid ATM id", })
    end

    it 'should return 400 status and not change atm banknotes value' do
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})

      expect {
        request(amount: AtmLogic::MAX_WITHDRAW * 2)
      }.to change { atm.total }.by(0)

      expect(response).to be_bad_request
      expect(JSON.parse(response.body)).to eql({ "error" => "amount does not have a valid value" })
      atm.reload

      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
    end

    it 'should return 400 status if amount value is exceeded' do
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})

      expect {
        request(amount: AtmLogic::MAX_WITHDRAW)
      }.to change { atm.total }.by(0)

      expect(response).to be_bad_request
      expect(JSON.parse(response.body)).to eql({"message"=>"Withdrawal not possible, insufficient funds", "result"=>{}})
      atm.reload

      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
    end

    it 'should return 200 status and message that operation is not possible due to lack of specific banknotes' do
      expect {
        request(amount: 4)
      }.to change { atm.total }.by(0)

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eql(
        {
          "message"=>"Not enough banknotes with the required denomination. Available denominations are: [50, 25, 10, 5]",
          "result"=>{},
        }
      )

      atm.reload
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
    end

    it 'should return 200 status and success message with withdraw result' do
      expect(atm.total).to eql(480)

      request(amount: 100)

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eql({ "message" => "Banknotes withdrawed successfully", "result"=>{"50"=>2}})

      atm.reload
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>4})
      expect(atm.total).to eql(380)
    end

    it 'should return 200 status and success message with withdraw result' do
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
      expect(atm.total).to eql(480)

      request(amount: 145)

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eql(
        {
          "message" => "Banknotes withdrawed successfully",
          "result"=>{"10"=>2, "25"=>1, "50"=>2},
        }
      )

      atm.reload
      expect(atm.banknotes).to eql({"10"=>2, "25"=>4, "5"=>3, "50"=>4})
      expect(atm.total).to eql(335)
    end

    it 'should return 200 status and success message with withdraw result' do
      expect(atm.banknotes).to eql({"10"=>4, "25"=>5, "5"=>3, "50"=>6})
      expect(atm.total).to eql(480)

      request(amount: 475)

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eql(
        {
          "message" => "Banknotes withdrawed successfully",
          "result"=>{"10"=>4, "25"=>5, "5"=>2, "50"=>6},
        }
      )

      atm.reload
      expect(atm.banknotes).to eql({"10"=>0, "25"=>0, "5"=>1, "50"=>0})
      expect(atm.total).to eql(5)
    end
  end
end
