class AddSpreeMenuIdToSpreePages < ActiveRecord::Migration
  def self.up
    add_column :spree_pages, :spree_menu_id, :integer
    add_column :spree_pages, :parent_id, :integer

    add_index :spree_pages, :spree_menu_id
    add_index :spree_pages, :parent_id
  end

  def self.down
    remove_column :spree_pages, :parent_id
    remove_column :spree_pages, :spree_menu_id
  end
end
