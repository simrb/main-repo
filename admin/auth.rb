
before '/admin/*' do
	view_level? _var(:admin_level)
end
