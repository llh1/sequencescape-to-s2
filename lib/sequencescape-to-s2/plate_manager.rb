require 'sequencescape-to-s2/resource_mapper'
require 'sequencescape-to-s2/s2_updater'
require 'sequel/adapters/mysql2'

module SequencescapeToS2
  class PlateManager
    include Virtus
    include Aequitas
    include ResourceMapper 
    include S2Updater

    attribute :sequencescape_db, Sequel::Mysql2::Database, :required => true, :writer => :private
    attribute :laboratory_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private
    attribute :management_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private

    def initialize(sequencescape_settings, s2_laboratory_settings, s2_management_settings)
      sequencescape_db_setup(sequencescape_settings)
      s2_stores_setup(s2_laboratory_settings, s2_management_settings)
    end

    def copy_plate_in_s2(plate_uuid)
      objects = load_plate_objects(plate_uuid)
      create_plate_objects(objects)
    end

    private

    def sequencescape_db_setup(settings)
      @sequencescape_db = Sequel.connect(settings)
    end

    def s2_stores_setup(laboratory_settings, management_settings)
      @laboratory_store = Lims::Core::Persistence::Sequel::Store.new(Sequel.connect(laboratory_settings))
      @management_store = Lims::Core::Persistence::Sequel::Store.new(Sequel.connect(management_settings))
    end
  end
end
