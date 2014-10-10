A core module that defines the base interface for common function


### VARIABLES

##### @f = {}
a key-val variable that stores the fields of db table and will be saved into db

##### @qs = {}
the request string of url

##### @t = {}
the common variable for template

##### @msg = ''
the message that will be raised 


### HELPERS

##### _randon size=12
return a random string with the size given

##### _ip
get the current ip of user login

##### _timeout? start_time, timeout
```
	# judge the time whether it is or not timeout
	#
	# == Arguments
	#
	# start_time, 	Time, a start time, like 2014-01-01 12:11:11 - 0700
	# time, 		Integer, the period of the time is available, like 30
	#
	# == Examples
	#
	# 	start_time = Time.new - 31
	#
	#	# the time is effective in 1 day
	# 	_timeout?(start_time, 3600*24) 	# => false
	#
	#	# as above, but just 30 seconds
	# 	_timeout?(start_time, 30) 		# => true
	#
```

### COMMANDS

##### $ 3s get simrb/demo
get a module from remote repository to local dir

##### $ 3s new demo
create a module and initialize the default module dirs and files

##### $ 3s bundle demo
run the bundled operation for specified module

