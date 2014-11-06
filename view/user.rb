get '/l' do redirect _var(:login, :link) end
get '/user/login' do
	redirect _var(:after_login, :link) if user_info[:uid] > 0
	@qs[:come_from] = request.referer unless @qs.include?(:come_from) 
	user_page :user_login
end

get '/user/logout' do
	user_logout
end

# get '/user/register' do
# 	if _var(:allow_register, :user) == 'yes'
# 		user_page :user_register
# 	else
# 		redirect _var(:login, :link)
# 	end
# end

post '/user/login' do
	user_login params
	return_page = @qs.include?(:come_from) ? @qs[:come_from] : _var(:after_login, :link)
	redirect return_page
end

post '/user/register' do
	user_info_add params if _var(:allow_register, :user) == 'yes'
	return_page = @qs.include?(:come_from) ? @qs[:come_from] : _var(:after_login, :link)
	redirect return_page
end


helpers do

	def user_page name
		_tpl name, :layout
	end

	def view_login? redirect_url = ''
		if user_login?
			if redirect_url != '' and redirect_url != request.path
				@qs[:come_from] = request.path
				redirect _url2(redirect_url)
			end
		else
			redirect_url = _var(:login, :link) if redirect_url == ''
			if redirect_url != request.path
				@qs[:come_from] = request.path
				redirect _url2(redirect_url)
			end
		end
	end

	# if the user level less than the given, raise a message
	def view_level? level
		_throw Sl[:'your level is too low'] if user_info[:level].to_i < level.to_i
	end

end
