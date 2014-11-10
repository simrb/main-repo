helpers do

	# user login by user name and password
	def user_login argv = nil
		if argv[:name] and argv[:pawd]

			# valid field format
			f = argv
			data_valid :user, f

			# if no user
			ds = Sdb[:user_info].filter(:name => f[:name])
			_throw Sl[:'the user is not existed'] if ds.empty?

			# verify password
			require "digest/sha1"
			if ds.get(:pawd) == Digest::SHA1.hexdigest(f[:pawd] + ds.get(:salt))
				sid = Digest::SHA1.hexdigest(f[:name] + Time.now.to_s)
				user_session_save sid, ds.get(:uid)
			else
				_throw Sl[:'the password is wrong']
			end

		end
	end

	def user_logout return_url = nil
		return_url ||= _var(:after_login, :link)
		sid = request.cookies['sid']

		# remove client cache
		response.set_cookie "sid", :value => "", :path => "/"

		# clear server cache
		user_session_remove sid
		redirect _url2(return_url)
	end

	# check the current user whether it is or not login
	#
	# == Example
	#
	# if the user status is unlogin, that will be jump to the page '/loginpage'
	# 	
	# 	user_login? _var(:login, :link)
	#
	# if the user had been login, that will return true, other is false.
	#
	# 	user_login?
	#
	def user_login?
		reval = user_info[:uid] > 0 ? true : false
		if reval
			user_session_update user_info[:sid], user_info[:uid]
		end
		reval
	end

	# check the user by name , if it exists, return uid, others is nil
	def user_has? name
		uid = Sdb[:user_info].filter(:name => name).get(:uid)
		uid ? uid : nil
	end

	# get the current user infomation by uid, default value is 0 that means unlogin user
	#
	# == Examples
	#
	# 	user_info #=> {:uid = 0, :name => 'unknown', :pawd => '123456', :level => 2}
	#
	# or just get the name by 
	#
	# 	user_info[:name] 	#=> unknown
	#
	def user_info uid = 0
		@user_info 			= {}
		@user_info[:uid] 	= uid
		@user_info[:name] 	= 'guest'
		@user_info[:level] 	= 0
		@user_info[:sid] 	= ''

		# get uid
		if uid == 0
			# checks the uid whether exists in session
			if sid = request.cookies['sid']
				uid = user_session_has? sid
			end
		end

		# fetch info by uid
		if uid.to_i > 0
			ds = Sdb[:user_info].filter(:uid => uid)
			@user_info[:uid]	= uid
			@user_info[:name] 	= ds.get(:name)
			@user_info[:level] 	= ds.get(:level)
			@user_info[:sid] 	= sid
		end
		@user_info
	end

	def user_del uid
		Sdb[:user_info].filter(:uid => uid.to_i).delete
		Sdb[:user_sess].filter(:uid => uid.to_i).delete
	end

	def user_edit argv = {}
		argv 		= params if params[:pawd] or params[:level]
		argv[:uid]	= @qs[:uid].to_i if @qs.include? :uid

		data_valid :user_info_edit, argv

		unless argv.include? :uid
			_throw Sl[:'no user id'] 
		else
			ds = Sdb[:user_info].filter(:uid => argv[:uid])
			unless ds.empty?
				f = {}

				# password
				if argv[:pawd]
					f[:pawd] = Digest::SHA1.hexdigest(argv[:pawd] + ds.get(:salt))
				end

				# userlevel
				f[:level] = argv[:level] if argv[:level]
				Sdb[:user_info].filter(:uid => argv[:uid]).update(f)
			end
		end
	end

	# add a new user
	#
	# == Arguments
	# an hash includes :name, :pawd, :level
	#
	# == Returned
	# return uid if success, others is 0
	#
	def user_add argv = {}
		fkv			= {}
		fkv[:name]	= argv[:name]
		fkv[:level]	= argv[:level]
		fkv[:tag]	= argv[:tag] if argv[:tag]

		# if the username is existed
		_throw Sl[:'the user is existed'] if user_has? fkv[:name]

		# password
		require "digest/sha1"
		fkv[:salt] 	= _random 5
		fkv[:pawd] 	= Digest::SHA1.hexdigest(argv[:pawd] + fkv[:salt])

# 		Sdb[:user].insert(f)
		data_submit :user_info, :fkv => fkv, :uniq => true

		uid = Sdb[:user_info].filter(:name => fkv[:name]).get(:uid)
		uid ? uid : 0
	end

	# update the user session
	#
	# == Argument
	# sid, string, the session id
	# uid, integer, the user id
	#
	def user_session_update sid = "", uid = 0
		ds = Sdb[:user_sess].filter(:sid => sid, :uid => uid.to_i)
		ds.update(:changed => Time.now) if ds.count > 0
	end

	def user_session_remove sid = nil
		Sdb[:user_sess].filter(:sid => sid).delete if sid
	end

	def user_session_clean_all
		Sdb[:user_sess].where('uid != ?', user_info[:uid]).delete
	end

	def user_session_clean_timeout
		Sdb[:user_sess].where('timeout = ?', 1).delete
	end

	def user_session_save sid, uid
		# client cookie
		if params[:rememberme] == 'yes'
			# timeout class is day, default is 30 (days)
			timeout = _var(:timeout_of_session, :user).to_i
			response.set_cookie "sid", :value => sid, :path => "/", :expires => (Time.now + 3600*24*timeout)
		else
			timeout = 1
			response.set_cookie "sid", :value => sid, :path => "/"
		end

		# server
		Sdb[:user_sess].insert(:sid => sid, :uid => uid, :changed => Time.now, :timeout => timeout, :ip => _ip)
	end

	# the user do nothing in the timeout, the session will be remove, automatically
	# return the uid
	def user_session_has? sid
		uid = 0
		ds 	= Sdb[:user_sess].filter(:sid => sid)
		if ds.get(:sid)
			# remove the session, if timeout that is current time - login time of last
			current_time = Time.now
			changed_time = ds.get(:changed)
			days = (current_time.year - changed_time.year)*365 + current_time.yday - changed_time.yday
			if days > ds.get(:timeout).to_i
				ds.delete
			else
				uid = ds.get(:uid)
			end
		end
		uid
	end

	# mark the operation by ip that prevents the same user do an action many times in specified time
	def user_mark name, timeout, msg = ''
		reval = false
		ds = Sdb[:user_mark].filter(:name => name.to_s, :ip => _ip)

		# if no record, create one
		if ds.empty?
			data_submit :user_mark, :fkv => {:name => name.to_s}
		else
			# if timeout to the last log, update the changed time
			if _timeout?(ds.get(:changed), timeout)
				ds.update(:changed => Time.now)
			else
				reval = true
				_throw msg if msg != ''
			end
		end

		reval
	end

end


