class AddTenantOverrideSettings < ActiveRecord::Migration[4.2]
  include MigrationHelper

  def change
    return if previously_migrated_as?("20151435234633")
    add_column :tenants, :use_config_for_attributes, :boolean
  end
end
