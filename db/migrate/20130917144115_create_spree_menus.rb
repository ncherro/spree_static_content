class CreateSpreeMenus < ActiveRecord::Migration
  def self.up
    create_table :spree_menus do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :spree_menus
  end
end
