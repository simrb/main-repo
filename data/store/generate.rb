
module Simrb
	module Stool

		# a shortcut for all of generating commands
		#
		# Note:
		#
		# 1, all of generating methods support the options --module_name, and --nw
		# 2, all of example that assumes the demo is a module name, so the --module_name is --demo
		# 3, the --nw option it means no writting to file, that method just displays the output
		#
		# == Example
		#
		#	$ 3s g data demo_test name description --demo
		#	$ 3s g migration --demo
		#	$ 3s g view --demo form
		#
		# the result same as,
		#
		#	$ 3s g d demo_test name description --demo
		#	$ 3s g m --demo
		#	$ 3s g v form --demo 
		#
		def g args = []
			method 		= args.shift(1)[0]
			method 		= Scfg[:alias_gcmd][method] if Scfg[:alias_gcmd].keys.include? method
			method 		= 'g_' + method

			write_file	= true
			module_name = Scfg[:module_focus] ? Scfg[:module_focus] : nil
			args, opts	= Simrb.input_format args

			if opts[:nw]
				write_file = false
				opts.delete :nw
			end

			unless opts.empty?
				opts.each do | k, v |
					if k.to_s.to_i == 0
						module_name = k
						opts.delete k
					end
				end
			end

			Simrb.p("no module name given", :exit) if module_name == nil

			# implement the method
			if Stool.public_instance_methods.include? method.to_sym
				eval("#{method} '#{module_name}', #{write_file}, #{args}, #{opts}")
			else
				puts "No method #{method} defined"
			end
		end

		# generate the language sentence to file store/langs/*.en
		#
		# == Example
		#
		# 	$ 3s g lang en --demo 
		#
		# or, like this
		#
		# 	$ 3s g lang jp --demo 
		# 	$ 3s g lang cn --demo 
		# 	$ 3s g lang de --demo 
		#
		def g_lang module_name, write_file, args, opts
			lang		= args[0] ? args[0] : Scfg[:lang]
			dirs		= Dir["#{Smods[module_name]}#{Spath[:lang]}*.#{lang}"]
			resp 		= {}
			resh		= {}
			data		= {}

			dirs.each do | path |
				data.merge! Simrb.yaml_read path
			end

			Dir[
				"#{Smods[module_name]}#{Spath[:logic]}*.rb",
				"#{Smods[module_name]}/*.rb",
				"#{Smods[module_name]}#{Spath[:store]}*.rb",
				"#{Smods[module_name]}#{Spath[:tool]}*.rb",
				"#{Smods[module_name]}#{Spath[:view]}*.slim",
			].each do | path |
				base_match_lang(File.read(path)).each do | name |
					unless data.has_key? name
						resh[name] = name
						resp["from: #{path}"] ||= ""
						resp["from: #{path}"] << "\n#{name.ljust(20)} : #{name}"
					end
				end
			end

			# write content to file
			unless resh.empty?
				path = "#{Smods[module_name]}#{Spath[:lang]}#{module_name}#{(dirs.count + 1)}.#{lang}"
				res	= ""
				resh.each do | k, v |
					res << "#{k.ljust(20)}: #{v}\n"
				end
				res = "---\n#{res}"

				Simrb.path_write path, res if write_file
			end

			base_print_generated false, path, resp.map{|k,v| "\n#{k}#{v}"}
		end

		# generate the data block from a input array to a output hash
		#
		#
		# == Example 01, normal mode
		#
		# 	$ 3s g data table_name field1 field2 --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :default 		=> ''},
		# 			:field2	=>	{ :default 		=> ''},
		# 		}
		# 	}
		#
		# or, no writing the file, just display the generated content
		#
		# 	$ 3s g_data table_name field1 field2 --demo --nw
		#
		#
		# == Example 02, specify the field type, by default, that is string
		#
		# 	$ 3s g data table_name field1:pk field2:int field3:text field4 --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :pramiry_key	=> true },
		# 			:field2	=>	{ :type			=> 'Fixnum' },
		# 			:field3	=>	{ :type			=> 'Text' },
		# 			:field4	=>	{ :default		=> ''},
		# 		}
		# 	}
		#
		#
		# == Example 03, more parameters of field
		#
		# 	$ 3s g data table_name field1:pk field2:int=1:label=newfieldname field3:int=1:assoc_one=table,name --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :pramiry_key => true },
		# 			:field2	=>	{ :type	=> :integer, :default => 1, :label => :newfieldname },
		# 			:field3	=>	{ :default => 1, :assoc_one => [:table, :name] },
		# 		}
		# 	}
		#
		def g_data module_name, write_file, args, opts
			auto		= opts[:auto] ? true : false
 			has_pk 		= false
			table 		= args.shift
			key_alias 	= [:pk, :fk, :index, :unique]
			data 		= {}

			# the additional options of field should be this
			#
			# 	'field'
			# 	'field:pk'
			# 	'field:str'
			# 	'field:int'
			# 	'field:int=1'
			# 	'field:text'
			# 	'field:int=1:label=newfield:assoc_one=table_name,fieldname'
			#
			# the fisrt one is field name,
			# the second one is field type, or primary key, or other key
			# the others is extend

			# format the data block from an array to an hash
			args.each do | item |
				if item.include?(":")
					arr = item.split(":")

					# set field name
					field = (arr.shift).to_sym
					data[field] = {}

					# set field type
					if arr.length > 0
						# the second item that allows to be not the field type, 
						# it could be ignored by other options with separator sign "="
 						unless arr[0].include?('=')
							type = (arr.shift).to_sym

							# normal field type
							if Scfg[:alias_fields].keys.include? type
								data[field][:type] = Scfg[:alias_fields][type]

							# main keys
							elsif key_alias.include? type
								if type == :pk
									data[field][:primary_key] = true 
									has_pk = true
								else
								end
							else
								data[field][:type] = type.to_s
							end

						end
					end

					# the other items of field
					if arr.length > 0
						arr.each do | a |
							if a.include? "="
								key, val = a.split "="
								if val.include? ','
									val = val.split(',').map { |v| v.to_sym }
								end
								data[field][key.to_sym] = val
							end
						end
					end
				else
					data[item.to_sym] = {}
