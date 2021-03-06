helpers do

	def admin_page name
		_tpl name, :admin_layout
	end

	def view_get_user_add
		view_form :user_info, :fields => [:name, :pawd, :level], :view_post => 'user_add', :layout => :admin_layout
	end

	def view_post_user_add
		if params[:name] and params[:pawd]
			user_add params
		end
	end

# 	def view_get_user_edit argv = {}
# 		user_edit params
# 	end

	def view_post_user_edit
		user_edit params
	end

	def view_post_user_del
		if params[:uid]
			params[:uid].each do | uid |
				user_del uid.to_i
			end
		end
	end

	def view_post_sess_del
		user_session_remove params[:sid]
	end

	def view_post_sess_clean_all
		user_session_clean_all
	end

	def view_post_sess_clean_timeout
		user_session_clean_timeout
	end

	def view_get_file_create argv = {}
		view_file :file_form, argv
	end

	def view_post_file_del
		if params[:fiid]
			params[:fiid].each do | fid |
				file_rm fid
			end
		end
	end

	def view_post_file_upload
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

	# list the files under the directory given with path
	def base_file_list path
		res = []
		Dir[path + '*'].each do | f |
			res << f.split('/').last
		end
		res.sort.reverse
	end

end
