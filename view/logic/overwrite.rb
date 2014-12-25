helpers do

	# overwirte the method of data module
	def data_set_fkv origin, replace = {}
		res = {}
		origin.each do | k, v |
			if replace.include?(k)
				res[k] = replace[k]
			elsif params[k]
				res[k] = params[k]
			elsif @qs.include? k
				res[k] = @qs[k]
			else
				res[k] = v
			end

			res[k] = Time.now if k == :changed
		end
		res
	end

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
