module Simrb
	module Stool

		# generate many links of administration of background
		# virtually, this is an extension for generating data of data_menu to installs dir
		#
		# == Example
		#
		# 	$ 3s g_admin --demo
		#
		def g_admin module_name, write_file, args, opts
			path = base_append_suffix "#{Smods[module_name]}#{Spath[:install]}data_menu"

			# data of menu type
			data_menu = [
				{name: module_name, link: "/admin/info/#{module_name}", tag: 'admin'},
			]

			base_get_data_names(module_name).each do | name |
				link_name = name.to_s
				link_name = link_name.index("_") ? link_name.split("_")[1..-1].join(" ") : link_name
				data_menu << {name: link_name, link: "/admin/view/#{name}", parent: module_name, tag: 'admin'}
			end

			# turn the hash to string for writting as yaml file
			res = ""
			data_menu.each do | item |
				resh = ""
				item.each do | k, v |
					resh << "  #{k.to_s.ljust(15)}: #{v}\n"
				end
				resh[0] = "-"
				res << "#{resh}\n"
			end
			res = "---\n#{res}"

			# implement result
			base_print_generated write_file, path, res
		end

	end
end
