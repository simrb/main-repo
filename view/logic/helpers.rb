configure :production do
	not_found do
		Sl['sorry, no page']
	end

	error do
		Sl['sorry there was a nasty error,'] + env['sinatra.error'].name
	end
end

before do
	@t[:msg]	= ''
	@t[:css]	= {}
	@t[:js]		= {}

	unless request.cookies['msg'] == ''
		@t[:msg] = request.cookies['msg']
		response.set_cookie 'msg', :value => '', :path => '/'
	end
end

after do
	unless @msg.empty?
 		response.set_cookie 'msg', :value => @msg.values.join('\n'), :path => '/'
	end
end

helpers do

	######################################################
	# template component
	######################################################

	# table view
	def view_table name = nil, argv = {}
		@t[:layout]			= false
		@t[:tpl] 			= :view_table
		@t[:js][:table]		= 'view/checkall.js'

		@t[:search_fns]		= []
		@t[:btn_fns] 		= {}
		@t[:opt_fns] 		= {}
		@t[:lnk_fns]		= {}
		@t[:view_post] 		= 'submit'

		@t.merge!(data_init(name, argv))

		@t[:action] 		= "/view/operate/#{@t[:name]}"
		@t[:orders] 		||= @t[:fields]

		# condition
		if @t[:search_fns] == :enable
			@t[:search_fns] = @t[:fields]
			if @qs[:sw] and @qs[:sc]
				sw = @qs[:sw].to_sym
				sc = @qs[:sc]
				if @t[:data][sw].has_key? :assoc_one
					akv = data_kv @t[:data][sw][:assoc_one][0], @t[:data][sw][:assoc_one][1], sw
					sc = akv[sc]
				end
				@t[:conditions][sw] = sc
			end
		end

		# enable tag
		if data_tag_enable? @t[:name]
			if @qs[:_tag]
				@t[:conditions][@t[:pk]] = data_tag_ids(@t[:name], @qs[:_tag])
			end
		end

		ds = Sdb[@t[:name]].filter(@t[:conditions])

		# order
		if @qs[:order]
			ds = ds.order(@qs[:order].to_sym)
		else
			ds = ds.reverse_order(@t[:pk])
		end

		# the pagination parameters
		@page_count = 0
		@page_size = 30
		@page_curr = (@qs.include?(:page_curr) and @qs[:page_curr].to_i > 0) ? @qs[:page_curr].to_i : 1

		ds = ds.extension :pagination
		@ds = ds.paginate(@page_curr, @page_size, ds.count)
		@page_count = @ds.page_count

		_tpl @t[:tpl], @t[:layout]
	end

	# list view
	def view_list name = nil, argv = {}
		argv[:tpl] = :view_list
		view_table name, argv
	end

	# form view
	def view_form name = nil, argv = {}
		@t[:layout]			= false
		@t[:tpl] 			= :view_form
		@t[:opt] 			= :insert
		@t[:back_fn] 		= :enable
		@t[:view_post] 		= 'submit'
		@t[:_repath] 		= request.path
		@t.merge!(data_init(name, argv))

		@t[:action] 		= "/view/operate/#{@t[:name]}"
		@t[:fields].delete @t[:pk]
		data = @t[:fkv]

		#edit record, if has pk value
		if @qs.include?(@t[:pk])
			@t[:conditions][@t[:pk]] = @qs[@t[:pk]].to_i 
			ds = Sdb[@t[:name]].filter(@t[:conditions])
			unless ds.empty?
				data = ds.first
				@t[:opt] = :update
			end
		end

		@f = data_set_fkv @t[:fkv], data
		_tpl @t[:tpl], @t[:layout]
	end

	# file view
	def view_file name = nil, argv = {}
		@t[:entries] 		= 6
		@t[:layout]			= false
		@t[:tpl] 			= :view_file
		@t[:_repath] 		= request.path
		@t[:_name] 			= :file_info
		@t[:action] 		= "/view/operate/#{name}"
		@t.merge!(argv)
# 		@t.merge!(argv.merge(:name => name))

		_tpl @t[:tpl], @t[:layout]
	end

	# admin view for admin module
	def view_admin name, argv = {}, more = {}
		method 	= @qs.include?(:view_get) ? @qs[:view_get] : 'show'
		argv 	= argv.merge(more[method.to_sym]) if more.include? method.to_sym
		argv	= argv.merge(:name => name, :layout => :admin_layout)
		method	= "view_get_#{method}"

		if self.respond_to?(method.to_sym)
			eval("#{method} argv")
		end
	end

	######################################################
	# interface for route of view operation
	######################################################

	# auto process the submitted data from view request
	def view_post_submit name = nil, argv = {}
		data_submit name, argv = {}
	end

	def view_post_delete name = nil, argv = {}
		data_delete name, argv = {}
	end

	# interface method for view administration
	def view_get_show argv
		argv[:btn_fns] 		||= { :create => 'edit' }
		argv[:opt_fns] 		||= { :delete => 'delete' }
		argv[:lnk_fns]		||= { :edit => 'edit' }
		argv[:search_fns]	||= :enable
		view_table argv[:name], argv
	end

	def view_get_edit argv
		view_form argv[:name], argv
	end

	######################################################
	# template helper method
	######################################################

	# return current path, and with options
	#
	# == Examples
	#
	# assume current request path is /demo/user
	#
	# 	_url() # retuen '/demo/user'
	#
	# or give a path
	#
	# 	_url('/demo/home') # return '/demo/home'
	#
	# and, with some parameters
	#
	# 	_url('/demo/home', :uid => 1, :tag => 2) # return '/demo/home?uid=1&tag=2'
	#
	def _url path = request.path, options = {}
		str = path
		unless options.empty?
			str += '?'
			options.each do | k, v |
				str = str + k.to_s + '=' + v.to_s + '&'
			end
		end
		str
	end

	# it likes _url, but appends the @qs for options
	def _url2 path = '', options = {}
		@qs.merge!(options) unless options.empty?
		_url path, @qs
	end

	# load the template
	def _tpl name, layout = false, tag = "view"
		# just load the tpl
		if layout == false
			slim name, :layout => layout

		# load the page layout
		else
			@t[:title] 			||= _var("#{tag}_title")
			@t[:keywords]		||= _var("#{tag}_keywords")
			@t[:description]	||= _var("#{tag}_description")
			@t[:msg] << @msg.values.join("\n") unless @msg.empty?
			slim name, :layout => layout
		end
	end

	# throw out the message and halt current operation
	# suppot the ajax return, or redirect back
	def _throw str
		if request.path.split('/').include?('ajax')
			halt 200, str
		else
			response.set_cookie 'msg', :value => str, :path => '/'
			redirect back
		end
	end

	def _css path, domain = '/'
		"<link rel='stylesheet' type='text/css' href='#{_assets(path, domain)}' />"
	end

	def _js path, domain = '/'
		"<script type='text/javascript' src='#{_assets(path, domain)}'></script>"
	end

	def _file fnum, domain = '/'
		"#{domain}view/ajax/file/#{fnum}"
	end

	# generate the assets url
	#
	# == Example
	#
	# 	_assets('view/admin.css')
	# 	_assets('view/admin.css', 'https//www.example.com')
	#
	def _assets path, domain = '/'
		domain = '/_assets/' if domain == '/'
		"#{domain}#{path}"
	end

end

