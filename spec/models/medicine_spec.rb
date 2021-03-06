require 'rails_helper'

RSpec.describe Medicine, type: :model do
  it 'can be created with the proper attributes' do
    allow_any_instance_of(Medicine).to receive(:init) { '' }
    Medicine.create!(set_id: '123456789', name: 'Advil', active_ingredient: 'ibuprofen')

    expect(Medicine.first.set_id).to eq('123456789')
    expect(Medicine.first.name).to eq('Advil')
    expect(Medicine.first.active_ingredient).to eq('ibuprofen')
  end

  it 'will not be created and throw an error if values are nil' do
    allow_any_instance_of(Medicine).to receive(:init) { '' }
    expect { Medicine.create!(set_id: nil, name: nil, active_ingredient: nil) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  describe 'init' do
    it 'should set the result of several OpenFda Client queries to attribute accessors' do
      allow_any_instance_of(OpenFda::Client).to receive(:query_by_set_id) { '' }
      allow_any_instance_of(OpenFda::Client).to receive(:query_for_interactions) { '' }
      allow_any_instance_of(Medicine).to receive(:fetch_array_from_response) { 'Sample text' }

      med = Medicine.new
      %w(warnings dosage_and_administration indications_and_usage drug_interactions).each do |field|
        expect(med.send(field)).to eq('Sample text')
      end
    end
  end

  describe 'set_interactions' do
    before do
      allow_any_instance_of(Medicine).to receive(:init) { '' }
      @med1 = Medicine.new(name: 'MED1', active_ingredient: '', interactions: [])
      @med2 = Medicine.new(drug_interactions: 'med1 interaction', interactions: [])
    end

    it 'updates interactions for both meds if they interact' do
      Medicine.set_interactions(@med1, @med2)

      expect(@med1.interactions.include?(@med2)).to be true
      expect(@med2.interactions.include?(@med1)).to be true
    end
  end
end
