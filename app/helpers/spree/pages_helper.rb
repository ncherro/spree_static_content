module Spree::PagesHelper

  def render_snippet(slug)
    page = Spree::Page.by_slug(slug).first
    raw page.body if page
  end

  def render_menu_items(arr)
    req = request.fullpath
    r = "<ul>"
    arr.each do |item|
      classes = []
      classes << 'on' if item[:is_on]
      classes << 'active' if item[:is_active]
      on = %( class="#{classes.join(' ')}") if classes.any?
      r << %(<li#{on}><a href="#{item[:link]}">#{item[:title]}</a>)
      if item[:children].any?
        r << render_menu_items(item[:children])
      end
      r << "</li>"
    end
    r << "</ul>"
    r.html_safe
  end

end
