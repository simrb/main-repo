
before '/admin/*' do
	view_level? _var(:level, :admin)

	@t[:title] 			||= _var(:title, :admin)
	@t[:keywords]		||= _var(:keywords, :admin)
	@t[:description]	||= _var(:description, :admin)
end
