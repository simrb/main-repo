A user module that provides the base operation for action, like login, register, logout, authorization, etc

### HELPERS

##### user_login?
```
	# check the current user whether it is or not login
	#
	# == Example
	#
	# if the user status is unlogin, that will be jump to the page '/loginpage'
	# 	
	# 	user_login? _var(:login, :link)
	#
	# if the user had been login, that will return true, other is false.
	#
	# 	user_login?
	#
```

##### user_info uid = 0
```
	# get the current user infomation by uid, default value is 0 that means unlogin user
	#
	# == Examples
	#
	# 	user_info #=> {:uid = 0, :name => 'unknown', :pawd => '123456', :level => 2}
	#
	# or just get the name by 
	#
	# 	user_info[:name] 	#=> unknown
	#
```

##### user_logout
just an action for user logout
```
	get '/logout' do
		user_logout
	end
```

