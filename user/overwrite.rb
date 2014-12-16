before do

	# user access authorization
	if Sdb.tables.include? :user_access
		Sdb[:user_access].to_hash(:path, :level).each do | path, level |
			redirect '/' if request.path.start_with?(path) and user_info[:level] < level
		end
	end

end

helpers do

	def file_uid
		user_info[:uid]
	end

end

