
before '/admin/*' do
	@t[:title] ||= _var(:admin_title)
end
