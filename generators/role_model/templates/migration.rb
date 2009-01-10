class <%= migration_name %> < ActiveRecord::Migration

  def self.up
    create_table :<%= (table_name < 'users') ? "#{singular_name}_users" : "user_#{table_name}" %>, :id => false, :force => true  do |t|
      t.integer :user_id, :<%= singular_name %>_id
      t.timestamps
    end

    create_table :<%= table_name %>, :force => true do |t|
      t.string  :name, :authorizable_type, :limit => 40
      t.integer :authorizable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :<%= table_name %>
    drop_table :<%= (table_name < 'users') ? "#{singular_name}_users" : "user_#{table_name}" %>
  end

end
