module Simrb
	module Stool

		def user_info_submitter data
			data.each do | h |
				user_add h
			end
		end
	
	end
end
