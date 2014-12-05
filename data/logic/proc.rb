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

	# prepare data for operation of following
	# first argument is a symbol that is the name(table name) of data block
	def data_init name, argv = {}
		v = argv

		v[:name] 		= name.to_sym
		v[:conditions]	||= {}

		# validate the data
		v[:valid]		||= true

		# guarantee the inserted value is unique
		v[:uniq]		||= true

		# classify the data with tag
		v[:tag]			||= true
		if v[:tag] == true and data_tag_enable?(v[:name])
			# extract the tag value from fkv
			if v[:fkv].include?(:tag)
				v[:newtag] = v[:fkv].delete(:tag)
				v[:oldtag] = v[:fkv].include?(:oldtag) ? v[:fkv].delete(:oldtag) : ''
			else
				v[:tag]	= false
			end
		end

		# get the standard data schema
		@data 			= data_schema v[:name]
		v[:data]		||= @data[:data]
		v[:pk] 			||= @data[:pk]

		# all of field name of the table
 		v[:fields] 		||= @data[:fields]

		# an hash key-val for storing table fields
		# it has some alias names, like the setval, setValue
 		v[:fkv] 		= (argv[:setval] || argv[:setValue] || argv[:fkv])
 		v[:fkv] 		= v[:fkv] ? @data[:fkv].merge(v[:fkv]) : @data[:fkv]

		v
	end

	def data_insert name, argv = {}
		v = data_init(name, argv)

		# process fields that would be stored to db
		f = data_set_field v[:fkv], v[:fields]
		f = v[:fkv].merge(f)
		data_valid v[:name], f if v[:valid] == true
		f.delete v[:pk]

		# check the record wether or not unique record, 
		# don`t insert the data if it existed in database
		if v[:uniq] == true
			ds = Sdb[v[:name]].filter(f)
			Sdb[v[:name]].insert(f) if ds.empty?
		else
			Sdb[v[:name]].insert(f)
		end

		# add tag
		if v[:tag] == true
			pkid = Sdb[v[:name]].filter(f).limit(1).get(v[:pk])
			data_add_tag v[:name], pkid, v[:newtag]
		end

		_msg :data_insert, Sl[:'adding completed']
	end

	def data_update name, argv = {}
		v 	= data_init(name, argv)
		ds	= Sdb[v[:name]].filter(v[:conditions])
		_msg :data_update, Sl[:'no record in database']

		unless ds.empty?
			f = data_set_field ds.first, v[:fields]
			data_valid(v[:name], f) if v[:valid] == true
			f.delete v[:pk]
			Sdb[v[:name]].filter(v[:conditions]).update(f)

			# add tag
			if v[:tag] == true
				pkid = ds.get(v[:pk])
				data_set_tag v[:name], pkid, v[:newtag], v[:oldtag]
			end

			_msg :data_update, Sl[:'update completed']
		end
	end

	def data_delete name, argv = {}
		v = data_init(name, argv)
	end

	# set field values for variable @f
	# @f is a key-val hash of field that would be submit to db
	#
	# == Arguments
	#
	# data,   a key-value hash that stores field name and value
	# fields, specify some fields to assign value
	#
	def data_set_field data, fields
		res = {}
		fields.each do | k |
			if params[k]
				res[k] = params[k]
			elsif @qs.include? k
				res[k] = @qs[k]
			elsif data.include? k
				res[k] = data[k]
			else
				res[k] = ''
			end

			# specify field, fill the value, auto
			if k == :changed
				res[k] = Time.now
			end
		end
		res
	end

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
		@cache.include?(name) ? @cache(name) : nil
	end

end

before do
	@cache = {}
end
