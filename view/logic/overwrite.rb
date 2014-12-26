helpers do

	def data_init name = nil, argv = {}
		v = argv

		#################################
		# preset the initial data
		#################################

		# if no given name, just extract it from request view
		if name == nil
			if params[:_name]
				name = params[:_name]
			elsif @qs.include?(:_name)
				name = @qs[:_name]
			elsif v.include?(:name)
				name = v[:name]
			else
				_throw Sl[:'no parameter _name']
			end
		end

		v[:name] 		= name.to_sym

		# conditions for updating and insertion, deleting, et
		v[:conditions]	||= {}

		# insert or update in data_submit method
		v[:opt]			||= :insert

		# validate the data
		v[:valid]		||= false

		# enable the tag
		v[:entag]		||= data_tag_enable?(v[:name])

		# guarantee the inserted value is unique
		v[:uniq]		||= true

		# do not submit the primary key value of field
		v[:nopk]		||= true

		# get the standard data schema
		@data 			= data_schema v[:name]
		v[:data]		||= @data[:data]
		v[:pk] 			||= @data[:pk]

		# all of field name of the table
 		v[:fields] 		||= @data[:fields]

		# an hash key-val that sets the table fields and values
		#
		# :fkv => {
		# 	:name => 'user name', :pawd => 'user password'
		# }
		# notice: it has not primary key included in there
 		v[:fkv] 		= (v[:setval] || v[:setValue] || v[:fkv] || {})

		#################################
		# preprocess the raw data
		#################################

		# process the forward operation for data_submit
		if @qs.include?(v[:pk])
			v[:conditions][v[:pk]] = @qs[v[:pk]].to_i 
			v[:opt] = :update
		end

		# process the tag value
		if v[:entag] == true
			v[:newtag] 	= v[:fkv].include?(:tag) ? v[:fkv][:tag] : (v.include?(:tag) ? v[:tag] : '')
			v[:oldtag] 	= v[:fkv].include?(:oldtag) ? v[:fkv][:oldtag] : (v.include?(:oldtag) ? v[:oldtag] : '')
			v[:entag] 	= false if v[:newtag] == ''
		end

		# auto complete the default value
		v[:fkv]			= data_set_fkv @data[:fkv], v[:fkv]

		# remove the primary key
		v[:fkv].delete(v[:pk]) if v[:nopk] == true

		# execute the validating
		data_valid v[:name], v[:fkv] if v[:valid] == true
		v
	end

	# overwirte the method of data module
	def data_set_fkv origin, replace = {}
		res = {}
		origin.each do | k, v |
			if replace.include?(k)
				res[k] = replace[k]
			elsif params[k]
				res[k] = params[k]
			elsif @qs.include? k
				res[k] = @qs[k]
			else
				res[k] = v
			end

			res[k] = Time.now if k == :changed
		end
		res
	end

	def data_delete name = nil, argv = {}
		t = data_init name, params
		@t[:repath] ||= (params[:_repath] || request.path)

		if params[t[:pk]]
			# delete one morn records
			if params[t[:pk]].class.to_s == 'Array'
				Sdb[t[:name]].where(t[:pk] => params[t[:pk]]).delete
			# delete single record
			else
				t[:conditions][t[:pk]] = params[t[:pk]].to_i 
				Sdb[t[:name]].filter(t[:conditions]).delete
			end
			_msg :delete, Sl[:'deleting completed']
		end
	end

	# overwrite the user_login?
	def view_login? redirect_url = ''
		if user_login?
			if redirect_url != '' and redirect_url != request.path
				@qs[:come_from] = request.path
				redirect _url2(redirect_url)
			end
		else
			redirect_url = _var(:login_link) if redirect_url == ''
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

	def user_page name
		_tpl @t[:tpl], :view_page
	end

end
