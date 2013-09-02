require 'sequencescape-to-s2/resource_mapper'
require 'sequencescape-to-s2/s2_updater'
require 'sequencescape-to-s2/s2_encoder'
require 'sequencescape-to-s2/s2_publisher'
require 'sequel/adapters/mysql2'

module SequencescapeToS2
  class PlateManager
    include Virtus
    include Aequitas
    include ResourceMapper 
    include S2Updater
    include S2Encoder
    include S2Publisher

    attribute :sequencescape_db, Sequel::Mysql2::Database, :required => true, :writer => :private
    attribute :laboratory_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private
    attribute :management_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private

    # @param [Hash] sequencescape_settings
    # @param [Hash] s2_laboratory_settings
    # @param [Hash] s2_management_settings
    # @param [Hash] amqp_settings
    # @param [Hash] api_settings
    def initialize(sequencescape_settings, s2_laboratory_settings, s2_management_settings, amqp_settings, api_settings)
      setup_sequencescape_db(sequencescape_settings)
      setup_s2_stores(s2_laboratory_settings, s2_management_settings)
      setup_message_bus(amqp_settings)
      setup_api_roots(api_settings)
    end

    # @param [String] plate_uuid
    def copy_plate_in_s2(plate_uuid)
      objects = load_plate_objects(plate_uuid)
      create_plate_objects(objects)
      encoded_objects = encode(objects)            
      publish(encoded_objects)
    end

    private

    # @param [Hash] settings
    def setup_sequencescape_db(settings)
      @sequencescape_db = Sequel.connect(settings)
    end

    # @param [Hash] laboratory_settings
    # @param [Hash] management_settings
    def setup_s2_stores(laboratory_settings, management_settings)
      @laboratory_store = Lims::Core::Persistence::Sequel::Store.new(Sequel.connect(laboratory_settings))
      @management_store = Lims::Core::Persistence::Sequel::Store.new(Sequel.connect(management_settings))
    end
  end
end
