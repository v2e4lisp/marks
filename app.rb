# -*- coding: utf-8 -*-
require 'sinatra'
require 'redcarpet'
require 'pygments'

module Util
  extend self

  class HIHTML < Redcarpet::Render::HTML
    def block_code(code, language)
      Pygments.highlight(code, :lexer => language)
    end
  end

  def not_found(path)
    "<h1>File not found</h1>" +
      "<blockquote><p>#{path}" + 
      "</p></blockquote>"
  end

  def menu(path)
    '<ul id="menu">' + _menu(File.realpath(path), "/") + '</ul>'
  end

  def _menu(realpath, relpath)
    html = ''
    Dir.foreach(realpath) do |entry|
      next if (entry[0] == '.') # ignore hidden folder
      cur_relpath = File.join(relpath, entry)
      cur_realpath = File.join(realpath, entry)

      if File.directory?(cur_realpath)
        html << "<li>#{entry}<ul>"
        html << _menu(cur_realpath, cur_relpath)
        html << "</ul></li>"
      else
        html << "<li><a href=#{cur_relpath}>#{entry}</a></li>"
      end
    end
    html
  end

  def md
    return @parser if @parser
    @parser = Redcarpet::Markdown.new(HIHTML, {
        :autolink => true,
        :fenced_code_blocks => true,
        :space_after_headers => true,
        :tables => true
      })
  end

  def render(menu, text)
    html(menu, md.render(text))
  end

  def html(menu, text) <<-HTML
 <html>
<head>
<link rel='stylesheet' type='text/css' href='/css/markdown.css'>
<link rel='stylesheet' type='text/css' href='/css/highlight.css'>
<link rel='stylesheet' type='text/css' href='/css/code.css'>
<link rel='stylesheet' type='text/css' href='/css/slicknav.css'>
<script src="/js/jquery-1.10.1.min.js"></script>
<script src="/js/jquery.slicknav.min.js"></script>
<script>
$(function(){
  var $menu = $('#menu');
  $menu.slicknav({label: ''});
});
</script>
<style type="text/css">
#menu {
display:none;
}
.slicknav_menu {
display:block;
}
</style>
</head>
<body>
#{menu}
#{text}
</body>
</html>
HTML
  end
end

set :root, File.realpath(ARGV.first)
set :public_folder, File.join(File.dirname(__FILE__), "public")
set :app_file, __FILE__
disable :dump_errors, :logging

before { @menu = Util.menu(settings.root) }

not_found { Util.render(@menu, Util.not_found(settings.root + request.path_info)) }

get '/' do
  Util.render(@menu, '') 
end

get '/*' do
  file = File.join(settings.root, params[:splat].first)
  raise Sinatra::NotFound unless File.exists?(file)
  Util.render(@menu, File.read(file))
end

