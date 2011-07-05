require 'sinatra/base'
require 'sinatra/url_for'

module Sinatra
  module StaticAssets
    module Helpers
      # In HTML <link> and <img> tags have no end tag.
      # In XHTML, on the contrary, these tags must be properly closed.
      #
      # We can choose the appropriate behaviour with +closed+ option:
      #
      #   image_tag "/images/foo.png", :alt => "Foo itself", :closed => true
      #
      # The default value of +closed+ option is +false+.
      #
      def image_tag(source, options = {})
        options[:src] = source_url(source_path(source, {:folder => 'images'}))
        tag("img", options)
      end

      def stylesheet_link_tag(*sources)
        list, options = extract_options(sources)
        list.collect { |source| stylesheet_tag(source, options) }.join("\n")
      end

      def javascript_script_tag(*sources)
        list, options = extract_options(sources)
        list.collect { |source| javascript_tag(source, options) }.join("\n")
      end

      alias :javascript_include_tag :javascript_script_tag

      def link_to(desc, url, options = {})
        tag("a", options.merge(:href => url_for(url))) do
          desc
        end
      end

      private

      def tag(name, local_options = {})
        start_tag = "<#{name}#{tag_options(local_options) if local_options}"
        if block_given?
          content = yield
          "#{start_tag}>#{content}</#{name}>"
        else
          "#{start_tag}#{"/" if options.xhtml}>"
        end
      end

      def tag_options(options)
        unless options.empty?
          attrs = []
          attrs = options.map { |key, value| %(#{key}="#{Rack::Utils.escape_html(value)}") }
          " #{attrs.sort * ' '}" unless attrs.empty?
        end
      end

      def stylesheet_tag(source, options = {})
        tag("link", { :type => "text/css",
            :charset => "utf-8", :media => "screen", :rel => "stylesheet",
            :href => source_url(source_path(source, {:folder => 'stylesheets', :extension => 'css'})) }.merge(options))
      end

      def javascript_tag(source, options = {})
        tag("script", { :type => "text/javascript", :charset => "utf-8",
            :src => source_url(source_path(source, {:folder => 'javascripts', :extension => 'js'})) }.merge(options)) do
            end
      end

      def extract_options(a)
        opts = a.last.is_a?(::Hash) ? a.pop : {}
        [a, opts]  
      end

      def source_path(source, options)
        return source if source =~ /^\//

        file_extension = options[:extension] ? ".#{options[:extension]}" : ""
        options[:folder] + "/" + source + file_extension
      end

      def source_url(source)
        url_with_timestamp = source_url_timestamp url_for(source)
        "#{ENV['asset_host']}#{url_with_timestamp}"
      end

      def source_url_timestamp(url)
        full_url = "#{Sinatra::Application.root}/public#{url}"
        if File.exists? full_url
          timestamp = File.mtime(full_url).to_i
          "#{url}?#{timestamp}"
        else
          url
        end
      end
    end

    def self.registered(app)
      app.helpers StaticAssets::Helpers
      app.disable :xhtml
    end
  end

  register StaticAssets
end
