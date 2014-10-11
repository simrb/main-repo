A view module that provides the majority of template views for displaying the data at frontground

### HELPERS

##### view_list :demo
display a list view, using like
```
	get '/' do
		view_list :demo
		# or, append the custom layout of template
		# view_list :demo, :demo_layout
	end
```
using in template
```
	== view_list :demo
```

##### view_table :demo
the usage like `view_list`

##### view_form :demo
write a form with given name :demo in template
```
	== view_form :demo
```
in route
```
	get '/' do
		view_form :demo
	end
```

##### view_file :file_info
display the file information with a table in template
```
	== view_file :file_info
```

##### view_admin :demo
an administration view for operating the data, like
```
	get '/' do
		view_admin :demo
	end
```

##### _url
```
	# return current path, and with options
	#
	# == Examples
	#
	# assume current request path is /demo/user
	#
	# 	_url() # retuen '/demo/user'
	#
	# or give a path
	#
	# 	_url('/demo/home') # return '/demo/home'
	#
	# and, with some parameters
	#
	# 	_url('/demo/home', :uid => 1, :tag => 2) # return '/demo/home?uid=1&tag=2'
	#
```

##### _tpl tpl_name, layout = false
load the template

##### _css path, domain = '/'
the inside code that will return like this

	"<link rel='stylesheet' type='text/css' href='#{_assets(path, domain)}' />"

##### _js path, domain = '/'
as the `_css` method, the return like

	"<script type='text/javascript' src='#{_assets(path, domain)}'></script>"

##### _file fnum, domain = '/'

	"#{domain}file/get/#{fnum}"


### ROUTES

##### /view/index
the default route

##### /robots.txt
the default robot file


### COMMANDS

##### $ 3s g layout --demo
create some of related files about the layout in module demo

##### $ 3s g view layout --demo
create a single file layout

