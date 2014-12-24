helpers do

	def user_page name
		_tpl @t[:tpl], :view_page
	end

	# overwrite the user_login?
	def view_login? redirect_url = ''
		if user_login?
			if redirect_url != '' and redirect_url != request.path
				@qs[:come_from] = request.path
				redirect _url2(redirect_url)
			end
		else
			redirect_url = _var(:login_link) if redirect_url == ''
			if redirect_url != request.path
				@qs[:come_from] = request.path
				redirect _url2(redirect_url)
			end
		end
	end

	# if the user level less than the given, raise a message
	def view_level? level
		_throw Sl[:'your level is too low'] if user_info[:level].to_i < level.to_i
	end

end
