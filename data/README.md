A data module that processes all of output and input operations of data and interacts with database


### STORAGE ARCHITECTURE

Bascially, in programming field, anything that will be treated as data with the various formats and types. The most common approach to process data is divided it into two parts, classification and save. The module provides the tag and menu systems in application data classification, and as the majority of stored format are the variable mode and X.

What is the X data, that is a format you create it as what you want. So, the module deals with the data as the way of X that you create, and `data_menu`, `data_var`, `data_tag` these we offer you, and some tools help you to generate and submit data to database.


### HELPERS

##### _var key, tag = '', val = ''
```
	# get the variable value that is a string, others is null value
	#
	# == Arguments
	#
	# key, this is key name
	# tag, tag name
	# val, default value, add the variable and set the default value if it isn`t existing
	#
	# == Example
	#
	# 	_var :home_page
	#
	# get the variable :home_page by tag 'www'
	#
	# 	_var :home_page, 'www'
	#
	# get the variable, if it isn`t existing, assign value '/home/page'
	#
	# 	_var :home_page, 'www', '/home/page'
	#
```

##### _tag name
```
	# return the tag id by tag name
	#
	# == Example
	# 	
	# 	assuming the tag ruby id is 2 that will be,
	#
	# 	_tag(:ruby) # => 2
	#
```

##### data_menu tag_name
```
	# get the menu by tag, the result is an array of hash
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
```

##### data_kv table, key, value
get an hash with two fields of db table as key-val format, like

	data_kv demo_type, id, name

##### data_submit table_name, argv = {}
submit the data with the given table name, like

	data_submit demo, {:fkv => {:title => 'the title', :body => 'the body'}}


### COMMANDS

##### $ 3s db demo
generate and implement the migration files of database by data block

	$ 3s db demo

or, implement all at the same time

	$ 3s db

##### $ 3s submit demo
submit the data of `installs` folder to database

##### $ 3s install
install a module, like for all to first installation

	$ 3s install

or, specified certain module by given name

	$ 3s install demo

