configure do
	Sdb = Sequel.connect(Scfg[:db_connection])
end

helpers do

	def _m2h str
# 		# redcarpet
#   	@markdown.render str

#  		# rdiscount
#  		RDiscount.new(str).to_html

		# kramdown
  		Kramdown::Document.new(str, @markdown_extensions).to_html
	end

	def data_markdown_load extension = {}
# 		require 'redcarpet'
# 		extensions 	= {:autolink => true, :space_after_headers => true}.merge(extension)
# 		html_obj 	= Redcarpet::Render::HTMSl.new()
# 		@markdown 	= Redcarpet::Markdown.new(html_obj, extensions)

		@markdown_extensions = extension
# 		require 'rdiscount'

  		require 'kramdown'
	end

	# get an hash with two fields of db table as key-val format
	def data_kv table, key, value
		name = "#{table}-#{key}-#{value}".to_sym
		@cache ||= {}
		unless @cache.has_key? name
			@cache[name] = Sdb[table].to_hash(key, value)
		end
		@cache[name]
	end

	# prepare data for the following operation
	# first argument is a symbol that is the name(table name) of data block
	def data_init name, argv = {}
		v = argv
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

	# replace the default value with given value
	def data_set_fkv origin, replace = {}
		res = {}
		origin.each do | k, v |
			# default value
			res[k] = v

			# given value
			res[k] = replace[k] if replace.include?(k)

			# auto completed value
			res[k] = Time.now if k == :changed
		end
		res
	end

	# submit data to database
	#
	# == Example
	#
	# by default, the method will insert a record to DB, 
	# or add the option `opt => update` for update the record that existed in DB yet
	#
	# data_submit(
	#	:blog_post, 
	#	:fkv 	=> { :title	=> 'new post', :body 	=> 'post content' },
	#	:uniq 	=> true,
	#	:valid 	=> false,
	#	#:opt	=> :update
	# )
	#
	def data_submit name, argv = {}
		v = data_init(name, argv)
		_msg :data_submit, Sl[:'nothing happened']

		if v[:opt] == :insert
			# check the record wether or not unique record, 
			# don`t insert the data if it existed in database
			if v[:uniq] == true
				ds = Sdb[v[:name]].filter(v[:fkv])
				Sdb[v[:name]].insert(v[:fkv]) if ds.empty?
			else
				Sdb[v[:name]].insert(v[:fkv])
			end

			# add tag
			if v[:entag] == true
				pkid = Sdb[v[:name]].filter(v[:fkv]).limit(1).get(v[:pk])
				data_add_tag v[:name], pkid, v[:newtag]
			end

			_msg :data_submit, Sl[:'adding completed']
		else
			ds	= Sdb[v[:name]].filter(v[:conditions])
			unless ds.empty?
				Sdb[v[:name]].filter(v[:conditions]).update(v[:fkv])

				# add tag
				if v[:entag] == true
					pkid = ds.get(v[:pk])
					data_set_tag v[:name], pkid, v[:newtag], v[:oldtag]
				end

				_msg :data_submit, Sl[:'update completed']
			end
		end
	end

# 	def data_delete name, argv = {}
# 		v = data_init(name, argv)
# 	end

	def data_valid name, f
		Svalid[name].map { |b| instance_exec(f, &b) } if Svalid[name]
	end

	def data_get name
		Sdata[name] ? Sdata[name].map { |b| instance_eval(&b) }.inject(:merge) : []
	end

	# return a entire schema of data that includes the form_type of field for template, 
	# data block, field keys, primary_key, an key-val hash of field
	#
	# == Returned
	#
	# table/data block defined schema
	# all of field names
	# primary_key of field
	# key-value of field
	#
	# == Example
	#
	# 	data_schema :user
	#
	# output
	# 
	# {
	# 	:data 	=> {:uid => {:default => 0, :type => 'Fixnum' ,,,}, :name => {:default => '', ,,,}}, 
	# 	:fields => [:uid, :name, :pawd, :level ,,,],
	# 	:pk 	=> :uid, 
	# 	:fkv 	=> {:uid => 0, :name => '', :pawd => '123456' ,,,}
	# }
	# 
	def data_schema name
		return data_cache(name) if data_cache?(name)

		pk 		= nil
		fields 	= []
		fkv		= {}
		data 	= data_format name

# 		schema = Sdb.schema name.to_sym
		data.each do | field, val |
			# save primary_key
			pk = field if val[:primary_key] == true

			# a key-val hash
			fkv[field] = val[:default]

			# default form type
			unless val.include? :form_type
				if val.include? :assoc_one
					val[:form_type] = :radio 
				elsif val.include? :assoc_many
					val[:form_type] = :checkbox 
				elsif Scfg[:field_number].include? val[:type]
					val[:form_type] = :number 
				elsif val[:type] == 'Text'
					val[:form_type] = :textarea 
				elsif field == :changed or field == :created
					val[:form_type] = :hide
				else
					val[:form_type] = :text
				end
			end

			# all of fields
			fields << field
		end

		res = { :data => data, :fields => fields, :pk => pk, :fkv => fkv }
		data_cache name, res
		res
	end

	# get the data block by name, and set the default type and value of field
	def data_format name, merge_data = nil
		data = data_get name.to_sym
		data.each do | key, val |
			# default field type, and field value
			unless val.include? :type
				# fisrt, judge by default value
				if val.include? :default
					val[:type] = val[:default].class.to_s

				# second, judge by assoc_one, or assoc_many, or primary_key
				elsif val.include?(:assoc_one) or val.include?(:assoc_many) or val.include?(:primary_key)
					val[:type] = Scfg[:field_number][0]
					val[:default] = 1

				# others, matches by field name
				else
					val[:type] = data_match_field_type key
					val[:default] = ''
				end
			end

			# default value of field
			unless val.include? :default
				if val.include? :type
					if Scfg[:field_number].include? val[:type]
						val[:default] = 1
					end
				end
			end
			val[:default] = '' unless val.include? :default
		end
	end

	# judge the field type by field name, automatically 
	def data_match_field_type field
		field = field.to_s
		if field[-2,2] == 'id'
			type = Scfg[:field_number][0]
		elsif Scfg[:field_fixnum].include? field
			type = 'Fixnum'
		elsif Scfg[:field_time].include? field
			type = 'Time'
		else
			type = 'String'
		end
		type
	end

	def data_cache name, content = nil
		# get value
		if content == nil
			@cache[name]

		# set value
		else
			@cache[name] = content
		end
	end

	def data_cache? name
		@cache.include?(name) ? @cache[name] : nil
	end

end

before do
	@cache = {}
end
