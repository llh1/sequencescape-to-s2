require 'lims-core'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/labels/labellable'
require 'lims-laboratory-app/labels/sanger_barcode'
require 'lims-management-app/sample/sample'
require 'securerandom'
require 'rubygems'
require 'ruby-debug/debugger'

module SequencescapeToS2
  module ResourceMapper

    PLATE_TYPE = "Plate"
    SAMPLE_TYPE = "Sample"

    PlateUuidNotFound = Class.new(StandardError)
    WrongAssetType = Class.new(StandardError)
    UnknownPlateSize = Class.new(StandardError)

    private

    # @param [String] plate_uuid
    # @return [Hash]
    def load_plate_objects(plate_uuid)
      {:laboratory => {}, :management => {}}.tap do |objects|
        plate_id = plate_id_by_uuid(plate_uuid)          

        plate_data = load_plate_data_by_plate_id(plate_id)
        plate = create_empty_plate(plate_data[:size])
        objects[:laboratory][plate_uuid] = plate

        labellable = create_labellable(plate_uuid, plate_data[:prefix], plate_data[:barcode])
        labellable_uuid = SecureRandom.uuid 
        objects[:laboratory][labellable_uuid] = labellable

        aliquots_data = load_aliquots_data_by_plate_id(plate_id)
        set_aliquots(plate, aliquots_data).tap do |samples|
          samples.each do |sample_uuid, sample|
            objects[:laboratory][sample_uuid] = sample
          end
        end

        sample_ids = aliquots_data.inject([]) { |m,e| m << e[:sample_id] }
        samples = create_samples(sample_ids)
        samples.each do |sample_uuid, sample|
          objects[:management][sample_uuid] = sample
        end
      end
    end

    # @param [String] plate_uuid
    # @return [Integer]
    def plate_id_by_uuid(plate_uuid)
      uuid_row = sequencescape_db[:uuids].where(:external_id => plate_uuid).first
      raise PlateUuidNotFound, "The plate uuid '#{plate_uuid}' cannot be found in Sequencescape." unless uuid_row
      plate_id = uuid_row[:resource_id]

      asset_type = sequencescape_db[:assets].where(:id => plate_id).first[:sti_type]
      raise WrongAssetType, "The uuid '#{plate_uuid}' doesn't correspond to a plate (it's a #{asset_type})." unless asset_type == PLATE_TYPE

      plate_id
    end

    # @param [Integer] plate_id
    # @return [Lims::LaboratoryApp::Laboratory::Plate]
    def create_empty_plate(size)
      dimensions = asset_size_to_row_column(size)
      Lims::LaboratoryApp::Laboratory::Plate.new({
        :number_of_rows => dimensions[:number_of_rows], 
        :number_of_columns => dimensions[:number_of_columns]
      })
    end

    # @param [String] plate_uuid
    # @param [String] prefix
    # @param [String] barcode
    # @return [Lims::LaboratoryApp::Laboratory::Labellable]
    # TODO: concat prefix and barcode doesn't give the sanger barcode
    # There is still the last caracter to add. From where?
    def create_labellable(plate_uuid, prefix, barcode)
      Lims::LaboratoryApp::Labels::Labellable.new({
        :name => plate_uuid,
        :type => 'resource'
      }).tap do |l|
        l["sanger label"] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
          :type => Lims::LaboratoryApp::Labels::SangerBarcode::Type,
          :value => "#{prefix}#{barcode}"
        })
      end
    end

    # @param [Array] sample_ids
    # @return [Hash]
    def create_samples(sample_ids)
      {}.tap do |samples|
        sample_data = load_sample_data_by_sample_ids(sample_ids)
        sample_data.each do |row|
          # TODO
        end
      end
    end
     
    # @param [Integer] size
    # @return [Hash]
    def asset_size_to_row_column(size)
      case size
      when 96 then {:number_of_rows => 8, :number_of_columns => 12}
      else raise UnknownPlateSize, "The plate size #{size} cannot be translated into number of rows and number of columns."
      end
    end

    # @param [Integer] plate_id
    # @return [Hash]
    def load_plate_data_by_plate_id(plate_id)
      sequencescape_db[:assets].left_outer_join(
        :barcode_prefixes, :id => :barcode_prefix_id
      ).where(:assets__id => plate_id).first
    end

    # @param [Integer] plate_id
    # @return [Array]
    # TODO: concentration and current_volume correct attributes to compute the quantity?
    def load_aliquots_data_by_plate_id(plate_id)
      sequencescape_db[:assets].join(
        :container_associations, :content_id => :assets__id
      ).join(
        :maps, :maps__id => :assets__map_id
      ).join(
        :aliquots, :receptacle_id => :assets__id
      ).join(
        :uuids, :resource_id => :aliquots__sample_id
      ).left_outer_join(
        :well_attributes, :well_id => :assets__id
      ).where({
        :container_id => plate_id,
        :uuids__resource_type => SAMPLE_TYPE
      }).select(
        :maps__description___location, 
        :aliquots__sample_id, 
        :uuids__external_id___sample_uuid,
        :well_attributes__concentration,
        :well_attributes__current_volume
      ).all
    end

    # @param [Array] sample_ids
    # @return [Array]
    def load_sample_data_by_sample_ids(sample_ids)
      sequencescape_db[:samples].join(
        :sample_metadata, :sample_id => :samples__id
      ).join(
        :uuids, :resource_id => :samples__id
      ).where({
        :resource_type => SAMPLE_TYPE,
        :samples__id => sample_ids
      }).all
    end

    # @param [Lims::LaboratoryApp::Laboratory::Plate] plate
    # @param [Array] aliquots_data
    # @return [Hash]
    def set_aliquots(plate, aliquots_data)
      {}.tap do |samples|
        count = 1
        aliquots_data.each do |row|
          sample = Lims::LaboratoryApp::Laboratory::Sample.new("Sample #{count}") 
          samples[row[:sample_uuid]] = sample
          count += 1

          quantity = (row[:concentration] && row[:current_volume]) ? row[:concentration]*row[:current_volume] : nil
          aliquot = Lims::LaboratoryApp::Laboratory::Aliquot.new(:sample => sample, :quantity => quantity)

          plate[row[:location]] << aliquot
        end
      end
    end
  end
end
