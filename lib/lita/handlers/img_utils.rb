module ForecastIo
  module ImgUtils
    include Magick
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

    def percip_chance_to_points(data, key, min, differential, area)
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

        if ix == (data.length - 1)
          string << "#{sep}#{cmd}#{x_cord},#{y}"
          string << "#{sep}#{cmd}0,#{y}"
        end

        ix += 1
      end

      string
    end

    def plot_scale_lines(data, key, min, differential, area, length, line_num)
      x = area[:x]
      y = area[:y]

      # x over 60 since we have minutely data
      # just divide y by tenths so we give scale
      x_step = x / line_num
      y_step = y / line_num

      results = {}
      rx = results[:x] = []
      ry = results[:y] = []

      (0 .. x_step).each do |_x|
        x_pos = _x * line_num
        if _x == 0 || _x == x_step
          rx << {data: [x_pos, y, x_pos, 0], color: 'grey'}
        end
        rx << {data: [x_pos, y, x_pos, (y + length)], color: 'black'}
      end

      (0 .. line_num).each do |_y|
        y_pos = (y - (_y * y_step))
        ry << {data: [0, y_pos, x, y_pos], color: 'grey'}
        ry << {data: [0, y_pos, (0 - length), y_pos], color: 'black'}
      end

      results
    end

  end
end
