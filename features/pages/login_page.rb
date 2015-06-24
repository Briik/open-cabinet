class LoginPage
  include Capybara::DSL, Rails.application.routes.url_helpers

  def visit_login_page
    visit(new_user_session_path)
  end

  def sign_in(user)
    fill_in('user_email', with: user.email)
    fill_in('user_password', with: user.password)
    find('#sign_in').click
  end

  def sign_out
    click_link 'Sign Out'
  end
end
