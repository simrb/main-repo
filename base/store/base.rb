module Simrb
	module Stool

		# get a module from github to local modules dir
		#
		# == Example
		# 
		# 	$ 3s get simrb/demo
		#
		def get args = []
			require 'simrb/comd'
			simrb_app = Simrb::Scommand.new
			simrb_app.run(args.unshift('get'))
		end

		# create a module, initializes the default dirs and files of module
		#
		# == Example
		# 
		# 	$ 3s new demo
		#
		def new args
			require 'simrb/comd'
			simrb_app = Simrb::Scommand.new
			simrb_app.run(args.unshift('new'))
		end

		# run the bundled operation for module
		#
		# == Example
		#
		# 	$ 3s bundle demo
		#
		def bundle args = []
			puts "Starting to bunlde gemfile for modules ..."
			args = Smods.keys if args.empty?

			args.each do | module_name |
				path = "#{Smods[module_name]}#{Spath[:gemfile]}"
				if File.exist? path
					`bundle install --gemfile=#{path}`
				end
			end
			puts "Successfully implemented"
		end

	end
end

