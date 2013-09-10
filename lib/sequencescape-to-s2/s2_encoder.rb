require 'lims-laboratory-app/laboratory/plate/plate_resource'
require 'lims-laboratory-app/labels/labellable/labellable_resource'
require 'lims-management-app/sample/sample_resource'
require 'lims-api/context'

module SequencescapeToS2
  module S2Encoder
    
    def self.included(klass)
      klass.class_eval do
        include Virtus
        include Aequitas
        attribute :laboratory_app_root, String, :required => true, :writer => :private
        attribute :management_app_root, String, :required => true, :writer => :private
      end
    end

    # @param [Hash] api_settings
    def setup_api_roots(api_settings)
      @laboratory_app_root = api_settings["laboratory_app_root"]
      @management_app_root = api_settings["management_app_root"]
    end

    # @param [Hash] objects
    # @return [Array]
    def encode(objects)
      laboratory_uuids = objects[:laboratory].keys
      management_uuids = objects[:management].keys

      [].tap do |encoded_resources|
        self.class.switch_sample_persistor_to(Lims::LaboratoryApp::Laboratory::Sample)
        encoded_resources << encode_for_store(:laboratory, laboratory_uuids)

        # Lims::Core::NO_AUTOLOAD needs to be set to avoid the call to 
        # labellable_to_stream for a sample. 
        # @see lims-api/core_resource.rb:50
        self.class.switch_sample_persistor_to(Lims::ManagementApp::Sample)
        Lims::Core.const_set("NO_AUTOLOAD", 1) unless Lims::Core.const_defined?("NO_AUTOLOAD")
        encoded_resources << encode_for_store(:management, management_uuids)
        Lims::Core.send(:remove_const, "NO_AUTOLOAD") if Lims::Core.const_defined?("NO_AUTOLOAD")
      end.flatten
    end

    # @param [String] application
    # @param [Array] uuids
    # @return [Array]
    def encode_for_store(application, uuids)
      api_root = self.send("#{application}_app_root")
      store = self.send("#{application}_store")
      context = Lims::Api::Context.new(store, nil, nil, url_generator(api_root))

      [].tap do |encoded_resources|
        uuids.each do |uuid|
          resource = context.for_uuid(uuid)
          context.with_session do |session|
            resource.object(session)

            if context.find_model_name(resource.object.class)
              encoded_resources << context.send(:message_payload, "create", resource)
            end
          end
        end
      end
    end

    # @param [String] root
    # @return [String]
    def url_generator(root)
      lambda { |u| "#{root}/#{u}" }
    end
  end
end
