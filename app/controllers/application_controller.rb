class ApplicationController < ActionController::Base
  protect_from_forgery

	before_filter :find_user, :except => :login

	def find_user
		reset_session if session[:last_seen].nil? or session[:last_seen] < 25.minutes.ago 
		session[:last_seen] = Time.now
		if session[:user_id].nil?
			redirect_to '/auth/facebook'
		else
			@user ||= User.find_by_id(session[:user_id])
			session[:last_seen] = Time.now
		end
	end
end
