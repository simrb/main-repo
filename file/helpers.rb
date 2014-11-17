helpers do

	# get the list of file information by given type, the result is json data
	#
	# == Examples
	#
	# 	file_list 'image'
	#
	def file_list type = 'all', pagination = true
		page_size = 20
		page_curr = (@qs.include?(:page_curr) and @qs[:page_curr].to_i > 0) ? @qs[:page_curr].to_i : 1

		# search condition
	 	ds = Sdb[:file_info].filter(:uid => file_uid)
		if type == 'all'
		elsif type == 'image'
			ds = ds.where(Sequel.like(:type, "#{type}/%"))
		end

		unless ds.empty?
			ds 			= ds.select(:fiid, :name, :type, :fnum).reverse_order(:fiid)
			ds 			= ds.extension :pagination
			ds 			= ds.paginate(page_curr, page_size, ds.count)

			page_count 	= ds.page_count
			page_prev 	= (page_curr > 1 and page_curr <= page_count) ? (page_curr - 1) : 0
			page_next 	= (page_curr > 0 and page_curr < page_count) ? (page_curr + 1) : 0

			res 		= ds.all
			res.unshift({:prev => page_prev, :next => page_next, :size => page_count, :curr => page_curr})

			require 'json'
			JSON.pretty_generate res
		else
			nil
		end
	end

	# get the file by fnum
	def file_get fnum
		ds = Sdb[:file_info].filter(:fnum => fnum)
		unless ds.empty?
			send_file Spath[:upload_dir] + ds.get(:path).to_s, :type => ds.get(:type).split('/').last.to_sym
		else
			module_name = "view"
			path = "#{Smods[module_name]}#{Spath[:assets]}images/default.jpg"
			send_file path, :type => :jpeg
		end
	end

	# save file info to db, and move the file content to upload directory
	#
	# == Arguments
	#
	# file,		filename, tempfile
	#
	def file_save file
		fields 				= {}
 		fields[:uid] 		= file_uid
		fields[:fnum] 		= file_num_generate
		fields[:name] 		= file[:filename].split('.').first
		fields[:created]	= Time.now
		fields[:type]		= file[:type]
 		fields[:path] 		= "#{file_uid}-#{fields[:created].to_i}#{_random(3)}"

		_msg :file_save, ''

		# allow these file type to save
		unless _var(:filetype, :file).include? file[:type]
			_msg :file_save, Sl[:'the file type isn`t allowed to save']
		end

		# allow the scope of file size
		file_content = file[:tempfile].read
		if (fields[:size] = file_content.size) > _var(:filesize, :file).to_i
			_msg :file_save, Sl[:'the file size is too big']
		end

		if @msg[:file_save] == ''
			# save the info of file
			Sdb[:file_info].insert(fields)

			# save the body of file
			path = Spath[:upload_dir] + fields[:path]
			Simrb.path_write path, file_content
# 			File.open(Spath[:upload_dir] + fields[:path], 'w+') do | f |
# 				f.write file_content
# 			end

			_msg :file_save, Sl['saved file successfully']
		end
# 
# 		# return the value
# 		unless reval == nil
# 			Sdb[:file_info].filter(fields).get(reval)
# 		end
	end

	def file_rm fid, level = 1
		ds = Sdb[:file_info].filter(:fiid => fid.to_i)
		unless ds.empty?
			path 	= Spath[:upload_dir] + ds.get(:path)
# 			uid		= ds.get(:uid)

			# validate user
# 			unless uid.to_i == _user[:uid]
# 				_throw Sl[:'your level is too low'] if _user[:level] < level
# 			end

			# remove record
			ds.delete

			# remove file
			File.delete path if File.exist? path
		end
	end

	# create a random number for file
	def file_num_generate
 		_random(6) + "#{file_uid}"
	end

	def file_uid
		self.respond_to?(:_user) ? _user[:uid] : 0
	end

end


