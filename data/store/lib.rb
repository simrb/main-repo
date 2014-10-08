module Simrb
	module Stool

		# get the installed file by module name you need to install
		#
		# == Example
		#
		# 	base_install_file "demo"
		#
		# return the result as below
		#
		# {
		# 	# this is a file in installed directory called _user
		# 	:_user	=>	[
		# 		{:name => 'guest', :pawd => 'guest'},
		# 		{:name => 'system', :pawd => 'system', :level => 99},
		# 		{:name => 'test', :pawd => 'test', :level => 2},
		# 	]
		# 	# as above, a file called _rule
		# 	:_rule	=>	[
		# 		{:name => 'admin'},
		# 		{:name => 'system_opt'},
		# 	]
		# }
		#
		def base_install_file module_name
			res			= {}
			module_name	= module_name.to_s
			files 		= Dir["#{Smods[module_name]}#{Spath[:install]}*"]

			files_path	= Spath[:install_lock]
			files_lock	= []

			if Scfg[:install_lock] == 'yes'
				if File.exist? files_path
					files_lock = File.read(files_path).split("\n")
				else
					File.new(files_path, 'w')
				end

				files.each do | file |
					files.delete(file) if files_lock.include? file
				end

				unless files.empty?
					File.open(files_path, 'a') do | f |
						f.write(files.join("\n") + "\n")
					end
				end
			end

			files.each do | file |
				installer 		= file.split('/').last
				installer		= installer.split('.').first if installer.index('.')
				installer		= installer.to_sym
 				res[installer]  = []

				Simrb.yaml_read(file).each do | row |
					line = {}
					row.each do | k, v |
						line[k.to_sym] = v == nil ? '' : v
					end
					res[installer] << line
				end
			end

			res
		end

		# get the data block by module name
		#
		# == Example
		#
		# 	base_get_data_names "demo"
		#
		def base_get_data_names module_name, data = nil
			res 	= []
			data 	= Sdata.keys unless data
			data.each do | t |
				res << t if t.to_s.index("#{module_name}_") == 0 or t.to_s == module_name
			end
			res
		end

		# add a number as suffix for path
		def base_append_suffix path
			count 	= Dir[path, "#{path}.*"].count
			suffix 	= count > 0 ? ".#{count}" : ""
			path 	= "#{path}#{suffix}"
		end

		# convert an hash block to string
		def base_data_to_str table_name, data
			res = ""
			data.each do | k, v |
				res << "\t\t:#{k.to_s.ljust(23)}=>\t{\n"
				v.each do | k, v |
					res << "\t\t\t:#{k.to_s.ljust(19)}=>\t"
					if v.class.to_s == 'String'
						res << "'#{v}'"
					elsif v.class.to_s == 'Symbol'
						res << ":#{v}"
					else
						res << "#{v}"
					end
					res << ",\n"
				end
				res << "\t\t},\n"
			end
			res = "data :#{table_name} do\n\t{\n#{res}\t}\nend\n\n"
		end

		# generate the migration created by a data name that maybe is a table name
		#
		# == Examples
		#
		#	base_generate_migration_created table_name
		#
		def base_generate_migration_created name
			res		= ""
			data 	= data_format(name)

			data.each do | key, val |
				type 	= val.include?(:primary_key) ? 'primary_key' : val[:type]
				options = {}
				options[:size] = val[:size] if val.include?(:size)

				res << "\t\t\t"
				res << "#{type} :#{key}"
				unless options.empty?
					res << options.collect { |k,v| ", :#{k} => #{v}" }.join
				end
				res << "\n"
			end

			res = "\t\tcreate_table?(:#{name}) do\n#{res}\t\tend\n"
		end

		# generate the migration dropped
		def base_generate_migration_drop tables = []
			"\t\tdrop_table?(:#{tables})\n"
		end

		# generate the migration altered
		def base_generate_migration_altered table, data
			res = ""

			data.each do | key, val |
				val.each do | item |
					res << "\t\t\t"
					res << "#{key} "
					res << ":#{item.shift(1)[0]}"
					res << ", #{item[0]}" unless item.empty?
					res << "\n"
				end
			end

			res = "\t\talter_table(:#{table}) do\n#{res}\t\tend\n"
		end

		# match the language sentence with regular expression
		def base_match_lang args = []
			str = args
			res = []

			str.scan(/Sl\[(:|'|")?(:|'|")?(.+?)('|")?\]/) do |x, y, z, j|
				res << z unless [x, y, z, j].count(nil) == 3
			end

			res
		end

		# print the content in terminal, and write to file
		def base_print_generated write_file, path, res, mode = "a+"
			unless res.empty?
				# write result
				Simrb.path_write path, res, mode if write_file

				# display result
				puts "path: #{path}"
				puts res
			else
				puts "nothing to write"
			end
		end

	end
end

