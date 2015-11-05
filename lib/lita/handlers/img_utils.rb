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
  end
end
