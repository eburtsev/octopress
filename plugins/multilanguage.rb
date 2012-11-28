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
end

