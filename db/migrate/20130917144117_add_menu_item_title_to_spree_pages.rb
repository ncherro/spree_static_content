class AddMenuItemTitleToSpreePages < ActiveRecord::Migration
  def self.up
    add_column :spree_pages, :menu_item_title, :string
  end

  def self.down
    remove_column :spree_pages, :menu_item_title
  end
end
