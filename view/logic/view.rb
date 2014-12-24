# set the default page
get '/' do
#  	pass if request.path_info == '/'
	status, headers, body = call! env.merge("PATH_INFO" => _var(:home_link))
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


#########################
# editor.js interface
#########################

# list by type
get '/view/ajax/filelist/:name' do
	file_list params[:name]
end

# get file by id
get '/view/ajax/file/:fnum' do
	file_get params[:fnum]
end

# upload file by ajax
post '/view/ajax/upload' do
	params[:upload] ? file_save(params[:upload]) : ''
end


#########################
# view_post interface
#########################

# a interface route for submitting data
post '/view/operate/:_name' do
	method	= params[:view_post] ? params[:view_post] : (@qs.include?(:view_post) ? @qs[:view_post] : "")
	method	= "view_post_#{method}"
	if self.respond_to?(method.to_sym)
		eval("#{method}")
	end
# 	@t[:repath] ||= (params[:_repath] || request.referer)
	redirect (params[:_repath] || request.referer)
end


