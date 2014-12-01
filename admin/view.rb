get '/a' do redirect _url('/admin/info/system') end
get '/admin/info/:name' do
	admin_page :admin_info
end

get '/admin/view/:table' do
	view_admin params[:table].to_sym
end

# user
get '/admin/user' do
	view_admin(:user_info, {}, {
			:show			=>	{
				:fields		=>	[:uid, :name, :level, :created],
				:search_fns	=>	[:uid, :name, :level, :created],
				:btn_fns	=>	{ :create => 'user_add' },
				:opt_fns 	=> 	{ :delete => 'user_del' },
			},
			:edit			=>	{
				:view_post	=>	'user_edit',
				:fields		=>	[:pawd, :level],
			}
		}
	)
end

get '/admin/sess' do
	view_admin(:user_sess, {}, {
			:show			=>	{
				:opt_fns 	=>	{
					:delete 		=> 'sess_del',
					:delete_all 	=> 'sess_clean_all',
					:delete_timeout => 'sess_clean_timeout',
				},
			},
		}
	)
end

# file
get '/admin/file' do
	view_admin(:file_info, {:view_post => 'file_upload'}, {
			:show			=>	{
				:btn_fns	=>	{ :create => 'file_create' },
				:opt_fns	=>	{ :delete => 'file_del' },
				:lnk_fns	=>	{},
			},
		}
	)
end

# backup
get '/admin/baks' do
	case @qs[:opt]
	when 'export'
		if @qs[:id]
			type = @qs[:id].split('_').last
			send_file Spath[:backup_dir] + @qs[:id], :filename => "#{@qs[:id]}.#{type}", :type => type.to_sym
# 		attachment "#{Time.now}.csv"
# 		csv_file
		end
	when 'download'
		if @qs[:name]
			type = @qs[:name].split('.').last
			send_file Spath[:download_dir] + @qs[:name], :filename => "#{@qs[:name]}", :type => type.to_sym
		end
	when 'recover'
		base_backup_recover(@qs[:id], @qs[:encoding]) if @qs[:id]
		_msg Sl[:'recover complete']
		redirect back
	when 'delete'
		file = File.delete Spath[:backup_dir] + "#{@qs[:id]}"
		_msg Sl[:'delete complete']
		redirect back
	else
		@tables 	= Sdb.tables.each_slice(5).to_a
		@encoding 	= _var(:encoding, :file) != "" ? _var(:encoding, :file) : Scfg[:encoding]
		admin_page :admin_backup
	end
end

# backup
post '/admin/baks/backup' do
	if params[:table_name]
		# generate the csv file
		encoding 	= params[:encoding] ? params[:encoding] : _var(:encoding, :file)
		csv_file 	= base_table_to_csv params[:table_name], encoding
		filename	= "#{Time.now.strftime('%Y%m%d%H%M%S')}"
		filename	= (params[:filename] and params[:filename] !='') ? params[:filename] : ''
		filename 	= Spath[:backup_dir] + "#{filename}_csv"

		# save at server
		File.open(filename, 'w+') do | f |
			f.write csv_file
		end
		_msg Sl[:'backup complete']
	end
	redirect back
end

# inport
post '/admin/baks/inport' do
	if params[:inport] and params[:inport][:tempfile]
		filename = params[:inport][:filename].split('.').first
		File.open(Spath[:backup_dir] + filename, 'w+') do | f |
			f.write params[:inport][:tempfile].read
		end
		_msg Sl[:'upload complete']
	end
	redirect back
end