# 					data[item.to_sym][:default] = ''
				end
			end

			# complete the field type and default value, 
			# because those operatings could be ignored at last step.
			data.each do | field, vals |
				# replace the field type with its alias
				Scfg[:alias_fields].keys.each do | key |
					if data[field].include? key
						data[field][:type] 		= Scfg[:alias_fields][key]
						data[field][:default] 	= key == :int ? data[field][key].to_i : data[field][key]
						data[field].delete key
					end
				end

				# the association field that default type is Fixnum (integer)
				if data[field].include? :assoc_one
					data[field][:type] = Scfg[:field_number][0]
				end
			end

			# automatically match the primary key
			if auto == true and has_pk == false
				h = {"#{table}_id".to_sym => {:primary_key => true}}
				data = h.merge(data)
			end

			# write content to data.rb
			res 	= base_data_to_str table, data
			path 	= "#{Smods[module_name]}/data.rb"

			base_print_generated write_file, path, res
		end

		# generate the migration file by a gvied module name
		#
		# == Examples
		#
		# running at command
		#
		# 	$ 3s g m --demo
		#
		# or, no writting the file, just display the generated content
		#
		# 	$ 3s g m --demo --nw
		#
		# running with method mode
		#
		# 	g_migration demo, true
		#
		def g_migration module_name, write_file, args = [], opts = {}
			res				= ''
			operations		= []
			create_tables 	= []
			drop_tables		= []
			alter_tables	= {}
			origin_tables 	= base_get_data_names module_name, Sdb.tables
			current_data 	= base_get_data_names module_name
			all_tables		= (origin_tables + current_data).uniq

			Simrb.path_write Spath[:schema]

			all_tables.each do | table |
				data = data_format table

				# altered tables if the change is checked
				if origin_tables.include?(table) and current_data.include?(table)
					current_fields 	= data_format(table).keys
					origin_fields	= origin_tables.include?(table) ? Sdb[table].columns : []
					all_fields		= (current_fields + origin_fields).uniq

					all_fields.each do | field |
						# altered fields if the change is checked
						if origin_fields.include?(field) and current_fields.include?(field)

						# removed fields
						elsif origin_fields.include? field
							alter_tables[table] ||= {}
							alter_tables[table][:drop_column] ||= []
							alter_tables[table][:drop_column] << [field]

						# created fields
						else
							alter_tables[table] ||= {}
							alter_tables[table][:add_column] ||= []
							alter_tables[table][:add_column] << [field, data[field][:type]]
						end
					end

				# dropped tables
				elsif origin_tables.include?(table)
					drop_tables << table

				# created tables
				else
					create_tables << table
				end
			end

			# generated result about altering operation
			unless alter_tables.empty?
				operations << :altered
				alter_tables.each do | table, data |
					res << base_generate_migration_altered(table, data)
				end
			end

			# generated result about creating operation
			unless create_tables.empty?
				operations << :created
				create_tables.each do | table |
					res << base_generate_migration_created(table)
				end
			end

			# generated result about dropping operation
			unless drop_tables.empty?
				operations << :dropped
				drop_tables.each do | table |
					res << base_generate_migration_drop(table)
				end
			end

			unless res == ''
				count 	= Dir[Spath[:schema] + "*"].count + 1
				fname 	= args[1] ? args[1] : "#{operations.join('_')}_#{Time.now.strftime('%y%m%d%H%M%S')}" 
				path 	= "#{Spath[:schema]}#{count.to_s.rjust(3, '0')}_#{fname}.rb"
				res		= "Sequel.migration do\n\tchange do\n#{res}\tend\nend\n"
				base_print_generated write_file, path, res
			end
		end

		# generate a file in installed dir
		#
		# == Example 01, normal mode
		#
		# 	$ 3s g install data_menu --demo 
		# 	$ 3s g install data_menu --demo --nw
		# 	$ 3s g install data_menu name:myMenu link:myLink --demo 
		#
		# or take it with an alias name of `i`
		# 
		# 	$ 3s g i data_var --demo
		#
		# == Example 02, create many records at one time, -3 that means creating 3 records
		#
		# 	$ 3s g i data_var --demo -3
		#
		def g_install module_name, write_file, args, opts
			record_num		= 2
			field_ignore 	= [:created, :changed, :parent]
			res 			= ""

			# how many records would be created?
			unless opts.empty?
				opts.keys.each do | k |
					record_num = k.to_s.to_i if k.to_s.to_i > 0
				end
			end

			table_name	= args.shift(1)[0]
			path 		= base_append_suffix "#{Smods[module_name]}#{Spath[:install]}#{table_name}"

			# default value of given by command arguments
			resh 		= {}
			args.each do | item |
				key, val = item.split ":"
				resh[key.to_sym] = val
			end

			data_format(table_name).each do | k, v |
				if v.include? :primary_key
				elsif field_ignore.include? k
				else
					v[:default] = resh[k] if resh.include? k
					res << "  #{k.to_s.ljust(15)}: #{v[:default]}\n"
				end
			end

			res[0]	= "-"
			res 	= "---\n" + "#{res}\n"*record_num

			base_print_generated write_file, path, res
		end

	end
end
