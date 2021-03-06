data :data_var do
	{
		:dvid				=>	{
			:primary_key	=>	true,
		},
		:name				=>	{
			:default		=>	'unname',
		},
		:description		=>	{},
		:dkey				=>	{},
		:dval				=>	{
			:label			=>	:value,
		},
		:type				=>	{
			:default		=>	0,
			# the options could be, text, number, boolean
		},
		:changed			=>	{
			:default		=>	Time.now,
		}
	}
end

data :data_menu do
	{
		:dmid				=>	{
			:primary_key	=>	true,
		},
		:name				=>	{},
		:link				=>	{},
		:description		=>	{},
		:parent				=>	{
			:default		=>	0,
		},
		:order				=>	{
			:default		=>	19,
		},
	}
end

data :data_tag do
	{
		:dtid				=> 	{
			:primary_key	=>	true,
		},
		:name				=> 	{}
	}
end

data :data_tag_assoc do
	{
		:dtaid				=> 	{
			:primary_key	=>	true,
		},
		:tag_id				=> 	{},
		:table_id			=> 	{},
		:index_id			=> 	{},
	}
end

data :data_tag_enable do
	{
		:dteid				=> 	{
			:primary_key	=>	true,
		},
		:name				=> 	{},
		:closed				=> 	{
			:default		=>	0,
		},
	}
end


