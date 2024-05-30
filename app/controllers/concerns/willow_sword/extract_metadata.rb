module WillowSword
  module ExtractMetadata
    extend ActiveSupport::Concern
    include WillowSword::Integrator::ModsToModel

    def extract_metadata(file_path)
      @attributes = nil
      if WillowSword.config.xml_mapping_create == 'MODS'
        xw = WillowSword::ModsCrosswalk.new(file_path)
        xw.map_xml
        assign_mods_to_model
        @attributes = xw.mapped_metadata
      else
        xw = WillowSword::DcCrosswalk.new(file_path, @work_klass)
        xw.map_xml
        @attributes = xw.metadata
        set_visibility
      end
      @resource_type = xw.model if @attributes.any?
    end

    private

      def set_visibility
        # Default to open visibility
        @attributes[:visibility] ||= 'open'
        # If visibility is set to embargo or lease but not all fields are present, fall back to restricted
        @attributes[:visibility] = 'restricted' unless all_embargo_fields_present? || all_lease_fields_present?
        @attributes
      end

      def all_embargo_fields_present?
        @attributes[:visibility] == 'embargo' && all_embargo_fields?
      end

      def all_lease_fields_present?
        @attributes[:visibility] == 'lease' && all_lease_fields?
      end

      def all_embargo_fields?
        @attributes[:embargo_release_date].present? &&
          @attributes[:visibility_during_embargo].present? &&
          @attributes[:visibility_after_embargo].present?
      end

      def all_lease_fields?
        @attributes[:visibility_during_lease].present? &&
          @attributes[:visibility_after_lease].present? &&
          @attributes[:lease_expiration_date].present?
      end
  end
end
