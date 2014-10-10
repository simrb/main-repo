helpers do

	# get the variable value that is a string, others is null value
	#
	# == Arguments
	#
	# key, this is key name
	# tag, tag name
	# val, default value, add the variable and set the default value if it isn`t existing
	#
	# == Example
	#
	# 	_var :home_page
	#
	# get the variable :home_page by tag 'www'
	#
	# 	_var :home_page, 'www'
	#
	# get the variable, if it isn`t existing, assign value '/home/page'
	#
	# 	_var :home_page, 'www', '/home/page'
	#
	def _var key, tag = '', val = ''
		h 	= {:dkey => key.to_s}
		ds 	= Sdb[:data_var].filter(h)

		if tag != ''
			tids = data_tag_ids(:data_var, tag)
 			ds = ds.filter(:dvid => tids)
		end

		# adding if the variable hasn't existing in database
		if ds.empty?
			data_add_var({dkey: key, tag: tag, dval: val})
			val
		else
			ds.get(:dval)
		end
	end

	# return an array as value, split by ","
	def _var2 key, tag = '', val = '', sign = ","
		val = _var key, tag, val
		val.to_s.split(sign)
	end

	# update variable, create one if it doesn't exist
	def data_set_var key, val
 		Sdb[:data_var].filter(:dkey => key.to_s).update(:dval => val.to_s, :changed => Time.now)
#  		data_submit(:data_var, :fkv => argv, :opt => :update) unless argv.empty?
	end

	def data_add_var argv = {}
		argv[:dkey] = argv[:dkey].to_s
		argv[:dval] = argv[:dval].to_s
 		data_submit(:data_var, :fkv => argv, :uniq => true) unless argv.empty?
	end

end



