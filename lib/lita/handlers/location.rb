class Location
  attr_accessor :location_name, :latitude, :longitude

  def initialize (location_name, latitude, longitude)
    self.location_name = location_name
    self.latitude = latitude
    self.longitude = longitude
  end

  def to_s
    "Location: #{self.location_name} #{self.latitude},#{self.longitude}"
  end
end
