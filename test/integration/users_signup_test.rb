require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

	def setup
		ActionMailer::Base.deliveries.clear
	end

	test "invalid signup form validation" do
		get signup_path
		assert_no_difference 'User.count' do
			post users_path, params: { user: { 
				name: "",
				email: "user@invalid",
				password: "foo",
				password_confirmation: "bar" } }
		end
		assert_template 'users/new'
		assert_select 'div#error_explanation'
		assert_select 'div.alert'

	end

	test "form error messages" do
		error_messages = [
			"<li>Name can't be blank</li>",
			"<li>Email is invalid</li>",
			"<li>Password confirmation doesn't match Password</li>",
			"<li>Password is too short (minimum is 6 characters)</li>"
		]
    
		get signup_path
		post users_path, params: { user: { 
				name: "",
				email: "user@invalid",
				password: "foo",
				password_confirmation: "bar" } }
		# Test the amount of errors returned
		assert_select "#error_explanation .alert", "The form contains 4 errors."

		# Make sure the all the erros are known error messages
		items = css_select("#error_explanation ul>li")
		items.each do |item|
			assert error_messages.include?("#{item}"), "Unknown Error #{item}"
		end
		assert_template 'users/new'
	end

	test "valid signup information with account activation" do
		get signup_path
		assert_difference 'User.count', 1 do
			post users_path, params: { user: { name:  "Example User",
																				 email: "user@example.com",
																				 password:              "password",
																				 password_confirmation: "password" } }
		end
		assert_equal 1, ActionMailer::Base.deliveries.size
		user = assigns(:user)
		assert_not user.activated?
		# Try to log in before activation.
		log_in_as(user)
		assert_not is_logged_in?
		# Invalid activation token
		get edit_account_activation_path("invalid token", email: user.email)
		assert_not is_logged_in?
		# Valid token, wrong email
		get edit_account_activation_path(user.activation_token, email: 'wrong')
		assert_not is_logged_in?
		# Valid activation token
		get edit_account_activation_path(user.activation_token, email: user.email)
		assert user.reload.activated?
		follow_redirect!
		assert_template 'users/show'
		assert is_logged_in?
	end

end
