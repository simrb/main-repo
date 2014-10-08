module Simrb
	module Stool

		# generate view files
		#
		# == Examples
		#
		# Example 01, create a layout template
		#
		# 	$ 3s g view layout --demo 
		#
		# or, other template you should try
		#
		# 	$ 3s g view form --demo 
		#
		# or specify the file name with option --filename
		#
		# 	$ 3s g view form --demo --filename=myform
		#
		# by default, the file demo_myform.slim would be generated,
		#
		def g_view module_name, write_file, args, opts
			args.each do | name |
				method = "view_tpl_#{name}"
				if self.respond_to? method.to_sym
					eval("#{method} '#{module_name}', #{write_file}, #{args}, #{opts}")
				end
			end
		end

		# generate many templates that is a collection of view operated event,
		# it would copy the template layout, css, js, and helper
		#
		# == Example
		#
		# 	$ 3s g layout --demo
		#
		def g_layout module_name, write_file, args, opts
			['helper2', 'layout2', 'css', 'js'].each do | tpl |
 				g_view(module_name, write_file, (args + [tpl]), opts)
				puts "\n" + "-"*30 + "\n\n"
			end
		end

	end
end
