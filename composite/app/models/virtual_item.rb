class VirtualItem
  def self.columns
    unless @columns
      @columns = []
      Item.columns.each do | col |
        column = ActiveRecord::ConnectionAdapters::Column.new(col.name, '', col.type)
      end
    end
  end

  # Return the association reflection objects.  Currently this is empty as the
  # virtual item does not need to support associations
  def self.reflect_on_all_associations(macro = nil)
      []
  end
end