require_migration

describe MoveRepoDataFromDatabaseToSettings do
  let(:region_stub)   { migration_stub(:MiqRegion) }
  let(:database_stub) { migration_stub(:MiqDatabase) }
  let(:settings_stub) { migration_stub(:SettingsChange) }

  let(:region_number) { anonymous_class_with_id_regions.my_region_number }
  let(:region)        { region_stub.find_by_region(region_number) }
  let(:repo_string)   { "my-repo my-other-repo" }
  let(:repo_list)     { %w(my-repo my-other-repo) }

  before do
    region_id = anonymous_class_with_id_regions.rails_sequence_start
    region_stub.create(:id => region_id, :region => region_number)
  end

  migration_context :up do
    it "moves the data from miq_databases to the settings" do
      database_attrs = {
        :session_secret_token => SecureRandom.hex(64),
        :csrf_secret_token    => SecureRandom.hex(64),
        :update_repo_name     => repo_string
      }
      database_stub.create!(database_attrs)

      migrate

      setting_change = settings_stub.where(
        :key           => described_class::SETTING_KEY,
        :resource_id   => region.id,
        :resource_type => "MiqRegion"
      ).first
      expect(setting_change.value).to eq(repo_list)
    end

    it "handles nil update_repo_name" do
      database_attrs = {
        :session_secret_token => SecureRandom.hex(64),
        :csrf_secret_token    => SecureRandom.hex(64),
      }
      database_stub.create!(database_attrs)

      migrate

      setting_change = settings_stub.where(
        :key           => described_class::SETTING_KEY,
        :resource_id   => region.id,
        :resource_type => "MiqRegion"
      )
      expect(setting_change.count).to eq(0)
    end
  end

  migration_context :down do
    it "moves the data from the settings to miq_databases" do
      database_attrs = {
        :session_secret_token => SecureRandom.hex(64),
        :csrf_secret_token    => SecureRandom.hex(64),
        :update_repo_name     => nil
      }
      db = database_stub.create!(database_attrs)
      settings_stub.create!(
        :key           => described_class::SETTING_KEY,
        :value         => repo_list,
        :resource_id   => region.id,
        :resource_type => "MiqRegion"
      )

      migrate

      db.reload
      expect(db.update_repo_name).to eq(repo_string)
    end
  end
end
