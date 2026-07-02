# frozen_string_literal: true

module Decidim
  module Content
    class AssemblyMemberSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          user: resource.try(:decidim_user_id).present? ? uid(Decidim::User.new(id: resource.decidim_user_id)) : nil,
          full_name: normalize_translated_attribute(resource.full_name),
          position: resource.try(:position),
          position_other: normalize_translated_attribute(resource.try(:position_other)),
          designation_date: resource.try(:designation_date),
          ceased_date: resource.try(:ceased_date),
          gender: resource.try(:gender),
          birthday: resource.try(:birthday),
          birthplace: resource.try(:birthplace),
          non_user_avatar: blob_url(resource.try(:non_user_avatar), resource.organization),
          weight: resource.try(:weight),
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      end
    end
  end
end
