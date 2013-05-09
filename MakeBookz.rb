#!/usr/bin/env ruby
module MakeBookz
	# http://github.com/autodidakto/MakeBookz/
	require 'rubygems' # Supports 1.8.7
	require 'mp3info' # ruby-mp3info
  require 'tmpdir'

	def self.process source_dir, target_dir
    Dir.mktmpdir do |tmp_dir|
		  mp3s = build_mp3_list_from source_dir
		  title, author = get_tags_from_user_with mp3s.first

      m4b_file = transcode mp3s, title, tmp_dir

      inject_chapters mp3s, m4b_file
      inject_art source_dir, m4b_file
      inject_tags title, author, m4b_file

      FileUtils.mv m4b_file, target_dir
    end
    puts "...Done"
    rescue Interrupt
      puts "\nExiting"
	end

	def self.build_mp3_list_from source_dir
		mp3s = []
    Dir.glob(File.join source_dir, "*.mp3").each do |mp3_file|
				path = File.expand_path(mp3_file)
				name = File.basename(mp3_file, ".*")
				duration = Mp3Info.open(mp3_file).length
				start = mp3s.inject(0) {|memo, mp3| memo + mp3[:duration]}
				mp3s << {:path => path, :name => name, :duration => duration, :start => start}
		end
    if mp3s.empty? then raise 'No mp3s found!' else clean_titles mp3s end
	end

	def self.get_tags_from_user_with mp3
    mp3info = Mp3Info.open mp3[:path]

		puts 'Type title or press enter to accept:'
		puts title_guess = mp3info.tag.album || File.basename(File.dirname mp3info.filename)
		title_gets = STDIN.gets.chomp
		title = if title_gets.empty? then title_guess else title_gets end

		puts 'Type author or press enter to accept:'
		puts author_guess = mp3info.tag.artist || 'Unknown Author'
		author_gets = STDIN.gets.chomp
		author = if author_gets.empty? then author_guess else author_gets end
		return title, author
	end

	def self.transcode mp3s, title, output_dir
    file_list = mp3s.map { |mp3| bash_quote mp3[:path] }.join ' '
    output_file = bash_quote(File.join output_dir, (title + '.m4b'))
		`sox #{file_list} -r 32000 -c 1 -t .wav - | faac -b 64 -o #{output_file} - `
    # If success, or raise
    File.join(output_dir, title + '.m4b')
	end

	def self.inject_chapters mp3s, m4b_file
		title = File.basename(m4b_file, ".*")
    m4b_file_dir = File.dirname m4b_file
    chapters_file = File.join m4b_file_dir, (title + ".chapters.txt")

		if mp3s.count > 1
			File.open(chapters_file, 'w') do |f|
				mp3s.each { |mp3| f.puts "#{start_format mp3[:start]} #{mp3[:name]}" }
			end
    else # Chapters every 15 minutes if only one big mp3 file
			File.open(chapters_file, 'w') do |f|
				f.puts start_format(0) + " 0m"
				(mp3s.first[:duration].to_i / 900).times do |i| # Every 15 minutes
					f.puts start_format((i + 1) * 900).to_s + " " + (((i + 1) * 900) / 60).to_s + "m"
				end
			end
		end

		`mp4chaps -q #{bash_quote(m4b_file)} -i`
	end

	def self.clean_titles mp3s
    mp3s = mp3s.dup
		longest_common_index = mp3s.first[:name].length
		mp3s.each do |mp3|
			lci = find_longest_common_index mp3s.first[:name], mp3[:name]
			longest_common_index = lci if lci < longest_common_index
		end

		if longest_common_index != -1 && longest_common_index < mp3s.first[:name].length - 1
			mp3s.each do |mp3|
				mp3[:name][0..longest_common_index] = ''
			end
		end
		mp3s
	end

	def self.find_longest_common_index s1, s2
		i = 0
		i += 1 while s1[i] == s2[i] && i != s1.length
		i - 1
	end

	def self.start_format seconds
		mm, ss = seconds.divmod(60)
		hh, mm = mm.divmod(60)
		"%02i:%02i:%06.4f" % [hh, mm, ss]
	end

	def self.inject_art image_dir, m4b_file
    images = Dir.glob(File.join image_dir, "*.{jpg,png,gif}")
    if images.empty? then
      make_bookz_dir = File.dirname __FILE__
      images = Dir.glob(File.join make_bookz_dir, "*.{jpg,png,gif}")
    end

		`mp4art --add #{bash_quote(images.first)} #{bash_quote m4b_file}` unless images.empty?
	end

	def self.inject_tags title, author, m4b_file
		m4b_file = bash_quote m4b_file
		`mp4tags -album #{bash_quote title} #{m4b_file}`
		`mp4tags -artist #{bash_quote author} #{m4b_file}`
		`mp4tags -genre Audiobook #{m4b_file}`
	end

  # Tools
	def self.which cmd
		exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
		ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
			exts.each do |ext|
				exe = "#{path}/#{cmd}#{ext}"
				return exe if File.executable? exe
			end
		end
		return nil
	end

	def self.bash_quote arg
		"'" + arg.gsub("'", "'\\\\''") + "'"
	end
end

if ARGV[0] then
  source_dir = ARGV[0]
  target_dir = ARGV[1] || source_dir

  MakeBookz.process source_dir, target_dir
end
