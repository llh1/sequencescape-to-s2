require 'lims-busclient'
require 'sequencescape-to-s2/resource_mapper'
require 'sequencescape-to-s2/s2_updater'
require 'sequencescape-to-s2/s2_encoder'
require 'sequencescape-to-s2/s2_publisher'
require 'sequel/adapters/mysql2'

module SequencescapeToS2
  class PlateManager
    include Virtus
    include Aequitas
    include Lims::BusClient::Consumer
    include ResourceMapper 
    include S2Updater
    include S2Encoder
    include S2Publisher

    attribute :sequencescape_db, Sequel::Mysql2::Database, :required => true, :writer => :private
    attribute :laboratory_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private
    attribute :management_store, Lims::Core::Persistence::Sequel::Store, :required => true, :writer => :private
    attribute :reception_queue_name, String, :required => true, :writer => :private
    attribute :log, Object, :required => true, :writer => :private

    ValidUuid = /#{[8,4,4,4,12].map { |n| "[0-9a-f]{#{n}}" }.join('-')}/i
    NotAValidUuid = Class.new(StandardError)

    # @param [Hash] settings
    def initialize(settings)
      setup_sequencescape_db(settings[:sequencescape_settings])
      setup_s2_stores(settings[:s2_laboratory_settings], settings[:s2_management_settings])
      setup_message_bus_for_reception(settings[:reception_amqp_settings])
      setup_message_bus_for_publication(settings[:publication_amqp_settings])
      setup_api_roots(settings[:api_settings])

      setup_reception_queue
    end

    # @param [Object] logger
    def set_logger(logger)
      @log = logger
    end
    
    private

    def setup_reception_queue
      self.add_queue(reception_queue_name) do |metadata, payload|
        log.info("Message received with the routing key: #{metadata.routing_key}")
        log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
        
        begin
          raise NotAValidUuid, "The payload #{payload} is not a valid uuid" unless payload =~ ValidUuid 
          copy_plate_in_s2(payload)
        rescue NotAValidUuid, PlateUuidMotFound, WrongAssetType, UnknownPlateSize, ExistingResource => e
          metadata.reject
          log.error("Message rejected with the error: #{e}")
        else
          metadata.ack
          log.info("Message processed and acknowledged")
        end
      end
    end

    # @param [String] plate_uuid
    def copy_plate_in_s2(plate_uuid)
      objects = load_plate_objects(plate_uuid)
      create_plate_objects(objects)
      encoded_objects = encode(objects)            
      publish(encoded_objects)
    end

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

    # @param [Hash] settings
    def setup_message_bus_for_reception(settings)
      @reception_queue_name = settings.delete("queue_name")
      consumer_setup(settings)
    end
  end
end
