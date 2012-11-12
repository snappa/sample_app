class UsersController < ApplicationController
  before_filter :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_filter :correct_user,   only: [:edit, :update]
  before_filter :admin_user,     only: :destroy
  before_filter :signed_in_user_exclusion, only: [:new, :create]

  def index
    @users = User.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
#    logger.error("Auth: \"#{request.authorization}\", IP: #{request.ip},  Raw Params: #{request.query_parameters}")
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
#    logger.error("update: Auth: \"#{request.authorization}\", IP: #{request.ip},  Raw Params: #{request.query_parameters}, HEADERS: #{request.headers}, PARAMS: #{params}")
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    logger.error("**** destroying #{user.email} ****")
    if (user.id == current_user.id)
      flash.now[:error] = "You can not delete yourself!"
      logger.error("You can not delete yourself!")
    else
      user.destroy
      flash[:success] = "User destroyed."
      logger.error("**** destroyed D2")
      begin
        u2 = User.find(params[:id])
        logger.error("**** destroyed #{user.email}.  U2 found? #{u2.email}")
      rescue
        logger.error("****  DID destroy #{user.email}")
      end
    end
    redirect_to users_url
  end

  private

    def signed_in_user_exclusion
      if signed_in?
        flash[:info] = "You're already logged in ..."
        redirect_to(root_path)
      end
    end

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
