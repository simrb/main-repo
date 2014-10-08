data :user_info do
	{
		:uid				=>	{
			:primary_key	=>	true,
		},
		:name				=>	{
			:size 			=>	20,
			:label			=>	:username,
		},
		:pawd				=> 	{
			:size 			=>	50,
			:form_type		=>	:password,
			:default		=>	'123456',
			:label			=>	:password,
		},
		:salt				=>	{
			:size			=>	5,
			:default		=>	_random(5),
		},
		:level				=>	{
			:default		=>	1,
		},
		:created			=>	{
			:default		=>	Time.now
		},
	}
end

data :user_sess do
	{
		:sid				=> 	{
			:size			=>	50,
			:type			=>	'String'
		},
		:uid				=> 	{
			:default		=> 	user_info[:uid],
		},
		:timeout			=> 	{
			:default		=>	30,
		},
		:ip					=> 	{
			:default		=>	_ip,
			:size			=>	16,
			:type			=>	'String'
		},
		:changed			=>	{
			:default		=>	Time.now
		},
	}
end

data :user_mark do
	{
		:umid				=>	{
			:primary_key	=>	true,
		},
		:name				=> 	{},
		:uid				=> 	{
			:default		=>  user_info[:uid]
		},
		:ip					=> 	{
			:default		=>	_ip,
			:size			=>	16,
			:type			=>	'String'
		},
		:changed			=>	{
			:default		=>	Time.now
		},
	}
end



