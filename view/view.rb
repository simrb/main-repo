# set the default page
get '/' do
#  	pass if request.path_info == '/'
	status, headers, body = call! env.merge("PATH_INFO" => _var(:home, :link))
end

# assets resource
get '/_assets/*' do
	path_items 	= request.path.split('/')
	module_name	= path_items.shift(3)[2]
	path 		= "#{Smods[module_name]}#{Spath[:assets]}#{path_items.join('/')}"
	send_file path, :type => request.path.split('.').last().to_sym
end

# require 'sass'
# configure do
# 	set :sass, :cache => true, :cahce_location => './tmp/sass-cache', :style => :compressed
# end
# 
# get '/css/sass.css' do
# 	sass :index
# end

get '/view/index' do
	Sl[:"default page"]
end

get "/robots.txt" do
	arr = [
		"User-agent:*",
		"Disallow:/_*",
	]
	arr.join("\n")
end

# a interface route for submitting data
post '/view/operate' do
	method	= params[:view_post] ? params[:view_post] : (@qs.include?(:view_post) ? @qs[:view_post] : "")
	method	= "view_post_#{method}"
	argv	= view_init
	if self.respond_to?(method.to_sym)
		eval("#{method} argv")
	end
	@t[:repath] ||= (params[:_repath] || request.referer)
	redirect @t[:repath]
end

get '/file/list/:type' do
	file_list params[:type]
end

get '/file/get/:fnum' do
	file_get params[:fnum]
end

