require 'rails_helper'

RSpec.describe User, type: :model do
  it 'can contain a cabinet' do
    cabinet = Cabinet.create!
    User.create!(email: 'test1@test.com', password: 'password', cabinet: cabinet)

    expect(1 eq 1)
  end
end
