get '/l' do redirect _var(:login, :link) end
get '/user/login' do
	redirect _var(:after_login, :link) if user_info[:uid] > 0
	@qs[:come_from] = request.referer unless @qs.include?(:come_from) 
	user_page :view_login
end

get '/user/logout' do
	user_logout
end

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
