ENV["RAILS_ENV"] = "development"
dir = File.dirname(__FILE__)
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails/story_adapter'

# Steps for doing scenario setup
steps_for :setup do
  Given "A mix of items, groups, and places" do
    item1 = Item.create(:qty => 3, :part => "Part1", :price => 1.5)
    item2 = Item.create(:qty => 2, :part => "Part2", :price => 1.0)
    item3 = Item.create(:qty => 4, :part => "Part3", :price => 2.0)
    item4 = Item.create(:qty => 1, :part => "Part4", :price => 5.0)
    #
    group1 = Group.create()
    group2 = Group.create()
    #
    place1 = Place.create(:name => "Place1")
    place2 = Place.create(:name => "Place2")
    #
    item1.groups << group1
    item2.groups << group1
    item3.groups << group2
    item4.groups << group1
    item4.groups << group2
    place1.groups << group1
    place2.groups << group1
    place2.groups << group2
    #
    puts "\n\nThere are #{Item.count} items, #{Group.count} groups, #{Place.count} places\n"
  end
  
  Then "There are 8 virtual items" do
    VirtualItem.count.should == 8
  end
  
  Then "There are $count virtual items for part $part" do | c,p |
    VirtualItem.count( :conditions => {:part => p} ).should == c.to_i
  end
  
  When "Change $partA to $partB" do | partA, partB |
    vis = VirtualItem.find :all, :conditions => {:part => partA}
    vis.each do | vi |
      vi.part = partB
      vi.save!
    end
  end
end
