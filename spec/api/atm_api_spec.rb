require 'rails_helper'

RSpec.describe AtmAPI, type: :request do
  context 'add_banknotes endpoint' do
    let(:atm) { create(:atm) }

    it 'returns an empty array of statuses' do
      put "/api/v1/atms/#{atm.id}/add_banknotes", params: {
        banknotes: { '1': 1, '2': 5, '50': 10, }
      }

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq []
    end
  end
end
