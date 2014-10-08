This is a background adminisitration module that provides the base functions to user for maintaining the data


### Helpers

#### admin_page :tpl_name

call your custom template that will set the admin layout, automatically

```
# assume you offer a custom interface of administration
get '/admin/demo' do
	@t[:title] = "this is admin page of demo module"
	admin_page :demo_admin
end
```


### Routes

#### /admin/view/:table_name

provide an administration view interface that can let you operate the database table, like create, modify, delete, search by specified condition, just put it into your `installs` file of data_menu

#### /admin/info/:module_name

provide an index page as the top menu of all of sub menus

#### /a

a shortcut link of background login, like `http://www.example.com/a`


### Commands

#### $ 3s g admin --demo

auto create the administration menu by a specified module `demo`
