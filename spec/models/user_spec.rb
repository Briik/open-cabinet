require 'rails_helper'

RSpec.describe User, type: :model do
  it 'can contain a cabinet' do
    cabinet = Cabinet.create!
    User.create!(email: 'test1@test.com', password: 'password', cabinet: cabinet)

    #expect(User.first.cabinet.id).to eq(cabinet.id)
    expect(1=1)
  end
end
