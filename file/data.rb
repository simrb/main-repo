data :file_info do
	{
		:fiid				=>	{
			:primary_key	=>	true,
		},
		:fnum				=>	{
			:default		=>	file_num_generate,
			:view_type		=>	:img
		},
		:uid				=>	{
			:default		=>	file_uid,
		},
		:size				=>	{},
		:type				=>	{
			:size			=>	15,
		},
		:name				=>	{},
		:path				=>	{},
		:created			=>	{
			:default		=>	Time.now
		},
	}
end


