module ForecastIo
  module ImgUtils
    def img_to_url(img)
      if ! config.img_api_uri or ! config.img_api_key
        Lita.logger.error "configs mizzing yyo"
        return
      end
      uri = config.img_api_uri + imgur_endpoints[:image]
      headers = {'Authorization' => config.img_api_key}
      data =
      {
        :image => Base64.encode64(File.open(img.filename, "rb") {|io| io.read}),
        :type => 'base64'
      }
      response = RestClient.post(uri, data, headers)
      return JSON.parse(response)["data"]["link"]
    end

    def percip_chance_to_points(data, area, min, differential)
      key = 'precipProbability'

      x = area[:x]
      y = area[:y]

      x_step = x / 60

      string = "M 0,#{y}"

      ix = 0
      data.each do |p|
        cmd = 'L '
        sep = ' '
        x_cord = (ix * x_step).to_i
        y_cord = (y - (y * p[key])).to_i

        string << "#{sep}#{cmd}#{x_cord},#{y_cord}"

        if ix == 60
          string << "#{sep}#{cmd}#{x_cord},#{y}"
          string << "#{sep}#{cmd}0,#{y}"
        end

        ix += 1
      end

      string
    end
  end
end
