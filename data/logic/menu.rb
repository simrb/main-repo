helpers do

	# get an hash link by tag
	#
	# == Examples
	#
	#	data_menu :admin
	#
	# return an array, like this
	#
	#	[
	#		{:name => 'name', :link => 'link'},
	#		{:name => 'name', :link => 'link', :focus => true},
	#		{:name => 'name', :link => 'link', :sub_menu => [{:name => 'name', :link => 'link'},{},{}]},
	# 	]
	#
	def data_menu tag, menu_level = 2, set_tpl = true
		ds = Sdb[:data_menu].filter(:dmid => data_tag_ids(:data_menu, tag)).order(:order)
		return [] if ds.empty?

		arr_by_parent	= {}
		arr_by_mid		= {}

		ds.each do | row |
			arr_by_mid[row[:dmid]] = row
			arr_by_parent[row[:parent]] ||= []
			arr_by_parent[row[:parent]] << row[:dmid] 
		end

		data = []

		# 1-level link
		arr_by_parent[0].each do | mid |
			menu1 = {}
			menu1[:name] = arr_by_mid[mid][:name]
			menu1[:link] = arr_by_mid[mid][:link]
			# mark the current link
			if request.path == arr_by_mid[mid][:link]
				menu1[:focus] = true 
				# input the title, keywords, descrptions for template page
				if set_tpl
					@t[:title] = arr_by_mid[mid][:name]
					@t[:keywords] = arr_by_mid[mid][:name]
					@t[:description] = arr_by_mid[mid][:description]
				end
			end

			# 2-level link
			if arr_by_parent.has_key? mid
				menu1[:sub_menu] = []
				arr_by_parent[mid].each do | num |
					menu2 = {}
					menu2[:name] = arr_by_mid[num][:name]
					menu2[:link] = arr_by_mid[num][:link]
					# mark the current link
					if request.path == arr_by_mid[num][:link]
						menu1[:focus] = true 
						menu2[:focus] = true 
						# input the title, keywords, descrptions for template page
						if set_tpl
							@t[:title] = arr_by_mid[num][:name]
							@t[:keywords] = arr_by_mid[num][:name]
							@t[:description] = arr_by_mid[num][:description]
						end
					end
					menu1[:sub_menu] << menu2
				end
			end

			data << menu1
		end

		data
	end

	# add menu
	#
	# == Example
	#
	#	data_add_menu({:name => 'menu1', :link => 'menu1', :tag => 'top_link'})
	#
	#	or, with given tag
	#
	#	data_add_menu({:name => 'link3', :link => 'link3', parent => 'menu1', tag => 'top_link'})
	#
	def data_add_menu data = {}
		unless data.empty?
			if data.include? :parent
				ds = Sdb[:data_menu].filter(:name => data[:parent])
				data[:parent] = ds.get(:dmid) unless ds.empty?
			end
 			data_submit :data_menu, :fkv => data, :uniq => true
# 			Sdb[:link].insert(data)
		end
	end

end



