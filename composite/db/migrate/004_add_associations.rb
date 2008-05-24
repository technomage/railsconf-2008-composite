class AddAssociations < ActiveRecord::Migration
  def self.up
    create_table :items_groups do | t |
      t.column :item_id, :integer
      t.column :group_id, :integer
    end
    create_table :places_groups do | t |
      t.column :place_id, :integer
      t.column :group_id, :integer
    end
  end

  def self.down
    drop_table :items_groups
    drop_table :places_groups
  end
end
