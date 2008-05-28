class VirtualItem
  
  # Return column objects for each column in the model
  def self.columns
    unless @columns
      @columns = []
      @columns << ActiveRecord::ConnectionAdapters::Column.new("id", "", "string")
      Item.columns.each do | col |
        unless @columns.any?{|c|c.name == col.name}
          column = ActiveRecord::ConnectionAdapters::Column.new(col.name, '', col.type)
          @columns << column
        end
      end
      Group.columns.each do | col |
        unless @columns.any?{|c|c.name == col.name}
          column = ActiveRecord::ConnectionAdapters::Column.new(col.name, '', col.type)
          @columns << column
        end
      end
      Place.columns.each do | col |
        unless @columns.any?{|c|c.name == col.name}
          column = ActiveRecord::ConnectionAdapters::Column.new(col.name, '', col.type)
          @columns << column
        end
      end
    end
    @columns
  end

  # Return the association reflection objects.  Currently this is empty as the
  # virtual item does not need to support associations
  def self.reflect_on_all_associations(macro = nil)
      []
  end

  # Returns the AssociationReflection object for the named +aggregation+ (use the symbol). Example:
  #
  #   Account.reflect_on_association(:owner) # returns the owner AssociationReflection
  #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
  #
  def self.reflect_on_association(association)
    nil
  end

  # Return a database connection for this class, which should be the same as the
  # underlying models
  def self.connection
    Item.connection
  end

  # Returns a hash of column objects for the table associated with this class.
  def self.columns_hash
    @columns_hash ||= self.columns.inject({}) { |hash, column| hash[column.name.to_s] = column; hash }
  end

  # Returns an array of column names as strings.
  def self.column_names
    @column_names ||= self.columns.map { |column| column.name }
  end

  # Returns an array of column objects where the primary id, all columns ending in "_id" or "_count",
  # and columns used for single table inheritance have been removed.
  def self.content_columns
    @content_columns ||= self.columns.reject { |c| c.primary || c.name =~ /(_id|_count)$/ || c.name == inheritance_column }
  end

  # Returns a hash of all the methods added to query each of the columns in the table with the name of the method as the key
  # and true as the value. This makes it possible to do O(1) lookups in respond_to? to check if a given method for attribute
  # is available.
  def column_methods_hash #:nodoc:
    @dynamic_methods_hash ||= column_names.inject(Hash.new(false)) do |methods, attr|
      attr_name = attr.to_s
      methods[attr.to_sym]       = attr_name
      methods["#{attr}=".to_sym] = attr_name
      methods["#{attr}?".to_sym] = attr_name
      methods["#{attr}_before_type_cast".to_sym] = attr_name
      methods
    end
  end

  # Contains the names of the generated reader methods.
  def read_methods #:nodoc:
    @read_methods ||= Set.new
  end

  # Initializes the attributes array with keys matching the columns from the linked table and
  # the values matching the corresponding default value of that column, so
  # that a new instance, or one populated from a passed-in Hash, still has all the attributes
  # that instances loaded from the database would.
  def attributes_from_column_definition
    self.class.columns.inject({}) do |attributes, column|
      attributes[column.name] = column.default unless column.name == self.class.primary_key
      attributes
    end
  end

    def self.table_name
        "DataEntry"
    end
    def self.primary_key
        "id"
    end

    # Returns the column object for the named attribute.
    def column_for_attribute(name)
      self.class.columns_hash[name.to_s]
    end

    # Contains the names of the generated reader methods.
    def self.read_methods
        @read_methods ||= Set.new
    end

    # Answer if read methods should be generated.  This is false as methods are generated elsewhere
    def self.generate_read_methods
        false
    end

    # The list of generated column names
    def self.generated_column_names
      cols = column_names
      cols = ["item_id", "place_id", "group_id"].concat(cols)
      cols
    end

    # Defines an "attribute" method (like #inheritance_column or
    # #table_name). A new (class) method will be created with the
    # given name. If a value is specified, the new method will
    # return that value (as a string). Otherwise, the given block
    # will be used to compute the value of the method.
    #
    # The original method will be aliased, with the new name being
    # prefixed with "original_". This allows the new method to
    # access the original value.
    #
    # Example:
    #
    #   class A < ActiveRecord::Base
    #     define_attr_method :primary_key, "sysid"
    #     define_attr_method( :inheritance_column ) do
    #       original_inheritance_column + "_id"
    #     end
    #   end
    def self.define_attr_method(name, options={}, &block)
      value = options[:value]
      code = options[:code]
      sing = class << self; self; end
      sing.send(:alias_method, "original_#{name}", name) if sing.send(:method_defined?, name)
      if block_given?
        sing.send :define_method, name, &block
      elsif !value.nil?
        # use eval instead of a block to work around a memory leak in dev
        # mode in fcgi
        sing.class_eval "def #{name}; #{value.to_s.inspect}; end"
      elsif !code.nil?
        self.class_eval "def #{name}; #{code.to_s}; end"
      end
    end

    prior_methods = self.methods
    prior_class_methods = self.class.methods
    # Generate the accessor methods for each attriute
    self.generated_column_names.each do | col |
      if col != self.primary_key
        self.define_attr_method col, :code => "read_attribute('#{col.to_s}')"
        self.define_attr_method "#{col}=(val)", :code => "write_attribute('#{col}', val)"
      end
    end
    new_methods = self.methods-prior_methods
    puts "Added methods for attributes: #{new_methods.inspect}"
    new_class_methods = self.class.methods-prior_class_methods
    puts "Added class methods for attributes: #{new_class_methods.inspect}"

    # Return the value of an attribute
    def read_attribute(name)
      @attributes ||= {}
      return @attributes[name.to_sym]
    end

    # Set the value of an attribute
    def write_attribute(name, value)
      @attributes ||= {}
      @attributes[name.to_sym] = value
    end

    # Return the value of the named attribute when used as an index
    def [](name)
      read_attribute name
    end

    # Set the value of the named attribute when used as an index
    def []=(name, val)
      write_attribute name, val
    end
  
  # Count the number of records that would be returned by a find
  def self.count(options={})
    RAILS_DEFAULT_LOGGER.debug { "Performing count with #{options.inspect} options."}
    self.find(:all, options).size
  end

  # Returns the Errors object that holds all information about attribute error messages.
  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end

  # apply changes from this object to the database.  In this case it means
  # breaking the values in this object up to update/create related objects all
  # at one time.
  def update
    create_or_update
  end

  # Save the record back to the database
  # * No record exists: Creates a new record with values matching those of the object attributes.
  # * A record does exist: Updates the record with values matching those of the object attributes.
  def save
    create_or_update
  end

    # Attempts to save the record, but instead of just returning false if it couldn't happen, it raises a 
    # RecordNotSaved exception
    def save!
      if !create_or_update
        RAILS_DEFAULT_LOGGER.error do
          "\n\n\n\n#### FAILED TO SAVE RECORD ####\n\n#{self.errors.inspect}\n\n##########\n\n\n"
        end
        messages = self.errors.full_messages.join("\n")
        raise(ActiveRecord::RecordNotSaved.new("Unable to save VirtualItem due to errors: #{messages}"))
      end
    end
    
    # Simplified create_or_update that only updaates existing records
    def create_or_update
      #puts "Attributes: #{@attributes.inspect}"
      item = Item.find(self.item_id)
      group = Group.find(self.group_id)
      place = Place.find(self.place_id)
      
      self.class.column_names.each do | col |
        if (col != VirtualItem.primary_key)
          val = self.send col.to_sym
          setter = "#{col}=".to_sym
          if item.respond_to? setter
            item.send setter, val
          end
          if group.respond_to? setter
            group.send setter, val
          end
          if place.respond_to? setter
            place.send setter, val
          end
        end
      end
      
      item.save!
      group.save!
      place.save!
    end

  # A generic "counter updater" implementation, intended primarily to be
  # used by increment_counter and decrement_counter, but which may also
  # be useful on its own. It simply does a direct SQL update for the record
  # with the given ID, altering the given hash of counters by the amount
  # given by the corresponding value:
  #
  # ==== Options
  #
  # +id+        The id of the object you wish to update a counter on
  # +counters+  An Array of Hashes containing the names of the fields
  #             to update as keys and the amount to update the field by as
  #             values
  #
  # ==== Examples
  #
  #   # For the Post with id of 5, decrement the comment_count by 1, and
  #   # increment the action_count by 1
  #   Post.update_counters 5, :comment_count => -1, :action_count => 1
  #   # Executes the following SQL:
  #   # UPDATE posts
  #   #    SET comment_count = comment_count - 1,
  #   #        action_count = action_count + 1
  #   #  WHERE id = 5
  def self.update_counters(id, counters)
    updates = counters.inject([]) { |list, (counter_name, increment)|
      sign = increment < 0 ? "-" : "+"
      list << "#{connection.quote_column_name(counter_name)} = #{connection.quote_column_name(counter_name)} #{sign} #{increment.abs}"
    }.join(", ")
    update_all(updates, "#{connection.quote_column_name(primary_key)} = #{quote_value(id)}")
  end

  # Increment a number field by one, usually representing a count.
  #
  # This is used for caching aggregate values, so that they don't need to be computed every time.
  # For example, a DiscussionBoard may cache post_count and comment_count otherwise every time the board is
  # shown it would have to run an SQL query to find how many posts and comments there are.
  #
  # ==== Options
  #
  # +counter_name+  The name of the field that should be incremented
  # +id+            The id of the object that should be incremented
  #
  # ==== Examples
  #
  #   # Increment the post_count column for the record with an id of 5
  #   DiscussionBoard.increment_counter(:post_count, 5)
  def self.increment_counter(counter_name, id)
    update_counters(id, counter_name => 1)
  end

  # Construct a new object with the provided attribute values
  def initialize attrs = nil
    unless attrs.nil?
      attrs.each do | k, v |
        if k.to_s.length == 0
          puts "Argument to new VirtualItem includes empty key: #{attrs.inspect}"
        end
        if self.respond_to? "#{k}=".to_sym
          #puts "Initializing with attribute #{k} and value #{v}"
          self.send("#{k}=", v)
        end
      end
    end
  end
    
  # Locate a compound record using the provided arguments
  def self.find(*args)
    options = extract_options_from_args!(args)
    validate_find_options(options)
    #set_readonly_option!(options)
    o2 = {}
    o2.update(options)
    o2[:readonly] = false
    unless o2[:conditions].nil?
      self.rewrite_conditions(o2)
    end
    case args.first
      when :first then find_initial(options)
      when :all   then find_all(options)
      else             find_from_ids(args, options)
    end
  end

  COL_MAPPING = {
    "place_id" => "places.id",
    "item_id" => "items.id",
    "group_id" => "groups.id",
    "place_name" => "places.name",
  }

  # Qualify an input column name with the proper table prefix
  def self.qualify_column(col)
    temp_col = col.to_s
    pat = self.table_name+"."
    if temp_col[0,pat.length] == pat
        temp_col = temp_col[pat.length,temp_col.length-pat.length]
    end
    if COL_MAPPING[temp_col]
      return COL_MAPPING[temp_col]
    elsif Item.column_names.include? temp_col
        return "items.#{temp_col}".to_sym
    elsif Group.column_names.include? temp_col
        return "groups.#{temp_col}".to_sym
    elsif Place.column_names.include? temp_col
        return "places.#{temp_col}".to_sym
    end
    temp_col
  end

  def self.rewrite_conditions(options)
  end
 
  # Find the first matching row
  def self.find_initial(o2)
    o2[:limit] = 1
    return find_all(o2).first
  end

  # Find rows by id or conditions
  def self.find_from_ids(args, o2)
    qid = args[0]
    if o2[:conditions].nil?
      o2[:conditions] = ["concat_ws('_', items.id, groups.id, places.id) = ?", qid]
    else
      cond = o2[:conditions]
      if cond.is_a?(Array)
        old_cond = cond
        cond = []
        cond << old_cond[0]+" AND concat_ws('_', items.id, groups.id, places.id) = ?"
        (1..old_cond.length).each do | i | cond << old_cond[i] end
        cond << qid
      elsif cond.is_a?(Hash)
        cond["concat_ws('_', items.id, groups.id, places.id)"] = qid
      else
        cond = cond+" AND concat_ws('_', items.id, gorups.id, places.id) = '#{qid}'"
      end
      o2[:conditions] = cond
    end
    return find_all(o2).first
  end

  # Locate all matching rows in the virtual table
  def self.find_all(options)
    RAILS_DEFAULT_LOGGER.debug { "\nFind all with options: #{options.inspect}\n" }
    o2 = options
    limit = ""
    if l = o2[:limit]
        limit = " limit #{l}"
        if o = o2[:offset]
            limit = " limit #{l} offset #{o}"
        end
    end
    order = ""
    if (ord = o2[:order])
        order = "ORDER BY #{qualify_column(ord)}"
    end
    conditions = ""
    if o2[:conditions]
      cond = o2[:conditions]
      case cond
        when Array
          cond = sanitize_condition_sql cond
        when Hash
          sql = []
          vals = []
          cond.each do | k, v |
            sql << "#{COL_MAPPING[k] || qualify_column(k)} = ? "
            vals << v
          end
          cond = ["(#{sql.join(" ) AND (")})"]
          cond.concat(vals)
      end
      conditions = " AND #{sanitize_sql(cond)}"
    end
    cols = column_names.reject{|n| n == "id"}.collect{|cn| qualify_column cn}.join(",")
    temp = Group.connection.select_all(
      "select items.id as item_id, groups.id as group_id, places.id as place_id,"+
      "       concat_ws('_', items.id, groups.id, places.id) as id, "+cols+
      "       from items, groups_items, groups, places, groups_places "+
      "       where items.id = groups_items.item_id AND "+
      "             groups_items.group_id = groups.id AND "+
      "             groups.id = groups_places.group_id AND "+
      "             places.id = groups_places.place_id"+
      "       #{conditions} #{order} #{limit}")
    result = temp.collect do | r |
      VirtualItem.new(r)
    end
    #puts "Found #{result.size} virtual item rows"
    return result
  end
  
  self.class_eval {include ActiveRecordPermissions::Permissions}
  self.class_eval {include ActiveRecord::Calculations}
  self.class_eval {include ActiveRecord::Locking::Optimistic}
  
  module FromActiveRecordClassMethods
    
    # Extract the options from a set of arguments
    def extract_options_from_args!(args)
      args.last.is_a?(Hash) ? args.pop : {}
    end

    VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                               :order, :select, :readonly, :group, :from, :lock ]

    # Validate that the option keys are all correct
    def validate_find_options(options) #:nodoc:
        options.assert_valid_keys(VALID_FIND_OPTIONS)
    end


    # Accepts an array, hash, or string of sql conditions and sanitizes
    # them into a valid SQL fragment.
    #   ["name='%s' and group_id='%s'", "foo'bar", 4]  returns  "name='foo''bar' and group_id='4'"
    #   { :name => "foo'bar", :group_id => 4 }  returns "name='foo''bar' and group_id='4'"
    #   "name='foo''bar' and group_id='4'" returns "name='foo''bar' and group_id='4'"
    def sanitize_sql(condition)
      case condition
        when Array; sanitize_sql_array(condition)
        when Hash;  sanitize_sql_hash(condition)
        else        condition
      end
    end

    # Compute the value part of a condition
    def attribute_condition(argument)
      case argument
        when nil   then "IS ?"
        when Array then "IN (?)"
        when Range then "BETWEEN ? AND ?"
        else            "= ?"
      end
    end
    
    # Return the list of column names for the items class
    def item_columns
      Item.column_names
    end
    
    # Return hte list of column names for the item group class
    def item_group_columns
      Group.column_names
    end
    
    # Return the list of column names for the places class
    def place_columns
      Place.column_names
    end
    
    # Compute the column part of a condition
    def attribute_condition_column attr
      if self.item_columns.include? attr.to_s
        "items.#{attr}"
      elsif self.item_group_columns.include? attr.to_s
        "groups.#{attr}"
      elsif self.place_columns.include? attr.to_s
        "places.#{attr}"
      else
        attr
      end
    end
    
    # Generate SQL for an attribute condition.  Attributes can be
    # columnes on one of the 3 columns, quantities connected to the item
    # or segment groups connected to the item
    def attribute_conditional attr, value
      "#{attribute_condition_column attr}#{attribute_condition value}"
    end

    # Sanitizes a hash of attribute/value pairs into SQL conditions.
    #   { :name => "foo'bar", :group_id => 4 }
    #     # => "name='foo''bar' and group_id= 4"
    #   { :status => nil, :group_id => [1,2,3] }
    #     # => "status IS NULL and group_id IN (1,2,3)"
    #   { :age => 13..18 }
    #     # => "age BETWEEN 13 AND 18"
    def sanitize_sql_hash(attrs)
      conditions = attrs.map do |attr, value|
        "#{attribute_conditional(attr, value)}"
      end.join(' AND ')

      replace_bind_variables(conditions, expand_range_bind_variables(attrs.values))
    end

    # Accepts an array of conditions.  The array has each value
    # sanitized and interpolated into the sql statement.
    #   ["name='%s' and group_id='%s'", "foo'bar", 4]  returns  "name='foo''bar' and group_id='4'"
    def sanitize_sql_array(ary)
      statement, *values = ary
      if values.first.is_a?(Hash) and statement =~ /:\w+/
        replace_named_bind_variables(statement, values.first)
      elsif statement.include?('?')
        replace_bind_variables(statement, values)
      else
        statement % values.collect { |value| connection.quote_string(value.to_s) }
      end
    end

    alias_method :sanitize_conditions, :sanitize_sql

    def replace_bind_variables(statement, values) #:nodoc:
      raise_if_bind_arity_mismatch(statement, statement.count('?'), values.size)
      bound = values.dup
      statement.gsub('?') { quote_bound_value(bound.shift) }
    end

    def replace_named_bind_variables(statement, bind_vars) #:nodoc:
      statement.gsub(/:(\w+)/) do
        match = $1.to_sym
        if bind_vars.include?(match)
          quote_bound_value(bind_vars[match])
        else
          raise PreparedStatementInvalid, "missing value for :#{match} in #{statement}"
        end
      end
    end

    def expand_range_bind_variables(bind_vars) #:nodoc:
      bind_vars.each_with_index do |var, index|
        bind_vars[index, 1] = [var.first, var.last] if var.is_a?(Range)
      end
      bind_vars
    end

    def quote_bound_value(value) #:nodoc:
      if value.respond_to?(:map) && !value.is_a?(String)
        if value.respond_to?(:empty?) && value.empty?
          connection.quote(nil)
        else
          value.map { |v| connection.quote(v) }.join(',')
        end
      else
        connection.quote(value)
      end
    end

    def raise_if_bind_arity_mismatch(statement, expected, provided) #:nodoc:
      unless expected == provided
        raise PreparedStatementInvalid, "wrong number of bind variables (#{provided} for #{expected}) in: #{statement}"
      end
    end

  end
  self.class_eval {extend FromActiveRecordClassMethods}

  Symbol.class_eval do
    def humanize
      self.to_s.humanize
    end
  end
end