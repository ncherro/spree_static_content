# NOTE: changed :insert_after to :replace_contents to remove taxonomy items on
# pages
Deface::Override.new(:virtual_path => "spree/shared/_sidebar",
                     :name => "pages_in_sidebar",
                     :replace_contents => "#sidebar",
                     :partial => "spree/static_content/static_content_sidebar",
                     :disabled => false)
