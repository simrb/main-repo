module Simrb
	module Stool

		# return the content of erb file by path
		def base_get_erb path
			require 'erb'
			if File.exist? path
				content = File.read(path)
				t = ERB.new(content)
				t.result(binding)
			else
				res = "Warning: no file at #{path}"
				puts res
				res
			end
		end

	end
end
