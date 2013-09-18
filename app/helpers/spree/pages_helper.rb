module Spree::PagesHelper

  def render_snippet(slug)
    page = Spree::Page.by_slug(slug).first
    raw page.body if page
  end

  def render_menu_items(arr, *args)
    defaults = {
      wrapped: true,
      css_classes: ["sp-menu"],
      on_class: 'sp-on',
      active_class: 'sp-active',
    }

    options = defaults.merge(args.extract_options!)

    req = request.fullpath
    r = ""
    css_classes = options[:css_classes].any? ? %( class="#{options[:css_classes].join(' ')}") : nil

    r << %(<ul#{css_classes}>) if options[:wrapped]

    arr.each do |item|
      classes = []
      classes << options[:on_class] if item[:is_on]
      classes << options[:active_class] if item[:is_active]
      on = %( class="#{classes.join(' ')}") if classes.any?
      r << %(<li#{on}><a href="#{item[:link]}">#{item[:title]}</a>)
      if item[:children].any?
        # always wrap children
        r << render_menu_items(item[:children], wrapped: true, css_classes: [])
      end
      r << "</li>"
    end

    r << "</ul>" if options[:wrapped]

    r.html_safe
  end

end
