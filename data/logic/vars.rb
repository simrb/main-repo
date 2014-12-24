helpers do

	# get and set the variable
	#
	# == Example
	# 
	# get variable value by one argument
	#
	# 	_var :home_page
	#
	# set the variable value by two arguments
	#
	# 	_var :home_page, '/home/page'
	#
	def _var key, val = ''
		# get variable
		if val == ''
			ds = Sdb[:data_var].filter(:dkey => key.to_s)
			ds.empty? ? 'no var' : ds.get(:dval)

		# set variable
		else
			data_add_var({dkey: key, dval: val})
		end
	end

	# return an array as value, split by ","
	def _var2 key, val = '', sign = ","
		_var(key, val).to_s.split(sign)
	end

	# return a boolean value, estimate by true, on, yes
	def _var3 key, val = ''
		val_arr = %w(yes true on enable)
		val = _var(key, val).to_s
		val_arr.include?(val) ? true : false
	end

	# update variable, create one if it doesn't exist
	def data_set_var key, val
 		Sdb[:data_var].filter(:dkey => key.to_s).update(:dval => val.to_s, :changed => Time.now)
#  		data_insert(:data_var, :fkv => argv, :opt => :update) unless argv.empty?
	end

	def data_add_var argv = {}
		argv[:dkey] = argv[:dkey].to_s
		argv[:dval] = argv[:dval].to_s
 		data_insert(:data_var, :fkv => argv, :uniq => true) unless argv.empty?
	end

end



