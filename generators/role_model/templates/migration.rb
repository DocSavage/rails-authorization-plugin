class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= (table_name < 'users') ? "#{table_name}_users" : "users_#{table_name}" %>, :id => false, :force => true  do |t|
      t.column :user_id,          :integer
      t.column :<%= singular_name %>_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    create_table :<%= table_name %>, :force => true do |t|
      t.column :name,               :string, :limit => 40
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
  end

  def self.down
    drop_table :<%= table_name %>
    drop_table :<%= (table_name < 'users') ? "#{table_name}_users" : "users_#{table_name}" %>
  end
end
