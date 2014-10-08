module Simrb
	module Stool

# 		def data_before_submitter
# 		end
# 
# 		def data_after_submitter
# 		end

		def data_menu_submitter data
			data.each do | h |
				data_add_menu h
			end
		end

		def data_var_submitter data
			data.each do | h |
				data_add_var h
			end
		end

	end
end
