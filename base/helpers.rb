before do
	# a key-val variable that stores the fields of db table and then will be saved into db
	@f = {}

	# request query_string
	@qs	= {}

	# env["rack.request.query_hash"]
	base_fill_qs_with request.query_string if request.query_string

	# store all variable by key in here you need to use in template
	@t = {}

	# store all messages you need to output in here
	@msg = {}
end

helpers do

	def base_fill_qs_with str
		str.split("&").each do | item |
			key, val = item.split "="
			if val and val.index '+'
				@qs[key.to_sym] = val.gsub(/[+]/, ' ')
			else
				@qs[key.to_sym] = val
			end
		end
	end

	# return a random string with the size given
	def _random size = 12
		charset = ('a'..'z').to_a + ('0'..'9').to_a + ('A'..'Z').to_a
		(0...size).map{ charset.to_a[rand(charset.size)]}.join
	end

	def _ip
		ENV['REMOTE_ADDR'] || '127.0.0.1'
	end

	# judge the time whether it is or not timeout
	#
	# == Arguments
	#
	# start_time, 	Time, a start time, like 2014-01-01 12:11:11 - 0700
	# time, 		Integer, the period of the time is available, like 30
	#
	# == Examples
	#
	# 	start_time = Time.new - 31
	#
	#	# the time is effective in 1 day
	# 	_timeout?(start_time, 3600*24) 	# => false
	#
	#	# as above, but just 30 seconds
	# 	_timeout?(start_time, 30) 		# => true
	#
	def _timeout? changed_time, timeout
		@current_time ||= Time.now
		(@current_time - changed_time - timeout) > 0 ? true : false
	end

	# set temporary message to @msg or get it by key
	#
	# == Example
	#
	# save something,
	#
	# 	_msg :submit_post, 'successfully submit a post'
	#
	# get the value by just specified key, the result will be 'successfully submit a post' 
	# otherwise, it is a null string, if it hasn`t existed
	#
	# 	_msg :submit_post
	#
	def _msg name, str = nil
		if str == nil
			@msg.include?(name) ? @msg[name] : ''
		else
			@msg[name] = name.to_s
		end
	end

	def _throw str
		Simrb.p str
		halt str
	end

end
