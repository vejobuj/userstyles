require 'csspool'

def h(s)
	s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
end

puts '<style>pre{font-family: monospace; overflow:auto; height: 25em; border: 1px solid black;}</style>'

limit = 1000
offset = 0
includes = [:style_code, :user]
conditions = 'subcategory = "tumblr" and code like "%#posts .post.new\_post .new\_post\_label%" and obsolete = 0 and code_error is null'
order = 'styles.id desc'
styles = Style.find(:all, :conditions => conditions, :include => includes, :order => order, :limit => limit, :offset => offset)
until styles.empty?
	styles.each do |style|

		begin
			doc = CSSPool::CSS::Document.parse(style.style_code.code)
		rescue Exception => e
			#puts "#{style.id} is not valid to begin with"
			next
		end
		
		main_match = /#posts\s+\.post\.new_post\s+.new_post_label\s*\{\s*opacity\s*:\s*0\s*;\s*display\s*:\s*none\s*;\s*\}/.match(style.style_code.code)
		
		next if main_match.nil?
		
		#remove_bg_match = /\.new_post_label_icon\s*\{\s*background\-image\s*:\s*none(?:\s+!important)?\s*;?\s*\}/.match(style.style_code.code)
		
		fixed_snippet = "/* Code repaired by admin. See http://forum.userstyles.org/discussion/37591/attempting-to-mass-fix-broken-tumblr-dash-icon-styles */
.new_post_label  {
  opacity: 0 !important;
}"
		
		new_code = style.style_code.code.gsub(main_match[0], fixed_snippet)

		puts "<div><a href=\"/styles/#{style.id}.css\">#{h style.short_description}</a><br><pre>#{h new_code}</pre>"
		
		begin
			doc = CSSPool::CSS::Document.parse(new_code)
		rescue Exception => e
			puts "<h1>uh oh, not valid now!</h1>"
			next
		end

		puts "</div>"
		
			if true
				style.style_code.code = new_code
				style.category = style.calculate_category
				style.subcategory = style.calculate_subcategory
				style.userjs_available = style.calculate_userjs_available?
				style.opera_css_available = style.calculate_opera_css_available?
				style.ie_css_available = style.calculate_ie_css_available?
				style.chrome_json_available = style.calculate_chrome_json_available?
				style.screenshot_url = style.calculate_screenshot_url
				style.style_code.save(false)
				style.save(false)
			end
		
	end
	offset = offset + limit
	styles = Style.find(:all, :conditions => conditions, :include => includes, :order => order, :limit => limit, :offset => offset)
end
puts "Done"
