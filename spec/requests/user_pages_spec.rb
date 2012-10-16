require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "signup page" do
    before { visit signup_path }

    it { should have_selector('h1',    text: 'Sign up') }
    it { should have_selector('title', text: 'Sign up') }
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    before { visit user_path(user) }

    it { should have_selector('h1',    text: user.name) }
    it { should have_selector('title', text: user.name) }
  end

  describe "signup" do

    before { visit signup_path }

    let(:submit) { "Create my account" }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end

      describe "after submission" do
        before { click_button submit }

        it { should have_selector('title', text: 'Sign up') }
        it { should have_content('error') }
      end

      # EXERCISE 7.6, #2, WDS tests
      describe "name to long" do
        before do
          fill_in "Name", with: ("a" * 51)
          fill_in "Email", with: "foo@bar.com"
          fill_in "Password", with: "foobar"
          fill_in "Confirmation", with: "foobar"
          click_button submit
        end

        it { should have_selector('div', text: 'form contains 1 error') }
        it { should have_content('Name is too long (maximum is 50 characters') }

      end

      describe "name to long and invalid email" do
        before do
          fill_in "Name", with: ("a" * 51)
          fill_in "Email", with: "bar.com"
          fill_in "Password", with: "foobar"
          fill_in "Confirmation", with: "foobar"
          click_button submit
        end

        it { should have_selector('div', text: 'form contains 2 errors') }
        it { should have_content('Name is too long (maximum is 50 characters') }
        it { should have_content('Email is invalid') }

      end

    end

    describe "with valid information" do
      before do
        fill_in "Name",         with: "Example User"
        fill_in "Email",        with: "user@example.com"
        fill_in "Password",     with: "foobar"
        fill_in "Confirmation", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by_email('user@example.com') }

        it { should have_selector('title', text: user.name) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
      end

    end
  end

end
