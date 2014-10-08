module Simrb
	module Stool

		# generate and implement the migration files of database by data block
		#
		# == Examples
		#
		# 	$ 3s db demo
		#
		# or, implement all at the same time
		#
		# 	$ 3s db
		#
		def db args = []
			puts "Starting to change the schema of database ..."

			args, opts		= Simrb.input_format args
			write_file		= opts[:nw] ? false : true
			module_names 	= args.empty? ? Smods.keys : args

			# generate migration record files
			unless module_names.empty?
				puts "Starting to generate migration of database ..."

				module_names.each do | module_name |
					g_migration module_name, write_file
				end

				puts "Implemented migration completely"
			end

			Sequel.extension :migration
			if Dir[Spath[:schema] + '*'].count > 0
# 				Sequel::Migrator.run(Sdb, path, :column => module_name.to_sym, :table => :_schemas)
				Sequel::Migrator.run(Sdb, Spath[:schema].chomp("/"), :table => :_schema_info)
			end

			puts "Successfully implemented"
		end

		# submit the data to database
		#
		# == Example
		#
		# 	$ 3s submit demo
		#
		def submit args = []
			puts "Starting to submit data to database ..."
			args = Smods.keys if args.empty?

			args.each do | module_name |
				# implement the hook before submitting
				installer = "#{module_name}_before_submitter"
				eval("#{installer}") if self.respond_to?(installer.to_sym)

				# fetch datas that need to be insert to db
				installer_ds = base_install_file module_name

				# run submitter
				installer_ds.each do | name, data |
					installer = "#{name}_submitter"
					if self.respond_to?(installer.to_sym)
						eval("#{installer} #{data}")

					# if no installer, submit the data with default method
					else
						data.each do | row |
  							data_submit name.to_sym, :fkv => row, :unqi => true, :valid => false
						end
					end
				end

				# implement the hook after submitting
				installer = "#{module_name}_after_submitter"
				eval("#{installer}") if self.respond_to?(installer.to_sym)
			end

			puts "Submitted data completely"
		end

		# install a module
		#
		# == Examples
		# 
		# install all of module, it will auto detects
		#
		# 	$ 3s install
		#
		# or, install the specified module
		# 
		# 	$ 3s install blog
		#
		def install args = []
			puts "Starting to install ..."

			# step 1, run migration files
			db args

			# step 2, run the gemfile
			bundle args

			# step 3, submit the data of install dir to database
			submit args

			puts "Successfully installed"
		end

	end
end

