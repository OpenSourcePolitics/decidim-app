# frozen_string_literal: true

module GeocoderCoordinatesExtends
  def coordinates(address, options = {})
    if address.to_s.match?(/^(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)$/)
      address_parts = address.to_s.split(/\s*,\s*/)
      [address_parts[0].to_f, address_parts[1].to_f]
    elsif (results = search(address, options)).size.positive?
      results.first.coordinates
    end
  end
end

Geocoder.singleton_class.class_eval do
  prepend(GeocoderCoordinatesExtends)
end
