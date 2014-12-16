helpers do

	# has it enable the tag function
	#
	# == Example
	# 
	# ask for enabling the tag, default opened, the field closed value is 0,
	# returning ture, other is false
	#
	# 	data_tag_enable? :posts
	#
	def data_tag_enable? name
		res = true
 		ds = Sdb[:data_tag_enable].filter(:name => name.to_s)
 		if ds.empty?
			Sdb[:data_tag_enable].insert(:name => name.to_s, :closed => 0)
		else
			res = false if ds.get(:closed).to_i != 0
		end
		res
#  		_var2(:table_tags_disable).include?(name.to_s) ? false : true
	end

	# return the tag id by tag name
	#
	# == Example
	# 	
	# assuming the tag ruby id is 2 that will be,
	#
	# 	_tag(:ruby) # => 2
	#
	def _tag name
		name = name.to_s.strip
		ds	 = Sdb[:data_tag].filter(:name => name)
		if ds.empty?
			Sdb[:data_tag].insert(:name => name) 
			Sdb[:data_tag].filter(:name => name).get(:dtid)
		else
			ds.get(:dtid)
		end
	end

	# as the _tag, but return an array
	def _tag2 tag
		sign = ','
		tags = []
		if tag.class.to_s == 'Symbol'
			tags << tag.to_s 
		elsif tag.class.to_s == 'String'
			tags = tag.split(sign)
		elsif tag.class.to_s == 'Array'
			tags = tag
		end

		res = []
		tags.each do | tag |
			res << _tag(tag)
		end
		res
	end

	# the tag of certain table wether it is or not existing
	#
	# == Example
	#
	# 	judge the tag whether it is or not existed
	#
	def data_tag_has? table_name, index_id = nil
		Sdb[:data_tag_assoc].filter(:table_id => _tag(table_name)).empty? ? false : true
	end

	# get associated ids by table and tag
	#
	# == Example
	#
	#	get post ids by tag ruby
	#
	# 	data_tag_ids(:posts, :ruby) # => [2, 3, 5, 6]
	#
	def data_tag_ids table_name, tag
		h 			= {:table_id => _tag(table_name)}
		tags 		= _tag2 tag
		h[:tag_id]	= tags unless tags.empty?
		Sdb[:data_tag_assoc].filter(h).map(:index_id)
	end

	# get tag names
	#
	# == Example
	#
	#	get all of tags by index id 1
	#
	# 	data_get_tags(:demo, 1) #=> ['php', 'ruby', 'python']
	#
	def data_get_tags table_name, index_id
		res = []
		ds 	= Sdb[:data_tag_assoc].filter(
				:table_id => _tag(table_name), :index_id => index_id).map(:tag_id)
		res = Sdb[:data_tag].filter(:dtid => ds).map(:name) unless ds.empty?
		res
	end

	# get all of tags as an hash by specified table name
	#
	# == Example
	#
	#	get the tags of the posts table
	#
	# 	data_tag_hash(:posts)	# => { 1 => 'ruby', 2 => 'python',,, }
	#
	def data_tag_hash table_name
		tids = Sdb[:data_tag_assoc].filter(:table_id => _tag(table_name)).map(:tag_id)
		unless tids.empty?
			ds = Sdb[:data_tag].filter(:dtid => tids).to_hash(:dtid, :name)
		end
	end

	# add tags associating to table
	#
	# == Example
	#
	#	data_add_tag(:demo, :id, 'php, ruby, python')
	#
	def data_add_tag table_name, index_id, tag
		tids = _tag2 tag
		tids.each do | tid |
			Sdb[:data_tag_assoc].insert(:table_id => _tag(table_name), :index_id => index_id, :tag_id => tid)
		end
	end

	# set the tag, for table with one or more
	#
	# == Example
	#
	# remove the tag ruby for demo table by index value 1
	#
	#	data_set_tag(:demo, 1, 'php, ruby, python', 'php, ruby')
	#
	# or, add tag python
	#
	#	data_set_tag(:demo, 1, 'php, ruby', 'php, ruby, python')
	#
	def data_set_tag table_name, index_id, cur_tag, org_tag
		cur_tag	= cur_tag.split(',').map { | m | m.strip }
		org_tag = org_tag.split(',').map { | m | m.strip }
		add_tag	= []
		del_tag	= []

		unless org_tag.eql? cur_tag
			# add tag
			cur_tag.each do | tag |
				add_tag << tag unless org_tag.include?(tag)
			end

			# remove tag
			org_tag.each do | tag |
				del_tag << tag unless cur_tag.include?(tag)
			end
		end

		unless add_tag.empty?
			data_add_tag table_name, index_id, add_tag
		end

		unless del_tag.empty?
			data_rm_tag table_name, index_id, del_tag
		end
	end

	# remove the tag associated between tables
	#
	# == Example
	# 
	# 	assuming we remove the post tag by a post id 1
	#
	# 	data_rm_tag(:posts, 1, :ruby)
	#
	# 	or
	#
	# 	data_rm_tag(:posts, 1, 'ruby, python')
	#
	# 	or
	#
	# 	data_rm_tag(:posts, 1, [:ruby, :python])
	#
	def data_rm_tag table_name, index_id, tag
		tids = _tag2 tag
		unless tids.empty?
			tids.each do | tid |
				Sdb[:data_tag_assoc].filter(
					:table_id 	=> _tag(table_name),
					:index_id 	=> index_id,
					:tag_id 	=> tid
				).delete
			end
		end
	end

end

