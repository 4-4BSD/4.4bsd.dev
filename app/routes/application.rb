# frozen_string_literal: true

module Raven::Routes
  class Application < Roda
    plugin :render, views: File.join(__dir__, "..", "views")
    plugin :public, root: File.expand_path("../../public", __dir__)
    plugin :route_csrf, require_request_specific_tokens: false, check_header: true
    plugin :sessions, secret: ENV["SESSION_SECRET"] || "change me" * 24

    route do |r|
      r.public

      r.on "man" do
        r.on String do |manpage|
          r.get do
            raise "bad request" unless manpage =~ /^[a-zA-Z0-9\-\.]+$/
            content = man2html(manpage, r.params["section"])
            locals = {content:}
            layout_opts = {locals: {manpage:}}
            view("man", layout: "layouts/man", layout_opts:, locals:)
          rescue
            r.halt [400, {"content-type" => "text/plain"}, ["Bad request"]]
          end
        end
      end

      r.root do
        view("index")
      end

      r.on "api" do
        r.run Raven::Routes::API
      end
    end

    ##
    # @param [String] name
    #  The man page name
    # @param [String, nil]
    #  An optional section number.
    # @return [Test::Command]
    def man2html(name, section)
      Test::Command
        .new("man2html")
        .argv("-compress")
        .argv("-bare")
        .argv("-nodepage")
        .argv("-cgiurl", "/man/${title}?section=${section}")
        .stdin(man(name, section))
        .stdout
    end

    ##
    # @param [String] name
    #  The man page name
    # @param [String, nil] section
    #  Optional section
    # @return [Test::Command]
    def man(name, section)
      command = Test::Command
        .new("man")
        .env("MANPATH" => "/usr/share/man:/usr/local/man:/usr/local/share/man")
        .argv(*[section ? Integer(section).to_s : nil, name].compact)
      raise "bad request" unless command.success?
      command
    end

    ##
    # Inlines a file (typically an SVG) from public/images
    # as an <object> with a data: URI. The bytes stay in the
    # HTML (no extra request), but the object renders as its
    # own document so SVG CSS animations run and the artwork
    # isn't re-styled by the page.
    def svg!(name)
      root = File.expand_path("../../public/images/", __dir__)
      path = File.expand_path(File.join(root, name))
      return unless path.start_with?(root + File::SEPARATOR) and File.file?(path)
      encoded = strict_encode64(File.read(path))
      %(<object
         type="image/svg+xml"
         data="data:image/svg+xml;base64,#{encoded}"
         aria-hidden="true">
         </object>)
    end
    include Base64
  end
end