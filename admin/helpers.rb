helpers do

	def admin_page name
		@t[:title] 			||= _var(:admin_title, :admin_page)
		@t[:keywords]		||= _var(:keywords, :admin_page)
		@t[:description]	||= _var(:description, :admin_page)
		_tpl name, :admin_layout
	end

	def view_get_user_add argv = {}
		view_form :user_info, :fields => [:name, :pawd, :level], :view_post => 'user_add', :layout => :admin_layout
	end

	def view_post_user_add argv = {}
		argv = params if params[:name] and params[:pawd]
		if argv[:name] and argv[:pawd]
			user_add argv
		end
	end

# 	def view_get_user_edit argv = {}
# 		user_edit params
# 	end

	def view_post_user_edit argv = {}
		user_edit params
	end

	def view_post_user_del argv = {}
		if params[:uid]
			params[:uid].each do | uid |
				user_del uid.to_i
			end
		end
	end

	def view_post_sess_del argv = {}
		user_session_remove params[:sid]
	end

	def view_post_sess_clean_all argv = {}
		user_session_clean_all
	end

	def view_post_sess_clean_timeout argv = {}
		user_session_clean_timeout
	end

	def view_get_file_create argv = {}
		view_file :file_form, argv
	end

	def view_post_file_del argv = {}
		if params[:fiid]
			params[:fiid].each do | fid |
				file_rm fid
			end
		end
	end

	def view_post_file_upload argv = {}
		if params[:upload]
			params[:upload].each do | item |
				file_save item
			end
			_msg :file_save, Sl['saved file successfully']
		end
	end

	def base_table_to_csv datas, encoding = nil
		require 'csv'
		csv_file 	= ''
		tables 		= Sdb.tables

		datas.each do | tn |
			table_name = tn.to_sym
			if tables.include?(table_name)
				ds = Sdb[table_name]
				res = CSV.generate do | csv |
					csv << [table_name, '###table###']
					csv << (Sdb[table_name].columns! + ['##fields##'])
					csv << []
					ds.each do | row |
						csv << row.values
					end
					csv << []
				end
				csv_file << res
			end
		end

		encoding == nil ? csv_file : csv_file.force_encoding(encoding)
	end

	def base_backup_recover id, encoding = nil
		file = File.read Spath[:backup_dir] + "#{id}"

		#encoding
# 		unless encoding == nil
		file.force_encoding 'UTF-8'
# 		end

		require 'csv'
		contents = CSV.parse(file)

		#split the contents with '##########' to many blocks. each block is a table data
		contents.each do | row |
			if row.last == '###table###'
				@table		= row[0].to_sym
				Sdb[@table].delete

			elsif row.last == '##fields##'
				row.pop
				@tb_fields	= row
				@db_fields	= Sdb[@table].columns

			else
				unless row.empty?
					data = {}
					row.each_index do | i |
						if @db_fields.include? @tb_fields[i].to_sym
							data[@tb_fields[i].to_sym] = row[i]
						end
					end
					Sdb[@table].insert(data)
				end

			end
		end
	end

	def base_fetch_backup_list
		res = []
		Dir[Spath[:backup_dir] + '*'].each do | f |
			res << f.split('/').last
		end
		res.sort.reverse
	end

end
