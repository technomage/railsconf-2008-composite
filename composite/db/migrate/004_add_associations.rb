class AddAssociations < ActiveRecord::Migration
  def self.up
    create_table :groups_items, :id => false do | t |
      t.column :item_id, :integer
      t.column :group_id, :integer
    end
    create_table :groups_places, :id => false  do | t |
      t.column :place_id, :integer
      t.column :group_id, :integer
    end
  end

  def self.down
    drop_table :groups_items
    drop_table :groups_places
  end
end
