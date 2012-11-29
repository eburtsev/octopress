module Jekyll

	class Post
		attr_accessor :page_language

		alias super_url url
		def url
			_url = super_url
			default_language = self.site.config['default_language'] || 'en'
			@page_language = @page_language || self.slug[/\.([^\/.]*)$/, 1] || default_language
			if @page_language != default_language
				url_prefix = "/#{@page_language}"
			end
			_url = "#{url_prefix}#{_url}".gsub(".#{@page_language}", "")
			self.slug = self.slug.gsub(".#{@page_language}", "")
			self.data['language'] = @page_language
			self.data.deep_merge({ 'page_language' => @page_language });
			return _url
		end
	end

	class Page
		attr_accessor :page_language

		alias super_initialize initialize
		def initialize(site, base, dir, name)
			sdir = dir
			sname = name
			default_language = site.config['default_language'] || 'en'
			@page_language = @page_language || name[/\.([^\/.]*)\..+$/, 1] || default_language
			if !dir.start_with?("/#{@page_language}") || !dir.start_with?(@page_language)
				if page_language != default_language
					if dir.start_with?('/')
						dir = "/#{@page_language}#{dir}"
					else
						dir = "#{@page_language}/#{dir}"
					end
				end
			end
			name = name.gsub(".#{page_language}", "")
			super_initialize(site, base, dir, sdir, name, sname)
			self.data['language'] = @page_language
			self.data.deep_merge({ 'page_language' => @page_language });
		end
	end

	module Filters
		def append_lng_to_url(url, language)
			if url.start_with?('/')
				url = "/#{language}#{url}"
			else
				url = "#{language}/#{url}"
			end
			return url
		end

		def page_url_lng(url, current_language, language)
			default_language = @context.registers[:site].config['default_language'] || 'en'
			if url.end_with?('/index.html')
				url = url.gsub("/index.html", "/")
			end
			if current_language == default_language && current_language != language
				return append_lng_to_url(url, language)
			else
				lang_replacement = ""
				if language != default_language
					lang_replacement = language
				end
				if url.start_with?('/')
					if lang_replacement != ""
						lang_replacement = "/#{lang_replacement}"
					end
					url = url.gsub("/#{current_language}", "#{lang_replacement}")
				else
					if lang_replacement != ""
						lang_replacement = "/#{lang_replacement}"
					end
					url = url.gsub("#{current_language}", "#{lang_replacement}")
				end
				return url
			end
		end
	end
end

