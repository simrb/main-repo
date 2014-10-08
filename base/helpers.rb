configure :production do
	not_found do
		Sl['sorry, no page']
	end

	error do
		Sl['sorry there was a nasty error - '] + env['sinatra.error'].name
	end
end

before do
	# a key-val field that will be inserted to database
	@f = {}

	# request query_string
	@qs	= {}

	# env["rack.request.query_hash"]
	base_fill_qs_with request.query_string if request.query_string

	# template common variable
	@t = {}

	# message variable
	@msg = ''
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
	# start_time, 	Time, the value format like, 2014-01-01 12:11:11 - 0700
	# time, 		Integer, seconds
	#
	# == Examples
	#
	# 	start_time = Time.new - 31
	#
	#	# 1 day
	# 	_timeout?(start_time, 3600*24) 	# => false
	#
	#	# 30 seconds
	# 	_timeout?(start_time, 30) 		# => true
	#
	def _timeout? changed_time, timeout
		@current_time ||= Time.now
		(@current_time - changed_time - timeout) > 0 ? true : false
	end

end
