module Jekyll

	class Multilanguage
		def self.gen_url(_url, name, page_language, site, regex)
			default_language = site.config['default_language'] || 'en'
			page_language = page_language || name[regex, 1] || default_language
			if page_language != default_language
				url_prefix = "/#{page_language}"
			end
			_url = "#{url_prefix}#{_url}".gsub(".#{page_language}", "")
			name = name.gsub(".#{page_language}", "")
			return _url, page_language, name
		end
	end

	class Post
		attr_accessor :page_language

		alias super_url url
		def url
			_url, @page_language, self.slug = Multilanguage.gen_url(super_url, self.slug, @page_language, self.site, /\.([^\/.]*)$/)
			self.data['language'] = @page_language
			self.data.deep_merge({ 'page_language' => @page_language });
			return _url
		end
	end

	class Page
		attr_accessor :page_language

		alias super_url url
		def url
			_url, @page_language, @name = Multilanguage.gen_url(super_url, @name, @page_language, self.site, /\.([^\/.]*)\..+$/)
			self.data['language'] = @page_language
			self.data.deep_merge({ 'page_language' => @page_language });
			return _url
		end
	end
end

