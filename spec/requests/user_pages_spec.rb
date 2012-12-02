require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "index" do

    let(:user) { FactoryGirl.create(:user) }

    before(:each) do
      sign_in user
      visit users_path
    end

    it { should have_selector('title', text: 'All users') }
    it { should have_selector('h1',    text: 'All users') }

    describe "pagination" do

      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all)  { User.delete_all }

      it { should have_selector('div.pagination') }

      it "should list each user" do
        User.paginate(page: 1).each do |user|
          page.should have_selector('li', text: user.name)
        end
      end
    end

    describe "delete links" do

      it { should_not have_link('delete') }

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before :each do
          @admin2 = FactoryGirl.create(:admin, email: "dobedobedo@foo.com")
          sign_in admin
          visit users_path
        end

        it { should have_link('delete', href: user_path(User.first)) }
        it "should be able to delete another user" do
          expect { click_link('delete') }.to change(User, :count).by(-1)
        end
        it { should_not have_link('delete', href: user_path(admin)) }

        it { expect { delete user_path(admin) }.not_to change(User, :count) }

        it "admin2 should not be nil when looked up" do
          @admin2 = User.find_by_email("dobedobedo@foo.com")
          @admin2.should_not be_nil
        end
        it { expect { delete user_path(@admin2) }.to change(User, :count).by(-1) }
      end

      describe "one admin delete another" do
#        let(:admin) { FactoryGirl.create(:admin) }
#        let(:admin2) { FactoryGirl.create(:admin, email:"whoopdedo@dobedoNT.com") }
        before :each do
          @admin = FactoryGirl.create(:admin)
          @admin2 = FactoryGirl.create(:admin, email:"whoopdedo@dobedoNT.com")
          sign_in @admin
          visit users_path
        end
        it { should have_link('delete', href: user_path(User.first)) }

        it { expect { delete user_path(@admin) }.not_to change(User, :count) }
        it { expect { delete user_path(@admin2) }.to change(User, :count).by(-1) }

#        a2 = User.find_by_email("whoopdedo@dobedoNT.com")
#        it { a2.should_not be_nil }
#        it {a2.email.should == "whoopdedo@dobedont.com"}
        #it { expect { delete user_path(admin2) }.to change(User, :count).by(-1) }
      end

    end
    
  end

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

        it { should have_link('Sign out') }
      end

    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_selector('h1',    text: "Update your profile") }
      it { should have_selector('title', text: "Edit user") }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid information" do
      before { click_button "Save changes" }

      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name)  { "New Name" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in "Name",             with: new_name
        fill_in "Email",            with: new_email
        fill_in "Password",         with: user.password
        fill_in "Confirmation", with: user.password
        click_button "Save changes"
      end

      it { should have_selector('title', text: new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }
      specify { user.reload.name.should  == new_name }
      specify { user.reload.email.should == new_email }
    end
  end

  # section 9.6 Exercises, question 1.  Test for admin accessibility.
  describe "can only access admin when attr_accessible" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      user.toggle!(:admin)
    end

    subject { user }

    it { should respond_to(:admin) }

    it { should be_admin }

    describe "toggling admin" do
      before do
        user.toggle!(:admin)
      end

      it { should_not be_admin }
      @user = User.new(name:"fred", email: "garvin@snl.com", password:"foobar",password_confirmation:"foobar")
      @user.save
      @u = User.find_by_email "garvin@snl.com"
      it "should not be true" do
#        @user.reload.name.should == "fred"
        foo = "fred"
        foo.should == "fred"
        foo = "freddy"
        foo.should == "freddy"

        # Can't mass assign without adding admin to attr_accessible.  Make sure 
        # this raises an exception
        expect{ User.new(name:"freddy", email: "fred@garvin.com", password:"foobar",password_confirmation:"foobar", admin: true) } .to_not raise_error

        fuser = User.new(name:"freddy", email: "fred@garvin.com", password:"foobar",password_confirmation:"foobar")

        fuser.email.should == "fred@garvin.com"
        fuser.should_not be_admin
        fuser.admin = true
        fuser.should be_admin
      end
#      @user.reload.toggle!(:admin)
#      it { should_not be_admin }

    end

=begin
    it "should now allow access to admin on ctor" do
      expect do
        @user = User.new(name: "Fred", email: "foo@boobar.com", password: "foobar", 
                       password_confirmation: "foobar", admin: true)
      end.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end
=end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

    before { visit user_path(user) }

    it { should have_selector('h1',    text: user.name) }
    it { should have_selector('title', text: user.name) }

    describe "microposts" do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should have_content(user.microposts.count) }
    end
  end

end
