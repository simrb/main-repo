
before '/admin/*' do
	view_level? _var(:level, :admin)
end
